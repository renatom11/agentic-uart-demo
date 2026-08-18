// wv_tick_gen.sv -- WAVEFORM VIGNETTE for uart_tick_gen.
//
// NOT A TEST. This file is a demonstration: it stages one short, deliberately
// chosen scenario and dumps a reader-sized VCD. It contributes zero checks to
// the suite and is not run by test/run.sh. The suite is test/run.sh; the
// vignettes are test/wave/run_wave.sh.
//
// ---------------------------------------------------------------------------
// WHAT A READER SHOULD LOOK AT
// ---------------------------------------------------------------------------
// The PHASE of the first tick, not the spacing between ticks. Spacing is N
// under every off-by-one anchor convention, which is exactly why BUG-0001
// survived every interval-based check and was caught only by a measurement
// taken from the anchor cycle to the first tick (SPEC SS5.1; REQ-005).
//
// The marker bus `cyc_since_anchor` makes that phase directly readable: it
// reads 0 during the anchor cycle -- the cycle in which `rst` or `restart` is
// SAMPLED HIGH -- and increments from there. A conforming design raises `tick`
// in the cycle where `cyc_since_anchor` reads exactly N. A design with
// BUG-0001 raises it where the bus reads N-1; the opposite off-by-one raises
// it at N+1. All three look identical if you only measure tick-to-tick.
//
// ---------------------------------------------------------------------------
// PARAMETER CHOICES, AND WHY
// ---------------------------------------------------------------------------
//   N = 8            The real design instantiates this module at N=434 (tx bit
//                    period) and N=27 (rx oversample). Neither is legible: at
//                    N=434 the first tick is 434 clock edges from the anchor
//                    and a reader cannot count the gap by eye. N is a declared
//                    parameter of this module (SPEC SS5.1), so the vignette is
//                    free to pick a small one. 8 is the smallest value that
//                    still shows a countable gap and an obviously off-grid
//                    restart. SPEC SS5.1 requires only N >= 2.
//   restart at +5    The restart pulse is placed 5 cycles after a tick --
//                    deliberately NOT on the tick grid -- so the picture shows
//                    the counter being forced to 0 mid-interval rather than
//                    merely reloading where it would have reloaded anyway.
//
// The dumped scope is named explicitly and is small on purpose: the six bench
// signals plus one level of the DUT, so the internal divider state is visible
// beside the phase marker. Nothing else is dumped.
`timescale 1ns/1ps

module wv_tick_gen;

  localparam int CLK_PERIOD_NS = 20; // 50 MHz, as SPEC SS2
  localparam int N             = 8;  // see header

  logic clk = 1'b0;
  always #(CLK_PERIOD_NS/2) clk = ~clk;

  logic rst;
  logic restart;
  logic tick;

  uart_tick_gen #(.N(N)) dut (
      .clk     (clk),
      .rst     (rst),
      .restart (restart),
      .tick    (tick)
  );

  // ---- Reader marker: the spec's own cycle numbering, made visible.
  // SPEC SS5.1: "Cycle 0 is the cycle in which rst or restart is SAMPLED HIGH
  // -- not the cycle after it." anchor_cyc is therefore combinational, high
  // throughout the anchor cycle itself, and the counter is zeroed by the same
  // posedge that begins that cycle.
  logic        anchor_cyc;
  logic [15:0] cyc_since_anchor;

  assign anchor_cyc = rst | restart;

  always @(posedge clk) begin
    if (anchor_cyc) cyc_since_anchor <= 16'd0;
    else            cyc_since_anchor <= cyc_since_anchor + 16'd1;
  end

  initial begin
    $dumpfile("build/wave/wv_tick_gen.vcd");
    // Depth 2 on the named bench scope: the six bench signals plus ONE level
    // of children, i.e. the divider instance's own state. Not depth 0 -- a
    // whole-hierarchy dump is what makes a VCD unreadable.
    $dumpvars(2, wv_tick_gen);
  end

  int first_tick_after_reset;
  int first_tick_after_restart;

  initial begin
    $display("==== VIGNETTE (wv_tick_gen) ====");
    $display("Look at the PHASE of the first tick: tick is high in the cycle where cyc_since_anchor reads N=%0d, counting the cycle in which rst/restart is sampled high as 0. Spacing alone cannot tell a correct anchor from BUG-0001.", N);

    // ---- Reset release, then the first tick.
    rst     = 1'b1;
    restart = 1'b0;
    repeat (3) @(negedge clk);
    rst = 1'b0;   // dropped between edges: the last posedge with rst high was the anchor

    first_tick_after_reset = -1;
    while (first_tick_after_reset < 0) begin
      @(posedge clk);
      #1;
      if (tick === 1'b1) first_tick_after_reset = cyc_since_anchor;
    end
    $display("  reset anchor  -> first tick at cyc_since_anchor=%0d (spec: %0d)",
             first_tick_after_reset, N);

    // ---- Two more ticks, so the reader can see the steady-state grid.
    repeat (2 * N) @(posedge clk);

    // ---- Restart pulse at a deliberately off-grid phase.
    repeat (5) @(posedge clk);
    @(negedge clk);
    restart = 1'b1;
    @(negedge clk);
    restart = 1'b0;

    first_tick_after_restart = -1;
    while (first_tick_after_restart < 0) begin
      @(posedge clk);
      #1;
      if (tick === 1'b1) first_tick_after_restart = cyc_since_anchor;
    end
    $display("  restart anchor-> first tick at cyc_since_anchor=%0d (spec: %0d)",
             first_tick_after_restart, N);

    // ---- Tail: one more interval, so the last tick is not at the edge of the
    // dump and the reader can see the grid resume.
    repeat (N + 2) @(posedge clk);

    $display("  VCD: build/wave/wv_tick_gen.vcd");
    $finish;
  end

endmodule
