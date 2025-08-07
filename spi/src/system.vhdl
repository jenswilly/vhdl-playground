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
    signal clk_locked : std_logic;
    signal clk_48mhz : std_logic;

    -- SPI signals
    signal spi_dr : std_logic;
    signal spi_data : std_logic_vector(7 downto 0);
    
    -- FIFO signals
    signal fifo_empty : std_logic;   
 
    
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
        rst => '0',
        din => spi_data,
        wr_en => spi_dr,
        rd_en => '0',  -- No read enable for now
        empty => fifo_empty
    );
    
    o_leds(0) <= not fifo_empty;
    o_leds(1) <= clk_locked;
    
end architecture arch;