library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity led is
    port (
        led : out std_logic_vector(0 to 1);
        led0_b : out std_logic;
        led0_g : out std_logic;
        led0_r : out std_logic;
        btn : in std_logic_vector(0 to 1)
    );
end entity led;

architecture arch of led is
begin
    led(0) <= btn(0);
    led(1) <= btn(1);
    led0_r <= not btn(0);
    led0_g <= not btn(1);
    led0_b <= btn(0) or btn(1);
end architecture arch;