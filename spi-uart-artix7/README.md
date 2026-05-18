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
* `debounce_switch`: Local copy of Forencich's switch debouncer. Changed input/output names to avoid conflicts with reserved names and changed to fixed single-width only.

### Bus Pirate Commands

SPI, 1 MHz, clock idle low, clock edge active-to-idle, sample at middle, CS low, normal output:

`m -> 5 -> 4 -> 1* -> 2* -> 1* -> 2* -> 2` (Items with `*` are default choices.)

```
[0x6a 0x65 0x6e 0x73 0x6a 0x65 0x6e 0x73 0x6a 0x65 0x6e 0x73 0x6a 0x65 0x6e 0x73 0x6a 0x65 0x6e 0x73 0x6a 0x65 0x6e 0x73 0x6a 0x65 0x6e 0x73]
```
