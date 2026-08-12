// uart_tx — 8N1 transmitter (SPEC §5.2). Ten bit intervals of DIV_TX cycles.
module uart_tx
  import uart_pkg::*;
(
  input  logic       clk,
  input  logic       rst,
  input  logic [7:0] tx_data,
  input  logic       tx_valid,
  output logic       tx_ready,
  output logic       tx_line,
  output logic       tx_busy
);
  logic [9:0] sh;      // {stop, d7..d0, start}
  logic [3:0] bitcnt;  // 0 = start bit is on the wire, 9 = stop bit
  logic       running;
  logic       tick;
  logic       load;

  assign load     = tx_valid & tx_ready;
  assign tx_ready = ~running;
  assign tx_busy  = running;

  uart_tick_gen #(.N(DIV_TX)) u_tick (
    .clk(clk), .rst(rst), .restart(load), .tick(tick)
  );

  always_ff @(posedge clk) begin
    if (rst) begin
      sh      <= 10'h3FF;
      bitcnt  <= '0;
      running <= 1'b0;
      tx_line <= 1'b1;
    end else if (load) begin
      sh      <= {1'b1, tx_data, 1'b0};
      bitcnt  <= '0;
      running <= 1'b1;
      tx_line <= 1'b0;                 // start bit begins in the next cycle
    end else if (running && tick) begin
      if (bitcnt == 4'd9) begin
        running <= 1'b0;
        tx_line <= 1'b1;               // return to idle
      end else begin
        bitcnt  <= bitcnt + 4'd1;
        tx_line <= sh[bitcnt + 4'd1];  // d0..d7 then the stop bit
      end
    end
  end
endmodule
