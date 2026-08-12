# Compile order matters: the package must precede every module that imports it.
rtl/uart_pkg.sv
rtl/uart_tick_gen.sv
rtl/uart_tx.sv
rtl/uart_rx.sv
rtl/uart_fifo.sv
rtl/uart_lite.sv
