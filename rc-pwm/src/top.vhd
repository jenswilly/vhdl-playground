library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Top-level disign for RC PWM test
-- Be sure to define CLK (100 MHz) and LED[0:3] in constraints file

entity top is
    port(
        CLK : in std_logic;
        led : out std_logic_vector(0 to 3)
    );        
end entity top;

architecture arch of top is
begin
    pwm1: entity work.pwm(arch)
    generic map(
        RESOLUTION => 100,
        MIN_PULSE_WIDTH_US => 900,
        MAX_PULSE_WIDTH_US => 2100
    )
    port map (
        i_clk => clk,
        i_enable => '1',
        i_position => 100,
        o_pwm => led(0)
    );
    
    pwm2: entity work.pwm(arch)
    generic map(
        RESOLUTION => 100,
        MIN_PULSE_WIDTH_US => 900,
        MAX_PULSE_WIDTH_US => 2100
    )
    port map (
        i_clk => clk,
        i_enable => '1',
        i_position => 0,
        o_pwm => led(2)
    );

end architecture arch;
