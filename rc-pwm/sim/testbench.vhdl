library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity testbench is
end testbench;

architecture behavioral of testbench is
    signal clk_10mhz : std_logic := '0';
    signal clk_finished : std_logic;
    
    signal duty_cycle : integer := 128;
    signal pwm_out : std_logic;
    constant HALF_PERIOD : time := 50 ns; -- Half period for 10 MHz clock

begin
    clk_10mhz <= not clk_10mhz after HALF_PERIOD when clk_finished /= '1' else '0';

    UUT: entity work.pwm(behavioral) 
    generic map (
        RESOLUTION => 10
    )
    port map (
        i_clk => clk_10mhz,
        i_enable => '1',
        i_duty_cycle => duty_cycle,
        o_pwm => pwm_out
    );

        
    process
    begin
    	duty_cycle <= 2;
        clk_finished <= '0';

        wait for 100 ms;
        
        duty_cycle <= 8;
        wait for 100 ms;

        -- Done
        clk_finished <= '1';
        wait;
    end process;
end behavioral;
