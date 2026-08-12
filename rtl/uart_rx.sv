// uart_rx — 16x-oversampled 8N1 receiver (SPEC §5.3).
//
// rx_line is asynchronous and passes through two flip-flops before any logic
// reads it. A falling edge on the synchronised line, while idle, restarts the
// DIV_OS tick generator; that cycle is cycle 0 of the frame. Samples are then
// taken at oversample ticks 8, 24, ... 152 — clock cycles 216 + 432n.
module uart_rx
  import uart_pkg::*;
(
  input  logic       clk,
  input  logic       rst,
  input  logic       rx_line,
  output logic [7:0] rx_byte,
  output logic       rx_strobe,
  output logic       rx_frame_err,
  output logic       rx_busy
);
  // ---- two-flop synchroniser (s1, s2) plus one delay for edge detect -------
  logic s1, s2, s2_d;
  always_ff @(posedge clk) begin
    if (rst) begin s1 <= 1'b1; s2 <= 1'b1; s2_d <= 1'b1; end
    else     begin s1 <= rx_line; s2 <= s1; s2_d <= s2; end
  end
  wire fall = s2_d & ~s2;

  logic       running;
  logic       tick;
  logic [7:0] tcnt;      // oversample ticks since the restart
  logic       restart;
  logic [7:0] t_next;

  assign restart = fall & ~running;
  assign rx_busy = running;
  assign t_next  = tcnt + 8'd1;

  uart_tick_gen #(.N(DIV_OS)) u_os (
    .clk(clk), .rst(rst), .restart(restart), .tick(tick)
  );

  always_ff @(posedge clk) begin
    rx_strobe    <= 1'b0;              // both are one-cycle strobes
    rx_frame_err <= 1'b0;
    if (rst) begin
      running <= 1'b0;
      tcnt    <= '0;
      rx_byte <= '0;
    end else if (restart) begin
      running <= 1'b1;
      tcnt    <= '0;
    end else if (running && tick) begin
      tcnt <= t_next;
      if (t_next == 8'd8) begin
        // start-bit confirmation: a line that has gone high again is noise
        if (s2) running <= 1'b0;
      end else if (t_next >= 8'd24 && t_next <= 8'd136 && t_next[3:0] == 4'd8) begin
        rx_byte <= {s2, rx_byte[7:1]};        // LSB first
      end else if (t_next == 8'd152) begin
        running <= 1'b0;
        if (s2) rx_strobe <= 1'b1;            // stop bit high: byte is good
        else    rx_frame_err <= 1'b1;         // stop bit low: framing error
      end
    end
  end
endmodule
