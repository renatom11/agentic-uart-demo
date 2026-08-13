// tb_uart_fifo.sv
//
// Discharges REQ-015 (FIFO ordering and exactness).
//
// Derived solely from docs/specs/SPEC-uart_lite.md SS5.4 and
// docs/specs/requirements.md REQ-015. No RTL was read to write this file.
//
// SS5.4 contract under test (uart_fifo #(DEPTH=16, W=8)):
//   "rd_data: head of the queue, valid whenever !empty (first-word
//    fall-through). full/empty: exact. level: number of entries stored.
//    A write while full is silently ignored: stored entries are unchanged
//    and no flag is raised by this module." "rd_en: pop request; ignored
//    when empty."
`timescale 1ns/1ps

module tb_uart_fifo;

  localparam int CLK_PERIOD_NS = 20; // 50 MHz
  localparam int DEPTH = 16;
  localparam int W = 8;
  localparam int LVL_W = $clog2(DEPTH) + 1;
  localparam int NUM_RANDOM_OPS = 10000;

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

  // Software reference model: a queue mirroring exactly what the FIFO
  // should contain, updated using the same rules stated in SS5.4.
  logic [W-1:0] model_q[$];

  task automatic do_reset();
    rst = 1'b1;
    wr_en = 1'b0;
    rd_en = 1'b0;
    wr_data = '0;
    repeat (3) @(negedge clk);
    rst = 1'b0;
    @(posedge clk);
    #1;
    model_q.delete();
  endtask

  // Drive one cycle of stimulus and update the model using its PRE-edge
  // state (matching "ignored when empty" / "ignored while full", which are
  // conditions on the FIFO's state at the time of the request).
  task automatic drive_cycle(input bit do_wr, input logic [W-1:0] data, input bit do_rd);
    bit was_full;
    bit was_empty;
    was_full  = (model_q.size() == DEPTH);
    was_empty = (model_q.size() == 0);
    @(negedge clk);
    wr_en   = do_wr;
    wr_data = data;
    rd_en   = do_rd;
    if (do_wr && !was_full) model_q.push_back(data);
    if (do_rd && !was_empty) void'(model_q.pop_front());
    @(posedge clk);
    #1;
  endtask

  // Compare DUT outputs against the model's now-settled state. Accumulates
  // into the module-level error counters below (kept as globals, not task
  // ref args -- this Icarus Verilog build does not support reference ports).
  int rd_errors, full_errors, empty_errors, level_errors;

  task automatic check_state(input string ctx);
    bit exp_empty;
    bit exp_full;
    int exp_level;
    exp_level = model_q.size();
    exp_empty = (exp_level == 0);
    exp_full  = (exp_level == DEPTH);
    if (empty !== exp_empty) empty_errors = empty_errors + 1;
    if (full !== exp_full) full_errors = full_errors + 1;
    if (level !== exp_level[LVL_W-1:0]) level_errors = level_errors + 1;
    if (!exp_empty) begin
      if (rd_data !== model_q[0]) rd_errors = rd_errors + 1;
    end
  endtask

  int i;
  int seed;
  bit ignore_full_ok;
  bit ignore_empty_ok;
  bit order_ok;
  logic [W-1:0] popped;

  initial begin
    do_reset();

    // ---- Directed sanity: post-reset state.
    check(empty === 1'b1, "REQ-015", "post-reset: empty is asserted");
    check(level === '0, "REQ-015", "post-reset: level is 0");
    check(full === 1'b0, "REQ-015", "post-reset: full is not asserted");

    // ---- Directed: order preservation for a known run of writes/reads.
    order_ok = 1'b1;
    for (i = 0; i < DEPTH; i = i + 1) begin
      drive_cycle(1'b1, i[W-1:0], 1'b0);
    end
    // stop writing (fifo now full at DEPTH entries: 0,1,...,DEPTH-1)
    wr_en = 1'b0;
    @(negedge clk); @(posedge clk); #1;
    check(full === 1'b1, "REQ-015", $sformatf("full asserted exactly when level=DEPTH=%0d after %0d writes", DEPTH, DEPTH));
    check(level === DEPTH[LVL_W-1:0], "REQ-015", $sformatf("level==DEPTH=%0d after %0d writes", DEPTH, DEPTH));

    // ---- Directed: a write while full is silently ignored.
    ignore_full_ok = 1'b1;
    drive_cycle(1'b1, 8'hFF, 1'b0); // attempt a 17th write while full
    if (level !== DEPTH[LVL_W-1:0]) ignore_full_ok = 1'b0;
    if (full !== 1'b1) ignore_full_ok = 1'b0;
    if (rd_data !== 8'h00) ignore_full_ok = 1'b0; // head (byte 0) must be unchanged
    check(ignore_full_ok, "REQ-015", "a write while full is silently ignored: level, full, and head unchanged");

    // ---- Directed: pop all DEPTH entries, verify order-of-write == order-of-read.
    for (i = 0; i < DEPTH; i = i + 1) begin
      popped = rd_data;
      if (popped !== i[W-1:0]) order_ok = 1'b0;
      drive_cycle(1'b0, '0, 1'b1);
    end
    check(order_ok, "REQ-015", $sformatf("entries read back in the exact order written (%0d-entry run)", DEPTH));
    check(empty === 1'b1, "REQ-015", "empty asserted exactly when level=0 after draining all entries");

    // ---- Directed: a pop while empty is silently ignored.
    ignore_empty_ok = 1'b1;
    drive_cycle(1'b0, '0, 1'b1); // attempt a pop while empty
    if (empty !== 1'b1) ignore_empty_ok = 1'b0;
    if (level !== '0) ignore_empty_ok = 1'b0;
    check(ignore_empty_ok, "REQ-015", "a pop while empty is silently ignored: empty and level unchanged");

    // ---- Randomised sweep: NUM_RANDOM_OPS operations, biased across three
    // phases (fill-biased, drain-biased, balanced) so the full and empty
    // boundaries are both hit many times, not just reachable in principle.
    seed = 32'hD00D_F1F0; // fixed seed: reproducible run
    void'($urandom(seed));
    rd_errors = 0; full_errors = 0; empty_errors = 0; level_errors = 0;
    do_reset();
    check_state("post-reset-2");

    for (i = 0; i < NUM_RANDOM_OPS; i = i + 1) begin
      bit do_wr, do_rd;
      logic [W-1:0] data;
      int phase_wr_pct, phase_rd_pct;
      if (i < NUM_RANDOM_OPS / 3) begin
        phase_wr_pct = 80; phase_rd_pct = 30; // fill-biased
      end else if (i < 2 * NUM_RANDOM_OPS / 3) begin
        phase_wr_pct = 30; phase_rd_pct = 80; // drain-biased
      end else begin
        phase_wr_pct = 55; phase_rd_pct = 55; // balanced churn
      end
      do_wr = ($urandom_range(0, 99) < phase_wr_pct);
      do_rd = ($urandom_range(0, 99) < phase_rd_pct);
      data  = $urandom_range(0, 255);
      drive_cycle(do_wr, data, do_rd);
      check_state("random-sweep");
    end

    check(rd_errors == 0, "REQ-015",
          $sformatf("rd_data equals model head (first-word fall-through) over %0d random operations (%0d mismatches)", NUM_RANDOM_OPS, rd_errors));
    check(full_errors == 0, "REQ-015",
          $sformatf("full asserted exactly when level=DEPTH over %0d random operations (%0d mismatches)", NUM_RANDOM_OPS, full_errors));
    check(empty_errors == 0, "REQ-015",
          $sformatf("empty asserted exactly when level=0 over %0d random operations (%0d mismatches)", NUM_RANDOM_OPS, empty_errors));
    check(level_errors == 0, "REQ-015",
          $sformatf("level tracks the reference model exactly over %0d random operations (%0d mismatches)", NUM_RANDOM_OPS, level_errors));

    $display("==== SUMMARY (tb_uart_fifo) ====");
    $display("Total: %0d  Pass: %0d  Fail: %0d", pass_count + fail_count, pass_count, fail_count);
    if (fail_count > 0) begin
      $fatal(1, "tb_uart_fifo: %0d check(s) FAILED", fail_count);
    end else begin
      $display("tb_uart_fifo: ALL CHECKS PASSED");
    end
    $finish;
  end

endmodule
