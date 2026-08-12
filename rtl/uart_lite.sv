// uart_lite — top level (SPEC §5.5).
module uart_lite
  import uart_pkg::*;
(
  input  logic       clk,
  input  logic       rst,
  // host side
  input  logic [7:0] tx_data,
  input  logic       tx_valid,
  output logic       tx_ready,
  output logic [7:0] rx_data,
  output logic       rx_valid,
  input  logic       rx_ready,
  output logic       rx_overrun,
  input  logic       rx_ovr_clr,
  output logic       rx_frame_err,
  // wire side
  output logic       tx_line,
  input  logic       rx_line
);
  logic [7:0] rxb;
  logic       rxs, rxfe, rxbusy, ffull, fempty;
  logic [$clog2(FIFO_DEPTH):0] flevel;

  uart_tx u_tx (
    .clk(clk), .rst(rst), .tx_data(tx_data), .tx_valid(tx_valid),
    .tx_ready(tx_ready), .tx_line(tx_line), .tx_busy()
  );

  uart_rx u_rx (
    .clk(clk), .rst(rst), .rx_line(rx_line), .rx_byte(rxb),
    .rx_strobe(rxs), .rx_frame_err(rxfe), .rx_busy(rxbusy)
  );

  uart_fifo #(.DEPTH(FIFO_DEPTH), .W(8)) u_fifo (
    .clk(clk), .rst(rst),
    .wr_en(rxs), .wr_data(rxb),           // a framing error never writes
    .rd_en(rx_valid & rx_ready), .rd_data(rx_data),
    .full(ffull), .empty(fempty), .level(flevel)
  );

  assign rx_valid     = ~fempty;
  assign rx_frame_err = rxfe;

  // Overrun is the top level's: the receiver cannot stall a serial line, so
  // the arriving byte is dropped and the flag is sticky until cleared.
  always_ff @(posedge clk) begin
    if (rst)              rx_overrun <= 1'b0;
    else if (rx_ovr_clr)  rx_overrun <= 1'b0;
    else if (rxs & ffull) rx_overrun <= 1'b1;
  end
endmodule
