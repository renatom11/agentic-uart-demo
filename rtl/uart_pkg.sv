// uart_pkg — the constants of SPEC-uart_lite §2, in one place.
// Every module reads its timing from here; no module declares a divisor locally.
package uart_pkg;
  parameter int CLK_HZ     = 50_000_000;
  parameter int BAUD       = 115_200;
  // 50e6/115200 = 434.0278 -> 434, giving 115207.373 baud, +0.0064 %
  parameter int DIV_TX     = 434;
  // 50e6/(115200*16) = 27.1267 -> 27; receive bit period = 27*16 = 432 cycles,
  // giving 115740.74 baud, +0.4694 %
  parameter int DIV_OS     = 27;
  parameter int OS         = 16;
  parameter int FIFO_DEPTH = 16;
endpackage
