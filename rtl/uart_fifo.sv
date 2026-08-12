// uart_fifo — synchronous FIFO, first-word fall-through (SPEC §5.4).
// A write while full is silently ignored; this module raises no flag of its
// own. The overrun policy belongs to the top level.
module uart_fifo #(
  parameter int DEPTH = 16,
  parameter int W     = 8
) (
  input  logic                     clk,
  input  logic                     rst,
  input  logic                     wr_en,
  input  logic [W-1:0]             wr_data,
  input  logic                     rd_en,
  output logic [W-1:0]             rd_data,
  output logic                     full,
  output logic                     empty,
  output logic [$clog2(DEPTH):0]   level
);
  localparam int AW = $clog2(DEPTH);
  logic [W-1:0]  mem [DEPTH];
  logic [AW-1:0] wp, rp;
  logic          do_wr, do_rd;

  assign full    = (level == ($clog2(DEPTH)+1)'(DEPTH));
  assign empty   = (level == '0);
  assign do_wr   = wr_en & ~full;
  assign do_rd   = rd_en & ~empty;
  assign rd_data = mem[rp];

  always_ff @(posedge clk) begin
    if (rst) begin
      wp <= '0; rp <= '0; level <= '0;
    end else begin
      if (do_wr) begin mem[wp] <= wr_data; wp <= wp + AW'(1); end
      if (do_rd) rp <= rp + AW'(1);
      case ({do_wr, do_rd})
        2'b10:   level <= level + 1;
        2'b01:   level <= level - 1;
        default: level <= level;
      endcase
    end
  end
endmodule
