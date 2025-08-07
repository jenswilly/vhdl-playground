library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port (
        sysclk : in std_logic;
        led : out std_logic_vector(0 to 1);
        ja : in std_logic_vector(0 to 2);  -- PMOD connector
        led0_r : out std_logic;
        led0_g : out std_logic;
        led0_b : out std_logic
    );
end entity top;

architecture rtl of top is
    component system is
    port(
        i_clk : in std_logic;
        o_leds : out std_logic_vector(0 to 1);
        
        -- SPI input
        i_spi_clk : in std_logic;
        i_spi_mosi : in std_logic;
        i_spi_ss_n : in std_logic;
        o_spi_miso : out std_logic
    );        
    end component system;

begin
    -- RGB LED off
    led0_r <= '1';
    led0_g <= '1';
    led0_b <= '1';
    
    system_inst: system
    port map (
        i_clk => sysclk,
        o_leds => led,
        i_spi_clk => ja(0),
        i_spi_mosi => ja(1),
        i_spi_ss_n => ja(2)
        -- o_spi_mosi not connected
    ); 
end architecture rtl;
        