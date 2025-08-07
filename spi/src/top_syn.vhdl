library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port (
        sysclk : in std_logic;
        led : out std_logic_vector(0 to 1);
        ja : in std_logic_vector(0 to 2)  -- PMOD connector
    );
end entity top;

architecture rtl of top is
    component system is
    port(
        i_clk : in std_logic;
        o_led : out std_logic;
        
        -- SPI input
        i_spi_clk : in std_logic;
        i_spi_mosi : in std_logic;
        i_spi_ss_n : in std_logic;
        o_spi_miso : out std_logic
    );        
    end component system;

begin
    system_inst: system
    port map (
        i_clk => sysclk,
        o_led => led(0),
        i_spi_clk => ja(0),
        i_spi_mosi => ja(1),
        i_spi_ss_n => ja(2)
        -- o_spi_mosi not connected
    ); 
end architecture rtl;
        