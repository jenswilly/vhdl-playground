library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

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

        uart_txd    : out std_logic;

        gpio_ja1    : in  std_logic;       -- PMOD connector for SPI
        gpio_ja2    : in  std_logic;
        gpio_ja3    : in  std_logic
    );
end entity top;

architecture rtl of top is
    signal clk_100mhz_buf   : std_logic; -- Buffered clock input -> MMCM
    signal clk_mmcm_out     : std_logic; -- Output of the MMCM before buffering
    signal clk_100mhz_int   : std_logic; -- Buffered and stable 100 MHz clock for the core logic
    signal clkfb            : std_logic; -- Clock feedback for MMCM
    signal clk_locked       : std_logic;
    signal reset            : std_logic; -- Active high reset for everything except the clock generator
    signal clk_spi_int      : std_logic; -- Buffered SPI clock domain
    signal n_reset_n        : std_logic;
    signal leds             : std_logic_vector(7 downto 0);

    signal spi_sclk : std_logic;
    signal spi_ss_n : std_logic;
    signal spi_mosi : std_logic;

begin
    n_reset_n <= not reset_n;   -- Invert to active high reset
    spi_ss_n <= gpio_ja3;
    spi_mosi <= gpio_ja2;
    spi_sclk <= gpio_ja1;
    led0_r <= leds(0);
    led0_g <= leds(1);
    led1_r <= leds(2);
    led1_g <= leds(3);
    led2_r <= leds(4);
    led2_g <= leds(5);
    led3_r <= leds(6);
    led3_g <= leds(7);

    led0_b <= clk_locked; -- Use the blue LED to indicate clock lock status
    led1_b <= n_reset_n;  -- Use the blue LED to indicate reset status
    led2_b <= '0';
    led3_b <= '0';
    
    -- Input clock buffer SPI clock
    clk_ibufg_spi_inst : IBUFG
    port map (
        O => clk_spi_int,
        I => spi_sclk
    );

    -- Input clock buffer for the 100 MHz system clock
    clk_ibufg_inst : IBUFG
    port map (
        O => clk_100mhz_buf,
        I => clk
    );
    
    -- MMCM instance to generate a stable 100 MHz clock from 100 MHz input clock
    mmcme2_inst : MMCME2_BASE
    generic map (
        clkfbout_mult_f => 8.0,     -- 100 MHz * 8 = 800 MHz
        clkin1_period => 10.0,      -- 100 MHz = 10 ns period
        clkout0_divide_f => 8.0     -- 800 MHz / 8 = 100 MHz
    )
    port map (
        clkin1 => clk_100mhz_buf,  -- Input: 100 MHz
        clkout0 => clk_mmcm_out,   -- Output: ~100 MHz
        clkfbout => clkfb,
        clkfbin => clkfb,
        pwrdwn => '0',             -- Always powered on
        rst => n_reset_n,          -- Active high reset for the MMCM
        locked => clk_locked       -- Output: '1' when clock is locked
    );

    clk_bufg_inst : BUFG
    port map (
        O => clk_100mhz_int,
        I => clk_mmcm_out
    );

    -- Global reset handler synchronized to the 100 MHz clock
    reset_inst : entity work.reset(arch)
    port map (
        i_clk => clk_100mhz_int,
        i_clk_locked => clk_locked,
        i_reset => n_reset_n, -- Invert active-low reset input to active-high
        o_reset => reset        -- Use this signal for everything except the clock generator
    );
    
    -- Core instance
    core_inst : entity work.core(rtl)
        port map (
            clk => clk_100mhz_int,
            rst => reset,
            o_leds => leds,
            uart_txd => uart_txd,
            spi_sclk => clk_spi_int,
            spi_ss_n => spi_ss_n,
            spi_mosi => spi_mosi
        );
end architecture rtl;
