// tb_uart_tx.sv
//
// Discharges REQ-001 (frame format), REQ-002 (transmit bit period),
// REQ-003 (transmit byte integrity, all 256 values), REQ-004 (transmit
// handshake).
//
// Derived solely from docs/specs/SPEC-uart_lite.md SS2, SS3, SS5.2 and
// docs/specs/requirements.md REQ-001..REQ-004. No RTL was read to write
// this file.
//
// SS5.2 contract under test (uart_tx):
//   "tx_ready: high only when idle; a byte is accepted on tx_valid &
//    tx_ready. tx_line: serial output, registered, idles high. tx_busy:
//    high from acceptance until the stop bit completes."
//   "Each of the ten bit intervals is exactly DIV_TX = 434 clock cycles."
// SS3 contract: "Line idles high. One start bit (0), eight data bits least
//    significant first, no parity, one stop bit (1). A frame is therefore
//    10 bit times."
//
// Timing discipline: all cycle positions are tracked with a plain local
// "pos" variable advanced by `repeat(N) @(posedge clk)`, never by comparing
// against a free-running counter sampled with a blocking read racing its
// own nonblocking update -- an earlier version of this bench did exactly
// that (`accept_cycle = cycle_counter` racing `cycle_counter <= cycle_counter
// + 1` in the same posedge) and deadlocked on the very next absolute-value
// wait, because the counter had already advanced past the captured value by
// the time it was compared again. Relative, locally-tracked offsets have no
// such race and are also substantially cheaper to simulate.
`timescale 1ns/1ps

module tb_uart_tx;

  localparam int CLK_PERIOD_NS = 20; // 50 MHz
  localparam int DIV_TX = 434;

  int pass_count = 0;
  int fail_count = 0;

  task automatic check(input bit cond, input string req, input string msg);
    if (cond) begin
      pass_count++;
      $display("[%s] PASS  %s", req, msg);
    end else begin
      fail_count++;
      $display("[%s] FAIL  %s", req, msg);
    end
  endtask

  logic clk = 1'b0;
  always #(CLK_PERIOD_NS/2) clk = ~clk;

  logic       rst;
  logic [7:0] tx_data;
  logic       tx_valid;
  logic       tx_ready;
  logic       tx_line;
  logic       tx_busy;

  uart_tx dut (
      .clk      (clk),
      .rst      (rst),
      .tx_data  (tx_data),
      .tx_valid (tx_valid),
      .tx_ready (tx_ready),
      .tx_line  (tx_line),
      .tx_busy  (tx_busy)
  );

  task automatic do_reset();
    rst = 1'b1;
    tx_valid = 1'b0;
    tx_data = '0;
    repeat (5) @(negedge clk);
    rst = 1'b0;
    @(posedge clk);
    #1;
  endtask

  // Offers `data` on tx_valid/tx_data until tx_ready accepts it (tx_valid &
  // tx_ready sampled true at a posedge), then drops tx_valid. Returns with
  // the acceptance posedge established as relative position 0 for the
  // caller's own `pos` tracking: no further @(posedge clk) is consumed
  // after detecting acceptance, only a sub-cycle #1 and a negedge.
  task automatic offer_byte(input logic [7:0] data);
    bit accepted;
    @(negedge clk);
    tx_data = data;
    tx_valid = 1'b1;
    accepted = 1'b0;
    while (!accepted) begin
      @(posedge clk);
      if (tx_valid === 1'b1 && tx_ready === 1'b1) accepted = 1'b1;
    end
    #1;
    @(negedge clk);
    tx_valid = 1'b0;
  endtask

  // Advances the caller's local `pos` (posedges consumed since the
  // acceptance edge, which is pos=0) forward to `target`, then samples
  // tx_line and tx_ready a moment after that posedge.
  task automatic advance_to(inout int pos, input int target);
    repeat (target - pos) @(posedge clk);
    #1;
    pos = target;
  endtask

  int i, b;
  bit byte_ok;
  bit period_ok;
  bit period_errors;
  logic [7:0] test_byte1;
  int pos;

  initial begin
    do_reset();

    // ---- REQ-004 reset sanity (tx side only; full REQ-016 is discharged
    // at the uart_lite level).
    check(tx_line === 1'b1, "REQ-004", "post-reset: tx_line idles high");
    check(tx_ready === 1'b1, "REQ-004", "post-reset: tx_ready is high (idle)");
    check(tx_busy === 1'b0, "REQ-004", "post-reset: tx_busy is low (idle)");

    // ---- REQ-001: one directed frame, checking start/data/stop format by
    // sampling the middle of each of the 10 bit intervals.
    test_byte1 = 8'b1010_0101; // LSB-first on the wire: 1,0,1,0,0,1,0,1
    offer_byte(test_byte1);
    pos = 0;
    begin
      bit frame_bits[10];
      for (i = 0; i < 10; i = i + 1) begin
        advance_to(pos, i * DIV_TX + (DIV_TX / 2));
        frame_bits[i] = tx_line;
      end
      check(frame_bits[0] === 1'b0, "REQ-001", "start bit is low");
      byte_ok = 1'b1;
      for (b = 0; b < 8; b = b + 1) begin
        if (frame_bits[1 + b] !== test_byte1[b]) byte_ok = 1'b0;
      end
      check(byte_ok, "REQ-001", "d0..d7 on the wire equal tx_data, LSB first (byte 8'b10100101)");
      check(frame_bits[9] === 1'b1, "REQ-001", "stop bit is high");
    end
    advance_to(pos, 10 * DIV_TX + 2);

    // ---- REQ-002, precisely: verify each of the 10 bit-interval boundaries
    // lands exactly DIV_TX cycles from the previous one, for a frame whose
    // bits force a transition at every single boundary. The framing bits
    // are fixed (start=0, stop=1), so the data byte must be chosen so d0
    // differs from start(0) and d7 differs from stop(1), with d0..d7
    // alternating in between: d0..d7 = 1,0,1,0,1,0,1,0, i.e. tx_data =
    // 8'b0101_0101 = 0x55 (d0 is the LSB). 0xAA does NOT work here: its LSB
    // (d0) is 0, same as the start bit, so there is no transition at the
    // start/d0 boundary -- this bench's first attempt used 0xAA and its
    // boundary-1 check failed; the fix was the byte choice, not the DUT.
    offer_byte(8'b0101_0101);
    pos = 0;
    period_errors = 1'b0;
    for (i = 0; i <= 10; i = i + 1) begin
      bit before_val, after_val;
      int boundary;
      boundary = i * DIV_TX;
      if (i == 0) begin
        // boundary 0 is the acceptance edge itself: line must already be
        // low (start bit) starting exactly here.
        advance_to(pos, boundary);
        if (tx_line !== 1'b0) period_errors = 1'b1;
      end else if (i == 10) begin
        // boundary 10 is the end of the stop bit; confirm the line is
        // still high (stop bit) one cycle before this boundary.
        advance_to(pos, boundary - 1);
        if (tx_line !== 1'b1) period_errors = 1'b1;
      end else begin
        // interior boundary: the value one cycle before must differ from
        // the value at/after, confirming the transition lands exactly at
        // the boundary and not one cycle early or late.
        advance_to(pos, boundary - 1);
        before_val = tx_line;
        advance_to(pos, boundary);
        after_val = tx_line;
        if (before_val === after_val) period_errors = 1'b1;
      end
    end
    check(!period_errors, "REQ-002",
          "each of the 10 bit-interval boundaries (frame 0xAA, transition at every boundary) lands exactly DIV_TX=434 cycles from the previous one");
    advance_to(pos, 10 * DIV_TX + 2);

    // ---- REQ-004: handshake detail -- tx_ready falls the cycle after
    // acceptance, and does not rise again until the stop bit completes.
    begin
      bit ready_glitch;
      offer_byte(8'hC3);
      pos = 0;
      ready_glitch = 1'b0;
      for (i = 1; i < 10 * DIV_TX; i = i + 1) begin
        advance_to(pos, i);
        if (tx_ready !== 1'b0) ready_glitch = 1'b1;
      end
      check(!ready_glitch, "REQ-004",
            "tx_ready falls the cycle after acceptance and stays low until the stop bit completes");
      advance_to(pos, 10 * DIV_TX);
      check(tx_ready === 1'b1, "REQ-004", "tx_ready rises again once the stop bit has completed");
      advance_to(pos, 10 * DIV_TX + 2);
    end

    // ---- REQ-003: all 256 byte values, format-checked (start/d0..d7/stop).
    for (i = 0; i < 256; i = i + 1) begin
      bit ok;
      bit frame_bits[10];
      logic [7:0] byte_val;
      byte_val = i[7:0];
      offer_byte(byte_val);
      pos = 0;
      for (b = 0; b < 10; b = b + 1) begin
        advance_to(pos, b * DIV_TX + (DIV_TX / 2));
        frame_bits[b] = tx_line;
      end
      ok = (frame_bits[0] === 1'b0) && (frame_bits[9] === 1'b1);
      for (b = 0; b < 8; b = b + 1) begin
        if (frame_bits[1 + b] !== byte_val[b]) ok = 1'b0;
      end
      check(ok, "REQ-003", $sformatf("byte 0x%02x transmitted with correct frame format", byte_val));
      advance_to(pos, 10 * DIV_TX + 2);
    end

    $display("==== SUMMARY (tb_uart_tx) ====");
    $display("Total: %0d  Pass: %0d  Fail: %0d", pass_count + fail_count, pass_count, fail_count);
    if (fail_count > 0) begin
      $fatal(1, "tb_uart_tx: %0d check(s) FAILED", fail_count);
    end else begin
      $display("tb_uart_tx: ALL CHECKS PASSED");
    end
    $finish;
  end

endmodule
