// wv_fifo.sv -- WAVEFORM VIGNETTE for uart_fifo.
//
// NOT A TEST. A demonstration: one deliberately staged scenario, a
// reader-sized VCD, zero checks contributed to the suite. Not run by
// test/run.sh.
//
// ---------------------------------------------------------------------------
// WHAT A READER SHOULD LOOK AT
// ---------------------------------------------------------------------------
// The two flags at their exact boundaries, and the two silent-ignore rules
// (SPEC SS5.4; REQ-015). In order along the time axis:
//
//   1. Post-reset: `empty` high, `level` = 0, `full` low.
//   2. Four writes. `level` climbs 1,2,3,4 and `empty` drops on the first.
//      `rd_data` shows the head from the moment the first entry lands --
//      first-word fall-through, no read latency.
//   3. ONE SIMULTANEOUS PUSH AND POP: `wr_en` and `rd_en` high together in the
//      same cycle. `level` does not move, and the head advances by one. The
//      design permits this; watch that it is a genuine no-change on level
//      rather than a write that got dropped.
//   4. Fill to DEPTH. `full` rises in the SAME cycle `level` reaches 16, not
//      one before and not one after. This is the boundary a suite can get
//      wrong in a way that looks right: a `full` flag that asserts one entry
//      early still reads high wherever anyone checks that it is high.
//   5. A 17th write while full. `level`, `full` and `rd_data` are all
//      unchanged -- the write is silently ignored, and no flag is raised by
//      this module. The overrun policy lives at the top level (SPEC SS5.5),
//      not here.
//   6. Drain all 16. Bytes come out in the order written, `full` drops on the
//      first pop, `empty` rises exactly as `level` reaches 0.
//   7. A pop while empty. Nothing moves.
//
// ---------------------------------------------------------------------------
// PARAMETER CHOICES, AND WHY
// ---------------------------------------------------------------------------
//   DEPTH = 16, W = 8   The real configuration (SPEC SS5.4, SS4). Unlike the
//                       divisors, the depth costs nothing in readability: the
//                       whole scenario -- fill, overflow, drain, underflow --
//                       is about 60 clock cycles, so the VCD is a few
//                       kilobytes and the entire picture fits on one screen.
//                       Shrinking DEPTH would only make the `full` boundary
//                       less like the one the design actually ships.
//   data = 0x11,0x22…   Ascending, visually distinct, and each byte's value
//                       encodes its own arrival order, so a reader can verify
//                       ordering off `rd_data` alone without counting pops.
`timescale 1ns/1ps

module wv_fifo;

  localparam int CLK_PERIOD_NS = 20;  // 50 MHz, SPEC SS2
  localparam int DEPTH         = 16;  // SPEC SS5.4
  localparam int W             = 8;   // SPEC SS5.4
  localparam int LVL_W         = $clog2(DEPTH) + 1;

  logic clk = 1'b0;
  always #(CLK_PERIOD_NS/2) clk = ~clk;

  logic             rst;
  logic             wr_en;
  logic [W-1:0]     wr_data;
  logic             rd_en;
  logic [W-1:0]     rd_data;
  logic             full;
  logic             empty;
  logic [LVL_W-1:0] level;

  uart_fifo #(.DEPTH(DEPTH), .W(W)) dut (
      .clk     (clk),
      .rst     (rst),
      .wr_en   (wr_en),
      .wr_data (wr_data),
      .rd_en   (rd_en),
      .rd_data (rd_data),
      .full    (full),
      .empty   (empty),
      .level   (level)
  );

  initial begin
    $dumpfile("build/wave/wv_fifo.vcd");
    // Depth 1 on the named bench scope: the eight ports and nothing else. The
    // FIFO's storage array is deliberately not dumped -- the specification
    // constrains rd_data, full, empty and level, and a reader who checks the
    // memory contents instead of the interface is checking the wrong thing.
    $dumpvars(1, wv_fifo);
  end

  task automatic step(input bit do_wr, input logic [W-1:0] data, input bit do_rd);
    @(negedge clk);
    wr_en   = do_wr;
    wr_data = data;
    rd_en   = do_rd;
    @(posedge clk);
    #1;
  endtask

  int i;
  logic [W-1:0] popped;

  initial begin
    $display("==== VIGNETTE (wv_fifo) ====");
    $display("Look at the two flag boundaries: full rises in the SAME cycle level reaches DEPTH=%0d, empty rises in the same cycle level reaches 0 -- and watch the 17th write and the pop-while-empty change nothing at all.", DEPTH);

    rst     = 1'b1;
    wr_en   = 1'b0;
    rd_en   = 1'b0;
    wr_data = '0;
    repeat (3) @(negedge clk);
    rst = 1'b0;
    @(posedge clk);
    #1;
    $display("  post-reset: empty=%0b level=%0d full=%0b", empty, level, full);

    // ---- Four writes: 0x11 0x22 0x33 0x44.
    for (i = 1; i <= 4; i = i + 1) step(1'b1, 8'h11 * i[7:0], 1'b0);
    step(1'b0, '0, 1'b0);
    $display("  after 4 writes: level=%0d head=0x%02x", level, rd_data);

    // ---- One simultaneous push and pop.
    popped = rd_data;
    step(1'b1, 8'h99, 1'b1);
    $display("  simultaneous push(0x99)+pop: popped 0x%02x, level=%0d (unchanged), new head=0x%02x",
             popped, level, rd_data);
    step(1'b0, '0, 1'b0);

    // ---- Fill the rest of the way to DEPTH.
    for (i = 0; i < DEPTH - 4; i = i + 1) step(1'b1, 8'hA0 + i[7:0], 1'b0);
    step(1'b0, '0, 1'b0);
    $display("  filled: level=%0d full=%0b empty=%0b", level, full, empty);

    // ---- A 17th write while full: silently ignored (SPEC SS5.4).
    step(1'b1, 8'hFF, 1'b0);
    step(1'b0, '0, 1'b0);
    $display("  write while full: level=%0d full=%0b head=0x%02x (all unchanged)", level, full, rd_data);

    // ---- Drain to empty.
    for (i = 0; i < DEPTH; i = i + 1) step(1'b0, '0, 1'b1);
    step(1'b0, '0, 1'b0);
    $display("  drained: level=%0d empty=%0b full=%0b", level, empty, full);

    // ---- A pop while empty: silently ignored (SPEC SS5.4).
    step(1'b0, '0, 1'b1);
    step(1'b0, '0, 1'b0);
    $display("  pop while empty: level=%0d empty=%0b (unchanged)", level, empty);

    repeat (4) @(posedge clk);
    $display("  VCD: build/wave/wv_fifo.vcd");
    $finish;
  end

endmodule
