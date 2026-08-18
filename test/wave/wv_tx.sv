// wv_tx.sv -- WAVEFORM VIGNETTE for uart_tx.
//
// NOT A TEST. A demonstration: one deliberately staged scenario, a
// reader-sized VCD, zero checks contributed to the suite. Not run by
// test/run.sh.
//
// ---------------------------------------------------------------------------
// WHAT A READER SHOULD LOOK AT
// ---------------------------------------------------------------------------
// One complete 8N1 frame, end to end: `tx_line` idles high, drops for the
// start bit, carries eight data bits LEAST SIGNIFICANT FIRST, then returns
// high for the stop bit -- with `tx_busy` spanning the whole frame and
// `tx_ready` low across it (SPEC SS3, SS5.2; REQ-001, REQ-002, REQ-004).
//
// The marker bus `bit_idx` labels which of the ten intervals the line is in
// (0 = start, 1..8 = d0..d7, 9 = stop, 15 = idle), so a reader does not have
// to count 434-cycle intervals by eye to know which bit is on the wire.
//
// Two details worth watching, both of which cost this program real defects:
//   * The start bit begins the cycle AFTER `tx_valid & tx_ready`, because
//     `tx_line` is a registered output and cannot change in the same cycle as
//     the input that causes it (SPEC SS5.2). `cyc_since_accept` reads 0 on the
//     acceptance cycle and 1 on the first cycle of the start bit.
//   * Every one of the ten intervals is exactly 434 cycles INCLUDING THE
//     FIRST. An implementation whose start bit is 433 or 435 cycles and whose
//     other nine are 434 looks correct in any tick-to-tick measurement; that
//     was BUG-0001.
//
// ---------------------------------------------------------------------------
// PARAMETER CHOICES, AND WHY
// ---------------------------------------------------------------------------
//   byte = 8'hA3     Deliberately asymmetric under bit reversal. On the wire,
//                    LSB-first, 0xA3 = 1010_0011 sends 1,1,0,0,0,1,0,1;
//                    MSB-first it would send 1,0,1,0,0,0,1,1. The two are
//                    visibly different, so a reader can confirm LSB-first from
//                    the picture alone. 0xA5 and 0x55 are useless here: 0xA5
//                    is a bit-reversal palindrome (it sends the same sequence
//                    either way) and 0x55 differs from its reverse 0xAA only
//                    in the framing-bit boundaries.
//   DIV_TX = 434     The real divisor, not a scaled-down one. SPEC SS5.2
//                    declares no divisor parameter on uart_tx -- the constants
//                    live in uart_pkg (SPEC SS4) -- so a bench derived from
//                    the specification has no legal way to shrink it, and
//                    inventing one would mean reading the design. The frame is
//                    therefore 4340 cycles; the VCD stays small anyway because
//                    the signal list is short. Zoom-to-fit shows the whole
//                    frame; `bit_idx` labels the intervals.
`timescale 1ns/1ps

module wv_tx;

  localparam int CLK_PERIOD_NS = 20;      // 50 MHz, SPEC SS2
  localparam int DIV_TX        = 434;     // SPEC SS2
  localparam logic [7:0] SHOW  = 8'hA3;   // see header

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

  // ---- Reader markers. `framing` is raised by the stimulus on the acceptance
  // cycle; from there `cyc_since_accept` is SPEC SS5.2's own cycle numbering
  // (acceptance = 0) and `bit_idx` names the interval that number falls in.
  logic        framing;
  logic        accepted;
  logic [15:0] cyc_since_accept;
  logic [3:0]  bit_idx;

  always @(posedge clk) begin
    if (!framing) cyc_since_accept <= 16'd0;
    else          cyc_since_accept <= cyc_since_accept + 16'd1;
  end

  // A single ternary rather than a default-then-override block: an
  // intermediate assignment inside an always @(*) that re-evaluates every
  // cycle shows up in the VCD as an extra value change per cycle.
  always @(*) begin
    bit_idx = (!framing || cyc_since_accept == 0 || cyc_since_accept > 10 * DIV_TX)
              ? 4'd15                                       // idle / not in a frame
              : 4'((cyc_since_accept - 1) / DIV_TX);        // 0=start, 1..8=d0..d7, 9=stop
  end

  initial begin
    $dumpfile("build/wave/wv_tx.vcd");
    // Depth 1 on the named bench scope only: the transmitter's ports and the
    // two reader markers. The DUT's internals are deliberately NOT dumped --
    // this vignette is about the wire, and a shift register on the picture
    // would invite reading the frame off the internal state instead of off
    // tx_line, which is the only thing the specification constrains.
    $dumpvars(1, wv_tx);
  end

  int  i;
  int  target;
  bit  wire_bits [0:9];

  initial begin
    $display("==== VIGNETTE (wv_tx) ====");
    $display("Look at one whole 8N1 frame on tx_line: start low, then 0x%02x LSB-first (wire order 1,1,0,0,0,1,0,1), then stop high -- tx_busy spans it, tx_ready is low across it, and every interval including the first is DIV_TX=%0d cycles.", SHOW, DIV_TX);

    // ---- Reset, then a few idle cycles so the picture opens on the idle line.
    rst      = 1'b1;
    tx_valid = 1'b0;
    tx_data  = '0;
    framing  = 1'b0;
    repeat (5) @(negedge clk);
    rst = 1'b0;
    repeat (20) @(posedge clk);

    // ---- Offer the byte and hold tx_valid until it is accepted.
    @(negedge clk);
    tx_data  = SHOW;
    tx_valid = 1'b1;
    accepted = 1'b0;
    while (!accepted) begin
      @(posedge clk);
      if (tx_valid === 1'b1 && tx_ready === 1'b1) accepted = 1'b1;
    end
    framing = 1'b1;   // this posedge is SPEC SS5.2's cycle 0
    #1;
    @(negedge clk);
    tx_valid = 1'b0;

    // ---- The whole frame. The line is sampled at the middle of each of the
    // ten intervals and echoed to the log, so the wire order in the picture
    // and the wire order in the text are the same claim and a reader can
    // check one against the other. These are $display lines, not checks: this
    // file contributes nothing to the suite's 609.
    for (i = 0; i < 10; i = i + 1) begin
      target = i * DIV_TX + (DIV_TX / 2);
      while (cyc_since_accept < target) @(posedge clk);
      #1;
      wire_bits[i] = tx_line;
    end
    $display("  observed wire order (mid-interval samples): start=%0b  d0..d7=%0b%0b%0b%0b%0b%0b%0b%0b  stop=%0b",
             wire_bits[0], wire_bits[1], wire_bits[2], wire_bits[3], wire_bits[4],
             wire_bits[5], wire_bits[6], wire_bits[7], wire_bits[8], wire_bits[9]);
    $display("  0x%02x LSB-first predicts d0..d7 = %0b%0b%0b%0b%0b%0b%0b%0b (MSB-first would give the reverse)",
             SHOW, SHOW[0], SHOW[1], SHOW[2], SHOW[3], SHOW[4], SHOW[5], SHOW[6], SHOW[7]);

    // ---- Short tail, so the stop bit ending and tx_ready returning are both
    // inside the dump rather than at its edge.
    repeat (DIV_TX / 2 + 30) @(posedge clk);
    framing = 1'b0;
    repeat (20) @(posedge clk);

    $display("  VCD: build/wave/wv_tx.vcd");
    $finish;
  end

endmodule
