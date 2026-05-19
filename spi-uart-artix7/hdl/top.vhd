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
        debug_btn   : in  std_logic; -- Active high

        led0_r      : out std_logic;
        led0_g      : out std_logic;
        led1_r      : out std_logic;
        led1_g      : out std_logic;
        led2_r      : out std_logic;
        led2_g      : out std_logic;
        led3_r      : out std_logic;
        led3_g      : out std_logic;
        led_clk_ok  : out std_logic; -- Clock lock status LED (on if clock is stable)
        led_reset   : out std_logic; -- Reset pin status LED (on if reset is active)

        uart_txd    : out std_logic;

        gpio_ja1    : in  std_logic;    -- SPI clock input
        gpio_ja2    : in  std_logic;    -- SPI MOSI   
        gpio_ja3    : in  std_logic     -- SPI nCS
    );
end entity top;

architecture rtl of top is
    signal clk_buf          : std_logic; -- Buffered clock input -> MMCM
    signal clk_mmcm_out     : std_logic; -- Output of the MMCM before buffering
    signal clk_100mhz_int   : std_logic; -- Buffered and stable 100 MHz clock for the core logic
    signal clkfb            : std_logic; -- Clock feedback for MMCM
    signal clk_locked       : std_logic;
    signal reset_int        : std_logic; -- Active high reset for everything except the clock generator
    signal reset            : std_logic; -- Active high reset from pin -> MMCM reset input
    signal leds             : std_logic_vector(7 downto 0);
    signal btn              : std_logic; -- Debounced debug button
    signal spi_sclk : std_logic;
    signal spi_ss_n : std_logic;
    signal spi_mosi : std_logic;

    component debounce_switch is
        generic (
            N       : integer := 3; -- length of shift register
            RATE    : integer := 125000 -- clock division factor
        );
        port (
            i_clk       : in std_logic;
            i_rst       : in std_logic;
            i_raw       : in std_logic;
            o_debounced : out std_logic
        );
    end component debounce_switch;
begin
    -- Map input reset pin to internal reset signal
    arty_resetgen: if BOARD_TYPE = "arty" generate
        reset <= not reset_pin; -- Arty A7 has an active low reset button
    end generate;

    cmod_resetgen: if BOARD_TYPE = "cmod" generate
        reset <= reset_pin; -- Cmod A7 has an active high reset button
    end generate;

    debounce_inst : debounce_switch
        generic map (
            N => 3,
            RATE => 100000 -- Assuming a 100 MHz clock, this gives a debounce time of ~1 ms
        )
        port map (
            i_clk => clk_100mhz_int,
            i_rst => reset_int,
            i_raw => debug_btn,
            o_debounced => btn
        );
        
    spi_sclk <= gpio_ja1;
    spi_mosi <= gpio_ja2;
    spi_ss_n <= gpio_ja3;
    
    led0_r <= leds(0);
    led0_g <= leds(1);
    led1_r <= leds(2);
    led1_g <= leds(3);
    led2_r <= leds(4);
    led2_g <= leds(5);
    led3_r <= leds(6);
    led3_g <= leds(7);

    led_clk_ok <= clk_locked;   -- Clock lock status
    led_reset <= reset;        -- Reset pin status
    
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
            rst => '0',                -- MMCM always active
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
            rst => '0',                -- MMCM always active
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
            i_btn => btn,
            o_leds => leds,
            uart_txd => uart_txd,
            spi_sclk => spi_sclk,
            spi_ss_n => spi_ss_n,
            spi_mosi => spi_mosi
        );
end architecture rtl;
