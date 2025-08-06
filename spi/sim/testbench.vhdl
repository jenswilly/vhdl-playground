library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity testbench is
end entity testbench;

architecture behavioral of testbench is
    signal sclk : std_logic := '0';
    signal o_mosi : std_logic := '0';
    signal i_miso : std_logic;
    signal ss_n : std_logic := '1';
    
    signal dr : std_logic := '0';
    signal data_in : std_logic_vector(7 downto 0) := "00000000";
    
    constant data_out : std_logic_vector(15 downto 0) := "0101010111001100";
begin
    UUT: entity work.spi_slave(arch)
    generic map (WIDTH => 8)
    port map (
        sclk => sclk,
        i_mosi => o_mosi,
        o_miso => i_miso,
        ss_n => ss_n,
        o_dr => dr,
        o_data => data_in
    );
    
    process
    begin
        wait for 100 ns;
        
        -- Assert SS and shift out bit 0
        ss_n <= '0';
        o_mosi <= data_out(data_out'LEFT);
        wait for 100 ns;
        
        for i in data_out'LENGTH - 2 downto 0 loop
            -- CLK up
            sclk <= '1';
            wait for 100 ns;
            
            -- CLK down and shift out next
            sclk <= '0';
            o_mosi <= data_out(i);
            wait for 100 ns;
        end loop;
        
        -- Last clock cycle
        sclk <= '1';
        wait for 100 ns;
        
        -- Deassert SS and clock idle
        ss_n <= '1';
        sclk <= '0';
        wait for 100 ns;
        
        wait;
    end process;

end architecture behavioral;
