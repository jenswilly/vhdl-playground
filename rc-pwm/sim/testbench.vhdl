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
    component pwm 
        port(
            a, b, c : in std_logic;
            j, k : out std_logic);
    end component;
    
    signal clk_10mhz : std_logic := '0';
    signal clk_finished : std_logic;
    constant HALF_PERIOD : time := 50 ns; -- Half period for 10 MHz clock

begin
    clk : process 
    begin
        clk_10mhz <= not clk_10mhz after HALF_PERIOD when clk_finished /= '1' else '0';
    end process;

    UUT: comb port map(
        a => abc(2),
        b => abc(1),
        c => abc(0),
        j => j,
        k => k);
        
    process
    begin
        clk_finished <= '0';
        -- Do stuff with clk
        -- ...
        clk_finished <= '1';
    end process;

end behavioral;
