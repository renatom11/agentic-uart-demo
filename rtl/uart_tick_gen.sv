// uart_tick_gen — divide-by-N strobe with a restart input (SPEC §5.1).
//
// If `restart` is high during cycle L, `tick` is high during cycles L+N,
// L+2N, ... The counter comparison is against N-1, and the counter reloads
// to 1 (not 0) on restart, which is what puts the first tick exactly N
// cycles after the restart rather than N-1.
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
      cnt  <= CW'(1);
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
