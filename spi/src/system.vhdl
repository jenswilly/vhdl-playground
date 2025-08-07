library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- For MMCME2_BASE
Library UNISIM;
use UNISIM.vcomponents.all;

-- Top-level design for SPI-to-FIFO interface on Cmod-A7
-- This design is the "system" entity that integrates the SPI slave, FIFO, and LED control.
--
-- Required inputs are:
-- - `i_clk`: 12 MHz system clock (which will be scaled to 48 MHz for FIFO and reset logic)
-- - `o_led`: active high LED output indicating "FIFO not empty"
-- - `i_spi_clk`: SPI clock input
-- - `i_spi_mosi`: SPI input
-- - `i_spi_ss_n`: SPI CS/SS (active low) input
-- - `o_spi_miso`: SPI output (nothing is output from this system)
--

entity system is
port(
    i_clk : in std_logic;
    o_leds : out std_logic_vector(0 to 1);
    
    -- SPI input
    i_spi_clk : in std_logic;
    i_spi_mosi : in std_logic;
    i_spi_ss_n : in std_logic;
    o_spi_miso : out std_logic
);        
end entity system;

architecture arch of system is
    -- Global reset and clock
    signal global_reset : std_logic; -- Reset, active high: '0' means ready to go
    signal reset_sync : std_logic_vector(2 downto 0) := "000";
    signal clk_locked : std_logic;
    signal clk_48mhz : std_logic;
    signal clkfb : STD_LOGIC;

    -- SPI signals
    signal spi_dr : std_logic;
    signal spi_data : std_logic_vector(7 downto 0);
    
    -- FIFO signals
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
    
    component clk_wiz_0
    port (
        clk_out1          : out    std_logic;
        locked            : out    std_logic;
        clk_in1           : in     std_logic 
     );
    end component;
        
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
        CLKIN1 => i_clk,       -- Input: 12 MHz
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
    -- Note 2: Currently using the 12 MHz input clock and not the scaled 48 MHz - until that is working and we get a locked signal...
    reset : process(i_clk)
    begin
--        if (clk_locked = '0') then
--            -- Hold in reset until clock manager is locked and stable
--            reset_sync <= "000";
--            global_reset <= '1';
--        elsif rising_edge(clk_48mhz) then
        if(rising_edge(i_clk)) then
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
        clk => i_clk,   -- Use the 48 MHz clock for FIFO operations
        rst => global_reset,
        din => spi_data,
        wr_en => spi_dr,
        rd_en => '0',  -- No read enable for now
        empty => fifo_empty
    );
    
    o_leds(0) <= not fifo_empty;
    o_leds(1) <= clk_locked;
    
end architecture arch;