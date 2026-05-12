library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    port (
        clk         : in  std_logic;
        reset_n     : in  std_logic;

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
end entity top;

architecture rtl of top is
    signal clk_100mhz_int   : std_logic;
    signal clk_locked       : std_logic;
    signal reset            : std_logic; -- Active high reset for everything except the clock generator
    signal clk_spi_int      : std_logic; -- SPI clock domain

begin
    -- Input clock buffer for the 100 MHz system clock
    clk_ibufg_inst : IBUFG
    port map (
        O => clk_100mhz_int,
        I => clk
    );

    -- Input clock buffer for the SPI clock
    clk_ibufg_spi_inst : IBUFG
    port map (
        O => clk_spi_int,
        I => spi_sclk
    );

    -- Global reset handler synchronized to the 100 MHz clock
    reset_inst : entity work.reset(arch)
    port map (
        i_clk => clk_100mhz_int,
        i_clk_locked => clk_locked,
        i_reset => not reset_n, -- Invert active-low reset input to active-high
        o_reset => reset        -- Use this signal for everything except the clock generator
    );
        
    -- Core instance
    core_inst : entity work.core(rtl)
        port map (
            clk => clk_100mhz_int,
            rst => reset,

            led0_r => led0_r,
            led0_g => led0_g,
            led0_b => led0_b,
            led1_r => led1_r,
            led1_g => led1_g,
            led1_b => led1_b,
            led2_r => led2_r,
            led2_g => led2_g,
            led2_b => led2_b,
            led3_r => led3_r,
            led3_g => led3_g,
            led3_b => led3_b,
            led4 => led4,
            led5 => led5,
            led6 => led6,
            led7 => led7,

            uart_txd => uart_txd,

            spi_sclk => clk_spi_int,
            spi_ss_n => spi_ss_n,
            spi_mosi => spi_mosi
        );
end architecture rtl;
