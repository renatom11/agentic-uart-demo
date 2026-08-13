// uart_tick_gen — divide-by-N strobe with a restart input (SPEC §5.1).
//
// If `restart` is high during cycle L, `tick` is high during cycles L+N,
// L+2N, ...
//
// The reload value is 0. Reloading to 1 looks right on paper — "the counter
// starts at one" — but the reload cycle is itself consumed, so the first tick
// lands one cycle early and every later tick is correct. That is what makes
// this defect hard to see: the SPACING between ticks is N under either value,
// so the only check that can tell them apart measures from the restart to the
// FIRST tick. In the transmitter it showed up as a start bit of 433 cycles
// with all nine following intervals at 434.
module uart_tick_gen #(
  parameter int N = 27
) (
  input  logic clk,
  input  logic rst,
  input  logic restart,
  output logic tick
);
  localparam int CW = (N < 3) ? 2 : $clog2(N);
  logic [CW-1:0] cnt;

  always_ff @(posedge clk) begin
    if (rst || restart) begin
      cnt  <= '0;
      tick <= 1'b0;
    end else if (cnt == CW'(N - 1)) begin
      cnt  <= '0;
      tick <= 1'b1;
    end else begin
      cnt  <= cnt + CW'(1);
      tick <= 1'b0;
    end
  end
endmodule
