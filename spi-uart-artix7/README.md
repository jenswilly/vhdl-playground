# SPI -> UART for Arty A7

This project forwards data received over SPI to UART.

Both connections are uni-directional: SPI is slave-only and UART is TX only.

For following components are used:

* `reset`: own reset synchronizer
* `spi_axis`: own AXI Stream SPI slave
* `MMCME2`: Xilinx clock wizard
* `IBUFG` and `BUFG`: Xilinx clock buffers
* `uart_tx`: UART TX from a [Github project](https://github.com/ibndias/arty-a7-serial-verilog) (based on <https://ben-marshall.github.io/uart/>)
* `axis_fifo`: AXI Stream FIFO from [Alex Forencich's verilog-ethernet](https://github.com/alexforencich/verilog-ethernet) - added as a submodule
