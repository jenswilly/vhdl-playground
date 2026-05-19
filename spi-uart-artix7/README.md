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

### Delayed Drain to UART

If the FIFO should not drain to UART until SPI has been idle a while, apply this patch `git apply <file>`:

```
diff --git a/spi-uart-artix7/hdl/core.vhd b/spi-uart-artix7/hdl/core.vhd
index 3dc8b76..e252356 100644
--- a/spi-uart-artix7/hdl/core.vhd
+++ b/spi-uart-artix7/hdl/core.vhd
@@ -16,6 +16,8 @@ entity core is
 end entity core;
 
 architecture rtl of core is
+    constant SPI_IDLE_TIMEOUT_CYCLES : natural := 50_000_000; -- 0.5 s at 100 MHz
+
     -- Debug signals
     signal debug_active : std_logic;
     signal debug_burst_active : std_logic;
@@ -145,8 +147,30 @@ begin
     fifo_in_tvalid <= debug_tvalid or spi_axis_tvalid;
     fifo_in_tdata <= debug_tdata when debug_tvalid = '1' else spi_axis_tdata;
 
+    -- Delay FIFO draining until there has been no SPI data for a while.
+    spi_idle_timer : process (clk)
+    begin
+        if rising_edge(clk) then
+            if rst = '1' then
+                spi_idle_counter <= (others => '0');
+                drain_enable <= '0';
+            else
+                if spi_axis_tvalid = '1' then
+                    spi_idle_counter <= (others => '0');
+                    drain_enable <= '0';
+                elsif drain_enable = '0' then
+                    if spi_idle_counter = to_unsigned(SPI_IDLE_TIMEOUT_CYCLES - 1, spi_idle_counter'length) then
+                        drain_enable <= '1';
+                    else
+                        spi_idle_counter <= spi_idle_counter + 1;
+                    end if;
+                end if;
+            end if;
+        end if;
+    end process spi_idle_timer;
+
     -- Single-cycle start handshake: UART start and FIFO pop happen on the same edge.
-    uart_start_sig <= '1' when fifo_axis_tvalid = '1' and uart_tx_busy_sig = '0' else '0';
+    uart_start_sig <= '1' when fifo_axis_tvalid = '1' and uart_tx_busy_sig = '0' and drain_enable = '1' else '0';
     uart_tx_en_sig <= uart_start_sig;
 
     -- SPI input -> LEDs process
```

