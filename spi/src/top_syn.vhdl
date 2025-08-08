library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port (
        sysclk : in std_logic;
        led : out std_logic_vector(0 to 1);
        ja : in std_logic_vector(0 to 2);  -- PMOD connector
        btn : in std_logic_vector(0 to 1);
        led0_r : out std_logic;
        led0_g : out std_logic;
        led0_b : out std_logic
    );
end entity top;

architecture rtl of top is
begin
    -- RGB LED off
    led0_r <= '1';
    led0_g <= '1';
    led0_b <= '1';
    
    system_inst: entity work.system(arch)
    port map (
        i_clk => sysclk,
        o_leds => led,
        i_rst => btn(0),
        o_ready => open,    -- Don't care
        i_spi_clk => ja(0),
        i_spi_mosi => ja(1),
        i_spi_ss_n => ja(2)
        -- o_spi_mosi not connected
    ); 
end architecture rtl;
        