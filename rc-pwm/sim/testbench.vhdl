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
--  Port ( );
end testbench;

architecture Behavioral of testbench is
    component pwm 
        port(
            a, b, c : in std_logic;
            j, k : out std_logic);
    end component;
    
    signal abc : std_logic_vector(2 downto 0);
    signal j, k : std_logic;

begin
    UUT: comb port map(
        a => abc(2),
        b => abc(1),
        c => abc(0),
        j => j,
        k => k);
        
    process
    begin
        abc <= "000";
        wait for 100 ns;
        
        abc <= "001";
        wait for 100 ns;
        
        abc <= "010";
        wait;
    end process;

end Behavioral;
