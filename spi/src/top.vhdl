library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

-- Top-level disign for RC PWM test
-- Be sure to define CLK (100 MHz) and LED[0:3] in constraints file

entity top is
    port(
        sysclk : in std_logic;
        led : out std_logic_vector(0 to 1)
    );        
end entity top;

architecture rtl of top is
    -- Global reset and clock
    signal global_reset : std_logic; -- Reset, active high: '0' means ready to go
    signal reset_sync : std_logic_vector(2 downto 0) := "000";
    signal clk_locked : std_logic;
    signal clk_48mhz : std_logic;
    signal clkfb : STD_LOGIC;

    -- SPI signals
    -- signal i_spi_clk : std_logic;   -- Connect to external pin
    -- signal i_spi_mosi : std_logic;  -- Connect to external pin
    -- signal i_spi_cc_n : std_logic;  -- Connect to external pin
    -- signal o_spi_miso : std_logic;  -- Connect to external pin
    signal spi_dr : std_logic;
    signal spi_data : std_logic_vector(7 downto 0);
    
    -- FIFO signals
    signal fifo_rst : std_logic := '0';
    signal fifo_rd_en : std_logic := '0';
    signal fifo_dout : std_logic_vector(7 downto 0);
    signal fifo_full : std_logic;
    signal fifo_empty : std_logic;
    
    component fifo_0 is
    port (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC
        );
    end component  fifo_0;
    
begin
    -- Clock Manager (MMCM) for generating 48Hz from 12 MHz system clock
    MMCME2_inst : MMCME2_BASE
    generic map (
        BANDWIDTH => "OPTIMIZED",
        CLKFBOUT_MULT_F => 64.0,    -- 12 * 64 = 768 MH
        CLKFBOUT_PHASE => 0.0,
        CLKIN1_PERIOD => 83.333,    -- 12 MHz = 83.333 ns period
        CLKOUT0_DIVIDE_F => 16.0,   -- 768 MHz / 16 = 48 MHz
        CLKOUT0_DUTY_CYCLE => 0.5,
        CLKOUT0_PHASE => 0.0,
        DIVCLK_DIVIDE => 1,
        REF_JITTER1 => 0.0,
        STARTUP_WAIT => FALSE
    )
    port map (
        CLKOUT0 => clk_48mhz,   -- Output: 48 MHz
        CLKFBOUT => clkfb,
        CLKFBIN => clkfb,
        CLKIN1 => sysclk,       -- Input: 12 MHz
        PWRDWN => '0',
        RST => '0',             -- No external reset - let MMCM self-start
        LOCKED => clk_locked    -- Output: '1' when clock is locked
    );

    -- Automatic reset generation - activates when system is programmed and ready
    -- Reset sequence:
    -- 1. FPGA configuration completes (GSR released automatically)
    -- 2. Clock manager locks to stable frequency
    -- 3. 3-stage synchronizer releases reset cleanly
    -- 4. System starts normal operation
    -- Note: The `reset_sync` signal could also be a variable in the reset process, 
    --    but it is recommended to use signal for visibility in simulation, synthesis clarity (flip-flop) 
    --    and it is (apparently) standard practice for a reset sync to be implemented as a signal.
    reset : process(clk_48mhz, clk_locked)
    begin
        if (clk_locked = '0') then
            -- Hold in reset until clock manager is locked and stable
            reset_sync <= "000";
            global_reset <= '1';
        elsif rising_edge(clk_48mhz) then
            -- Release reset synchronously after clock is stable
            reset_sync <= reset_sync(1 downto 0) & '1';
            global_reset <= not reset_sync(2);  -- Released after 3 clocks
        end if;
    end process reset;

    spi1 : entity work.spi_slave(arch)
    generic map ( WIDTH => 8 )
    port map (
        sclk => i_spi_clk,
        i_mosi => i_spi_mosi,
        o_miso => o_spi_miso,
        ss_n => i_spi_ss_n,
        o_dr => spi_dr,
        o_data => spi_data
    );
    
    fifo : fifo_0 
    port map (
        clk => sysclk,
        rst => fifo_rst,
        din => spi_data,
        wr_en => spi_dr,
        rd_en => fifo_rd_en,
        dout => fifo_dout,
        full => fifo_full,
        empty => fifo_empty
    );
        
    -- LED assignments
    led(0) <= spi_dr;
    led(1) <= fifo_empty;
    
end architecture rtl;