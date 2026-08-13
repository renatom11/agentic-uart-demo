// tb_uart_tick_gen.sv
//
// Discharges REQ-005 (oversample tick rate), verified in CLOCK CYCLES, never
// in ticks, per requirements.md's explicit instruction.
//
// Derived solely from docs/specs/SPEC-uart_lite.md SS5.1 and
// docs/specs/requirements.md REQ-005. No RTL was read to write this file.
//
// SS5.1 / REQ-005 contract under test:
//   "Counting the cycle after reset release (or after a restart pulse) as
//    cycle 0, the k-th tick is high during cycle N.k. tick is never high in
//    two consecutive cycles. N must be at least 2."
//   "restart: when high, the counter is forced to 0 for that cycle and tick
//    is suppressed."
//
// k-indexing: "the k-th tick is high during cycle N.k" is read with k
// ranging over the positive integers {1,2,3,...} -- the ordinary reading of
// an ordinal ("the first tick", "the second tick", ...), giving no tick at
// cycle 0 itself and the first tick at cycle N. This bench asserts that
// literal schedule and, where the DUT's observed schedule disagrees with it,
// reports the mismatch as a failing check rather than adjusting the
// expectation -- see the Return log for the finding this produced.
//
// Each check is decomposed into three independent properties so a mismatch
// is diagnosable: (1) WHERE the first tick after the anchor event lands
// (the phase/anchor claim), (2) that consecutive ticks are exactly N cycles
// apart (the rate claim), (3) that tick is never high on two consecutive
// cycles. This is deliberately finer-grained than a single aggregate
// "pattern matches" check, precisely so a phase-only defect is not buried
// under to a monolithic FAIL.
`timescale 1ns/1ps

module tb_uart_tick_gen;

  localparam int CLK_PERIOD_NS = 20; // 50 MHz

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

  localparam int NUM_N = 4;

  function automatic int n_value(input int idx);
    case (idx)
      0: n_value = 2;
      1: n_value = 3;
      2: n_value = 27;
      default: n_value = 434; // idx == 3
    endcase
  endfunction

  // Sequencing: each generate-block instance waits its turn so the printed
  // output is ordered N=2, N=3, N=27, N=434, and so no two instances drive
  // the shared pass/fail counters concurrently.
  int turn = 0;

  genvar gi;
  generate
    for (gi = 0; gi < NUM_N; gi = gi + 1) begin : g_tickgen
      logic rst_i;
      logic restart_i;
      logic tick_o;

      uart_tick_gen #(.N(n_value(gi))) dut (
          .clk     (clk),
          .rst     (rst_i),
          .restart (restart_i),
          .tick    (tick_o)
      );

      // Runs `span` cycles from the calling context's current position and
      // records: first_tick (cycle index, relative to this call's cycle 0,
      // of the first observed tick; -1 if none seen), spacing_errors (count
      // of consecutive-tick gaps that are not exactly N), and
      // consecutive_errors (count of cycles where tick followed a tick with
      // no gap).
      task automatic observe_tick_pattern(
          input int n,
          input int span,
          output int first_tick,
          output int spacing_errors,
          output int consecutive_errors
      );
        int cyc;
        int prev_tick_cycle;
        bit prev_val;
        first_tick = -1;
        spacing_errors = 0;
        consecutive_errors = 0;
        prev_tick_cycle = -1;
        prev_val = 1'b0;
        for (cyc = 0; cyc < span; cyc = cyc + 1) begin
          @(posedge clk);
          #1;
          if (tick_o === 1'b1) begin
            if (first_tick == -1) first_tick = cyc;
            if (prev_tick_cycle != -1 && (cyc - prev_tick_cycle) != n) spacing_errors = spacing_errors + 1;
            if (prev_val === 1'b1) consecutive_errors = consecutive_errors + 1;
            prev_tick_cycle = cyc;
          end
          prev_val = tick_o;
        end
      endtask

      task automatic run_sweep();
        int n;
        int span;
        bit tick_during_restart;
        int first_tick;
        int spacing_errors;
        int consecutive_errors;
        n = n_value(gi);

        // ---- Reset-anchored pattern.
        // SPEC 5.1 anchor (amended at 21b8b2d after this bench found the
        // original wording off by one): cycle 0 is the cycle in which rst is
        // SAMPLED HIGH, not the cycle after it. observe_tick_pattern() labels
        // its first observed posedge 0, and that posedge is the one AFTER the
        // anchor, so an observation of c is spec-cycle c+1. The conversion is
        // written out rather than folded into the expected value, so the
        // anchor stays visible to a reader.
        rst_i = 1'b1;
        restart_i = 1'b0;
        repeat (3) @(negedge clk);
        rst_i = 1'b0; // dropped between edges; the last posedge with rst high was the anchor

        span = 5 * n;
        observe_tick_pattern(n, span, first_tick, spacing_errors, consecutive_errors);
        first_tick = first_tick + 1;   // observation cycles -> spec cycles

        check(first_tick == n, "REQ-005",
              $sformatf("N=%0d: first tick after reset lands at cycle N=%0d (k=1 in \"k-th tick at cycle N.k\"); observed first tick at cycle %0d",
                         n, n, first_tick));
        check(spacing_errors == 0, "REQ-005",
              $sformatf("N=%0d: consecutive ticks are exactly N=%0d cycles apart, checked over %0d post-reset cycles (%0d gap mismatches)",
                         n, n, span, spacing_errors));
        check(consecutive_errors == 0, "REQ-005",
              $sformatf("N=%0d: tick never high on two consecutive cycles, checked over %0d post-reset cycles (%0d violations)",
                         n, span, consecutive_errors));

        // ---- Restart-anchored pattern: cycle 0 = the cycle in which restart
        // is SAMPLED HIGH (SPEC 5.1 as amended). Tick must be suppressed
        // during the anchor cycle itself, per SS5.1's port table.
        repeat (2 * n + (n / 2) + 1) @(posedge clk); // run into an arbitrary phase
        @(negedge clk);
        restart_i = 1'b1;
        @(posedge clk);
        #1;
        tick_during_restart = tick_o;
        @(negedge clk);
        restart_i = 1'b0;

        span = 3 * n;
        observe_tick_pattern(n, span, first_tick, spacing_errors, consecutive_errors);
        first_tick = first_tick + 1;   // observation cycles -> spec cycles (see above)

        check(tick_during_restart === 1'b0, "REQ-005",
              $sformatf("N=%0d: tick suppressed during the restart pulse cycle itself", n));
        check(first_tick == n, "REQ-005",
              $sformatf("N=%0d: first tick after restart lands N=%0d cycles after the restart pulse cycle (k=1 convention); observed at %0d cycles after",
                         n, n, first_tick));
        check(spacing_errors == 0, "REQ-005",
              $sformatf("N=%0d: post-restart consecutive ticks are exactly N=%0d cycles apart, checked over %0d cycles (%0d gap mismatches)",
                         n, n, span, spacing_errors));
        check(consecutive_errors == 0, "REQ-005",
              $sformatf("N=%0d: post-restart tick never high on two consecutive cycles, checked over %0d cycles (%0d violations)",
                         n, span, consecutive_errors));
      endtask

      initial begin
        wait (turn == gi);
        run_sweep();
        turn = turn + 1;
      end
    end
  endgenerate

  initial begin
    wait (turn == NUM_N);
    $display("==== SUMMARY (tb_uart_tick_gen) ====");
    $display("Total: %0d  Pass: %0d  Fail: %0d", pass_count + fail_count, pass_count, fail_count);
    if (fail_count > 0) begin
      $fatal(1, "tb_uart_tick_gen: %0d check(s) FAILED", fail_count);
    end else begin
      $display("tb_uart_tick_gen: ALL CHECKS PASSED");
    end
    $finish;
  end

endmodule
