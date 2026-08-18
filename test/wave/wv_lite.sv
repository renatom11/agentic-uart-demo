// wv_lite.sv -- WAVEFORM VIGNETTE for uart_lite (top level).
//
// NOT A TEST. A demonstration: one deliberately staged scenario, a
// reader-sized VCD, zero checks contributed to the suite. Not run by
// test/run.sh.
//
// ---------------------------------------------------------------------------
// WHAT A READER SHOULD LOOK AT
// ---------------------------------------------------------------------------
// One byte making the whole round trip, and the two handshakes that carry it
// (SPEC SS5.5; REQ-016, REQ-017):
//
//   * `tx_valid` & `tx_ready` high together for one cycle -- the byte is
//     accepted. `tx_ready` falls the next cycle and stays low for the whole
//     frame.
//   * `tx_line` carries the frame. `rx_line` is wired to it by this bench,
//     so the same wire is both ends of the link.
//   * `rx_valid` rises when the byte reaches the head of the receive FIFO.
//     `rx_data` is valid from that moment -- first-word fall-through, no read
//     latency -- and the host pops on `rx_valid & rx_ready`.
//   * `rx_overrun` and `rx_frame_err` stay low throughout. A clean round trip
//     raises neither.
//
// ---------------------------------------------------------------------------
// WHAT THIS PICTURE IS NOT EVIDENCE OF
// ---------------------------------------------------------------------------
// Read REQ-017's own text before drawing a conclusion from this waveform:
// "This requirement is deliberately weak: transmitter and receiver derive
// their timing from the same clock, so a loopback pass is evidence about
// self-consistency and not about either side's agreement with the world. It
// never discharges REQ-011."
//
// A loopback that works proves the two halves agree with each other. Both
// could be wrong by the same amount and this picture would look identical.
// The requirement that actually pins the receiver to the outside world is
// REQ-011, whose 6656-check sweep over sender bit periods 422..447 has no
// readable waveform at all -- which is the honest reason these vignettes
// exist beside the suite rather than instead of it.
//
// ---------------------------------------------------------------------------
// PARAMETER CHOICES, AND WHY
// ---------------------------------------------------------------------------
//   byte = 8'hA3     Asymmetric under bit reversal, so the wire order is
//                    readable off tx_line without trusting a label. Same byte
//                    as wv_tx, so the two pictures can be laid side by side.
//   real divisors    SPEC SS5.5 declares no divisor parameter on uart_lite --
//                    the constants live in uart_pkg (SPEC SS4) -- so a bench
//                    derived from the specification has no legal way to shrink
//                    the bit period, and inventing one would mean reading the
//                    design rather than its spec. The round trip is therefore
//                    ~4400 cycles.
//   ONE byte only    The scenario is cut to a single byte rather than a run:
//                    the whole point is the handshake shape, which a second
//                    byte repeats without adding anything, at the cost of
//                    doubling the file.
//   no cycle counter Unlike wv_tx and wv_rx, this vignette dumps no
//                    cycle-index marker. The claim here is about handshake
//                    ORDER, not about cycle-accurate timing, and a 16-bit bus
//                    changing every cycle is, measured, roughly half the bytes
//                    of a dump this length.
`timescale 1ns/1ps

module wv_lite;

  localparam int CLK_PERIOD_NS = 20;      // 50 MHz, SPEC SS2
  localparam logic [7:0] SHOW  = 8'hA3;   // see header

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

  // The loopback itself: one wire, both ends of the link.
  assign rx_line = tx_line;

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

  initial begin
    $dumpfile("build/wave/wv_lite.vcd");
    // Depth 1 on the named bench scope: the twelve top-level ports and
    // nothing below them. The submodule hierarchy is deliberately excluded --
    // this vignette is about the interface contract, and the per-module
    // pictures are wv_tx, wv_rx, wv_fifo and wv_tick_gen.
    $dumpvars(1, wv_lite);
  end

  logic accepted;
  // The round-trip bound is kept in a `time` snapshot rather than a
  // per-cycle counter: a counter at module scope is dumped, ticks every
  // cycle, and measured 74 KB of this file -- a third of it -- to tell a
  // reader something the clock already tells them.
  time  t0;
  int   elapsed;

  initial begin
    $display("==== VIGNETTE (wv_lite) ====");
    $display("Look at the two handshakes around one byte: tx_valid & tx_ready high together accepts 0x%02x, tx_line carries the frame into rx_line, rx_valid rises when the byte reaches the FIFO head, and rx_valid & rx_ready pops it -- with rx_overrun and rx_frame_err low throughout.", SHOW);

    // ---- Reset. SPEC SS6: one cycle after rst deasserts, tx_line = 1,
    // tx_ready = 1, the FIFO is empty and rx_overrun = 0.
    rst        = 1'b1;
    tx_valid   = 1'b0;
    tx_data    = '0;
    rx_ready   = 1'b0;
    rx_ovr_clr = 1'b0;
    repeat (5) @(negedge clk);
    rst = 1'b0;
    @(posedge clk);
    #1;
    $display("  one cycle after reset: tx_line=%0b tx_ready=%0b rx_valid=%0b rx_overrun=%0b",
             tx_line, tx_ready, rx_valid, rx_overrun);
    repeat (20) @(posedge clk);

    // ---- Offer the byte; hold tx_valid until it is accepted.
    @(negedge clk);
    tx_data  = SHOW;
    tx_valid = 1'b1;
    accepted = 1'b0;
    while (!accepted) begin
      @(posedge clk);
      if (tx_valid === 1'b1 && tx_ready === 1'b1) accepted = 1'b1;
    end
    #1;
    @(negedge clk);
    tx_valid = 1'b0;

    // ---- Wait for the byte to come back round. The guard is a bench-side
    // bound, not a check: a run that hits it has hung, and a picture of a hang
    // is not the picture this file is for.
    t0 = $time;
    while (!rx_valid && (($time - t0) < 20000 * CLK_PERIOD_NS)) begin
      @(posedge clk);
      #1;
    end
    elapsed = ($time - t0) / CLK_PERIOD_NS; // $time is in this file's 1ns time unit
    $display("  round trip: rx_valid=%0b after %0d cycles, rx_data=0x%02x (sent 0x%02x), rx_frame_err=%0b rx_overrun=%0b",
             rx_valid, elapsed, rx_data, SHOW, rx_frame_err, rx_overrun);

    // ---- Pop it: one cycle of rx_valid & rx_ready.
    repeat (10) @(posedge clk);
    @(negedge clk);
    rx_ready = 1'b1;
    @(negedge clk);
    rx_ready = 1'b0;
    repeat (10) @(posedge clk);
    #1;
    $display("  after the pop: rx_valid=%0b (FIFO empty again)", rx_valid);

    repeat (20) @(posedge clk);
    $display("  VCD: build/wave/wv_lite.vcd");
    $finish;
  end

endmodule
