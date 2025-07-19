----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/19/2025 11:40:53 AM
-- Design Name: 
-- Module Name: comb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity comb is
  Port (
  a : in std_logic;
  b : in std_logic;
  c : in std_logic;
  j : out std_logic;
  k : out std_logic );
end comb;

architecture Behavioral of comb is
    signal abc : std_logic_vector(2 downto 0);
begin
    abc <= a & b & c;
    j <= '1' when abc = "001" or abc = "011" else '0';
    
    process(abc)
    begin
        case(abc) is
        when "000" | "001" | "011" | "100" | "101" =>
            k <= '1';
            
        when others =>
            k <= '0';
        
        end case;
    end process;


end Behavioral;
