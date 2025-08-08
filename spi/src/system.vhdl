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
    i_rst : in std_logic;       -- Global reset. Active high.
    o_ready : out std_logic;    -- Clock and reset handler ready.
    
    -- SPI input
    i_spi_clk : in std_logic;
    i_spi_mosi : in std_logic;
    i_spi_ss_n : in std_logic;
    o_spi_miso : out std_logic
);        
end entity system;

architecture arch of system is
    signal clk_locked : std_logic;
    signal clk_48mhz : std_logic;
    signal reset : std_logic;

    -- SPI signals
    signal spi_dr : std_logic;
    signal spi_data : std_logic_vector(7 downto 0);
    
    -- FIFO signals
    signal fifo_empty : std_logic;   
 
    -- Edge detection for spi_dr because we only want to write to FIFO once per spi_dr pulse
    signal spi_dr_prev : std_logic := '0';
    signal spi_dr_pulse : std_logic := '0';

    component fifo_0 is
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        din    : in  std_logic_vector(7 downto 0);
        wr_en  : in  std_logic;
        rd_en  : in  std_logic;
        dout   : out std_logic_vector(7 downto 0);
        full   : out std_logic;
        empty  : out std_logic
        );
    end component  fifo_0;
            
begin
    -- Make sure we only have spi_dr_pulse high for one 48 MHz clock cycle
    -- when spi_dr goes high (which might happen unsynchronized to the 48 MHz clock)
    -- so we don't write spi_data to the FIFO more than once.
    edge_detect: process(clk_48mhz)
    begin
        if rising_edge(clk_48mhz) then
            spi_dr_prev <= spi_dr;
            spi_dr_pulse <= spi_dr and not spi_dr_prev;
        end if;
    end process edge_detect;

    -- 48 MHz clock generation from the 12 MHz system clock
    -- (Not strictly necessary in our case...)
    clock_48mhz_inst : entity work.clock(arch)
    port map (
        i_clk => i_clk,
        i_rst => i_rst,
        o_48mhz_clk => clk_48mhz,
        o_clk_locked => clk_locked
    );

    -- Global reset handler synchronized to the 48 MHz clock
    reset_inst : entity work.reset(arch)
    port map (
        i_clk => clk_48mhz,
        i_clk_locked => clk_locked,
        i_reset => i_rst,
        o_reset => reset
    );
    
    -- SPI slave in only synchronized to the SPI clock
    spi_inst : entity work.spi_slave(arch)
    generic map ( WIDTH => 8 )
    port map (
        sclk => i_spi_clk,
        i_mosi => i_spi_mosi,
        o_miso => o_spi_miso,
        ss_n => i_spi_ss_n,
        i_rst => i_rst,
        o_dr => spi_dr,
        o_data => spi_data
    );

    -- FIFO instance
    fifo_inst : fifo_0
    port map (
        clk => clk_48mhz,
        rst => i_rst,
        din => spi_data,
        wr_en => spi_dr_pulse,
        rd_en => '0',  -- No read enable for now
        empty => fifo_empty
    );

    o_ready <= not reset;
    o_leds(0) <= not fifo_empty;
    o_leds(1) <= clk_locked;
    
end architecture arch;