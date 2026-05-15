library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

entity top is
    generic (
        BOARD_TYPE : string := "UNDEFINED" -- "arty" or "cmod" must be specified at project level
    );
    port (
        clk         : in  std_logic;
        reset_pin   : in  std_logic; -- Rest input pin. NB: can be either active high or low depending on board

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
    signal clk_buf          : std_logic; -- Buffered clock input -> MMCM
    signal clk_mmcm_out     : std_logic; -- Output of the MMCM before buffering
    signal clk_100mhz_int   : std_logic; -- Buffered and stable 100 MHz clock for the core logic
    signal clkfb            : std_logic; -- Clock feedback for MMCM
    signal clk_locked       : std_logic;
    signal reset_int        : std_logic; -- Active high reset for everything except the clock generator
    signal clk_spi_int      : std_logic; -- Buffered SPI clock domain
    signal reset            : std_logic; -- Active high reset from pin -> MMCM reset input
    signal leds             : std_logic_vector(7 downto 0);

    signal spi_sclk : std_logic;
    signal spi_ss_n : std_logic;
    signal spi_mosi : std_logic;

begin
    -- Map input reset pin to internal reset signal
    arty_resetgen: if BOARD_TYPE = "arty" generate
        reset <= not reset_pin; -- Arty A7 has an active low reset button
    end generate;

    cmod_resetgen: if BOARD_TYPE = "cmod" generate
        reset <= reset_pin; -- Cmod A7 has an active high reset button
    end generate;

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

    led0_b <= clk_locked;   -- Clock lock status
    led1_b <= reset;        -- Reset pin status
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
        O => clk_buf,
        I => clk
    );
    
    -- MMCM instance to generate a stable 100 MHz clock from 100 MHz input clock
    arty_clockgen: if BOARD_TYPE = "arty" generate
        -- Arty A7: 100 MHz input clock
        mmcme2_arty_inst : MMCME2_BASE
        generic map (
            clkfbout_mult_f => 8.0, -- VCO frequency = 100 MHz * 8 = 800 MHz
            clkin1_period => 10.0,  -- 100 MHz input clock period in ns
            clkout0_divide_f => 8.0 -- Output clock = 800 MHz / 8 = 100 MHz
        )
        port map (
            clkin1 => clk_buf, 
            clkout0 => clk_mmcm_out,   -- Output: ~100 MHz
            clkfbout => clkfb,
            clkfbin => clkfb,
            pwrdwn => '0',             -- Always powered on
            rst => reset,              -- Active high reset for the MMCM
            locked => clk_locked       -- Output: '1' when clock is locked
        );
    end generate;

    -- MMCM instance to generate a stable 100 MHz clock from 12 MHz input clock
    cmod_clockgen: if BOARD_TYPE = "cmod" generate
        -- Cmod A7: 12 MHz input clock
        mmcme2_cmod_inst : MMCME2_BASE
        generic map (
            clkfbout_mult_f => 50.0,    -- VCO frequency = 12 MHz * 50 = 600 MHz
            clkin1_period => 83.333,    -- 12 MHz input clock period in ns
            clkout0_divide_f => 6.0     -- Output clock = 600 MHz / 6 = 100 MHz
        )
        port map (
            clkin1 => clk_buf,
            clkout0 => clk_mmcm_out,   -- Output: ~100 MHz
            clkfbout => clkfb,
            clkfbin => clkfb,
            pwrdwn => '0',             -- Always powered on
            rst => reset,              -- Active high reset for the MMCM
            locked => clk_locked       -- Output: '1' when clock is locked
        );
    end generate;

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
        i_reset => reset,       -- Active high reset from pin
        o_reset => reset_int    -- Use this signal for everything except the clock generator
    );
    
    -- Core instance
    core_inst : entity work.core(rtl)
        port map (
            clk => clk_100mhz_int,
            rst => reset_int,
            o_leds => leds,
            uart_txd => uart_txd,
            spi_sclk => clk_spi_int,
            spi_ss_n => spi_ss_n,
            spi_mosi => spi_mosi
        );
end architecture rtl;
