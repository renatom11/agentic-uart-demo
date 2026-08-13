// tb_uart_lite.sv
//
// Discharges REQ-014 (overrun is flagged, never corrupting), REQ-016 (reset
// state), REQ-017 (loopback, 256 bytes). REQ-013 (input synchronisation) is
// inspection-only per requirements.md's Method column and is not attempted
// here -- see the final summary block, which names it explicitly as skipped.
//
// Derived solely from docs/specs/SPEC-uart_lite.md SS5.5, SS6 and
// docs/specs/requirements.md REQ-013, REQ-014, REQ-016, REQ-017. No RTL was
// read to write this file.
//
// SS5.5 contract under test (uart_lite):
//   "rx_overrun: sticky; set when a byte completes while the FIFO is full."
//   "Overrun. rx_overrun is set on any cycle where uart_rx.rx_strobe is high
//    and the FIFO is full, and stays set until rx_ovr_clr. The arriving
//    byte is dropped; the 16 stored bytes are unchanged and read out in the
//    order written. A framing error does not write the FIFO."
// SS6: "One cycle after rst deasserts: tx_line = 1, tx_ready = 1, the FIFO
//    is empty, rx_overrun = 0, and the receiver is idle."
`timescale 1ns/1ps

module tb_uart_lite;

  localparam int CLK_PERIOD_NS = 20; // 50 MHz
  localparam int RX_BIT_PERIOD = 432; // bench-model direct-injection period for REQ-014
  localparam int DIV_TX = 434;
  localparam int FIFO_DEPTH = 16;

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
  logic [7:0] rx_data;
  logic       rx_valid;
  logic       rx_ready;
  logic       rx_overrun;
  logic       rx_ovr_clr;
  logic       rx_frame_err;
  logic       tx_line;
  logic       rx_line;

  // rx_line is driven either from tx_line (loopback, REQ-017) or from this
  // bench's own direct-injection model (REQ-014), selected by loopback_en,
  // so the same DUT instance serves both without needing two instances.
  logic loopback_en;
  logic bench_rx_line;
  assign rx_line = loopback_en ? tx_line : bench_rx_line;

  uart_lite dut (
      .clk          (clk),
      .rst          (rst),
      .tx_data      (tx_data),
      .tx_valid     (tx_valid),
      .tx_ready     (tx_ready),
      .rx_data      (rx_data),
      .rx_valid     (rx_valid),
      .rx_ready     (rx_ready),
      .rx_overrun   (rx_overrun),
      .rx_ovr_clr   (rx_ovr_clr),
      .rx_frame_err (rx_frame_err),
      .tx_line      (tx_line),
      .rx_line      (rx_line)
  );

  task automatic do_reset();
    rst = 1'b1;
    tx_valid = 1'b0;
    tx_data = '0;
    rx_ready = 1'b0;
    rx_ovr_clr = 1'b0;
    loopback_en = 1'b0;
    bench_rx_line = 1'b1; // idle high
    repeat (5) @(negedge clk);
    rst = 1'b0;
    @(posedge clk);
    #1;
  endtask

  // ---- Bench-model transmitter for direct rx_line injection (REQ-014),
  // independent of uart_tx, same design as tb_uart_rx.sv's.
  task automatic bench_drive_bit(input logic val, input int p);
    @(negedge clk);
    bench_rx_line = val;
    repeat (p) @(posedge clk);
  endtask

  task automatic bench_send_frame(input int p, input logic [7:0] data, input bit bad_stop);
    int bi;
    bench_drive_bit(1'b0, p);
    for (bi = 0; bi < 8; bi = bi + 1) bench_drive_bit(data[bi], p);
    bench_drive_bit(bad_stop ? 1'b0 : 1'b1, p);
  endtask

  task automatic settle(input int cycles);
    repeat (cycles) @(posedge clk);
  endtask

  // ---- tx-side offer, for the REQ-017 loopback path.
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

  int i;
  logic [7:0] seen_bytes [0:FIFO_DEPTH-1];

  initial begin
    do_reset();

    // ============================================================
    // REQ-016: reset state.
    // ============================================================
    check(tx_line === 1'b1, "REQ-016", "one cycle after rst deasserts: tx_line = 1");
    check(tx_ready === 1'b1, "REQ-016", "one cycle after rst deasserts: tx_ready = 1");
    check(rx_valid === 1'b0, "REQ-016", "one cycle after rst deasserts: rx_valid = 0 (FIFO empty)");
    check(rx_overrun === 1'b0, "REQ-016", "one cycle after rst deasserts: rx_overrun = 0");

    // ============================================================
    // REQ-017: loopback, 256 bytes, byte-for-byte in order. One byte at a
    // time (offer, wait for it to arrive at rx_valid, pop, then the next)
    // so FIFO depth is never a factor -- REQ-017 is about correctness of
    // the round trip, not about sustained throughput.
    // ============================================================
    begin
      int mismatches;
      loopback_en = 1'b1;
      mismatches = 0;
      for (i = 0; i < 256; i = i + 1) begin
        logic [7:0] byte_val;
        bit got;
        int guard;
        byte_val = i[7:0];
        offer_byte(byte_val);
        got = 1'b0;
        guard = 0;
        while (!got && guard < 20000) begin
          @(posedge clk);
          #1;
          guard = guard + 1;
          if (rx_valid) got = 1'b1;
        end
        if (!got || rx_data !== byte_val) begin
          mismatches = mismatches + 1;
        end
        @(negedge clk);
        rx_ready = 1'b1;
        @(negedge clk); // spans exactly one posedge with rx_ready high
        rx_ready = 1'b0;
        settle(5);
      end
      check(mismatches == 0, "REQ-017",
            $sformatf("loopback: all 256 bytes read back byte-for-byte in order (%0d mismatches)", mismatches));
      loopback_en = 1'b0;
      settle(20);
    end

    // ============================================================
    // REQ-014: overrun is flagged, never corrupting. Direct rx_line
    // injection (bench-model transmitter, bypassing tx entirely), rx_ready
    // held low so nothing is popped, until the FIFO is deliberately filled.
    // ============================================================
    do_reset();
    begin
      logic [7:0] fill_bytes [0:FIFO_DEPTH-1];
      bit order_ok;
      bit overrun_seen_after_16;
      bit overrun_set_after_17th;
      bit dropped_ok;

      for (i = 0; i < FIFO_DEPTH; i = i + 1) fill_bytes[i] = (i * 53 + 7) & 8'hFF;

      rx_ready = 1'b0;
      for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
        bench_send_frame(RX_BIT_PERIOD, fill_bytes[i], 1'b0);
      end
      settle(30);

      overrun_seen_after_16 = rx_overrun;
      check(!overrun_seen_after_16, "REQ-014", "rx_overrun is not set after exactly 16 bytes (FIFO exactly full, not yet overrun)");

      // 17th byte, while full: should set rx_overrun and be dropped.
      bench_send_frame(RX_BIT_PERIOD, 8'hFF, 1'b0);
      settle(30);
      overrun_set_after_17th = rx_overrun;
      check(overrun_set_after_17th, "REQ-014", "rx_overrun is set when a 17th byte completes while the FIFO is full");

      // A framing error while full must not clear/disturb overrun and must
      // not write the FIFO either (SS5.5: "A framing error does not write
      // the FIFO"), checked here incidentally by the byte-order check below
      // still coming out exactly right.
      bench_send_frame(RX_BIT_PERIOD, 8'hEE, 1'b1); // bad stop
      settle(30);
      check(rx_overrun === 1'b1, "REQ-014", "rx_overrun stays set across a subsequent framing error while full");

      // Drain all 16 and confirm: exactly the original 16, in order; the
      // 17th (dropped) byte and the framing-error byte never appear.
      order_ok = 1'b1;
      for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
        seen_bytes[i] = rx_data;
        @(negedge clk);
        rx_ready = 1'b1;
        @(negedge clk); // spans exactly one posedge with rx_ready high
        rx_ready = 1'b0;
        settle(2);
        if (seen_bytes[i] !== fill_bytes[i]) order_ok = 1'b0;
      end
      check(order_ok, "REQ-014",
            "the 16 stored bytes are unchanged and read out in the order written (dropped 17th byte and the framing-error byte are absent)");
      check(rx_valid === 1'b0, "REQ-014", "FIFO is empty again after draining exactly 16 entries");

      // rx_overrun is sticky: still set after draining (only rx_ovr_clr
      // clears it).
      check(rx_overrun === 1'b1, "REQ-014", "rx_overrun remains set after draining the FIFO (sticky until rx_ovr_clr)");

      @(negedge clk);
      rx_ovr_clr = 1'b1;
      @(negedge clk); // spans exactly one posedge with rx_ovr_clr high
      rx_ovr_clr = 1'b0;
      settle(3);
      check(rx_overrun === 1'b0, "REQ-014", "rx_ovr_clr clears rx_overrun");
    end

    // ============================================================
    // REQ-013: input synchronisation -- inspection-only per
    // requirements.md's Method column ("inspection": reading a committed
    // file). Not attempted in simulation; explicitly skipped here.
    // ============================================================
    $display("[REQ-013] SKIP  inspection-only per requirements.md Method column -- not a simulation check");

    $display("==== SUMMARY (tb_uart_lite) ====");
    $display("Total: %0d  Pass: %0d  Fail: %0d", pass_count + fail_count, pass_count, fail_count);
    if (fail_count > 0) begin
      $fatal(1, "tb_uart_lite: %0d check(s) FAILED", fail_count);
    end else begin
      $display("tb_uart_lite: ALL CHECKS PASSED");
    end
    $finish;
  end

endmodule
