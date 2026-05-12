library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity core is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;

        led0_r      : out std_logic;
        led0_g      : out std_logic;
        led0_b      : out std_logic;
        led1_r      : out std_logic;
        led1_g      : out std_logic;
        led1_b      : out std_logic;
        led2_r      : out std_logic;
        led2_g      : out std_logic;
        led2_b      : out std_logic;
        led3_r      : out std_logic;
        led3_g      : out std_logic;
        led3_b      : out std_logic;
        led4        : out std_logic;
        led5        : out std_logic;
        led6        : out std_logic;
        led7        : out std_logic;

        uart_txd    : out std_logic;

        spi_sclk    : in  std_logic;
        spi_ss_n    : in  std_logic;
        spi_mosi    : in  std_logic
    );
end entity core;

architecture rtl of core is
    -- AXI Stream signals between the SPI slave and the FIFO
    signal spi_axis_tvalid : std_logic;
    signal spi_axis_tdata : std_logic_vector(7 downto 0);
    signal fifo_axis_tready : std_logic;
    signal fifo_axis_tvalid : std_logic;
    signal fifo_axis_tdata : std_logic_vector(7 downto 0);
    
begin
    -- SPI slave instance
    -- TODO

    -- FIFO instance
    -- TODO

    -- UART TX instance
    -- TODO
    

end architecture rtl;
