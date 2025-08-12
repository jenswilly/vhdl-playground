library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity testbench is
end entity testbench;

architecture behavioral of testbench is
    signal sclk : std_logic := '0';
    signal o_mosi : std_logic := '0';
    signal i_miso : std_logic;
    signal ss_n : std_logic := '1';
    signal leds : std_logic_vector(0 to 1);
    signal ready : std_logic := '0';
    signal servos : std_logic_vector(0 to 1);

    constant data_out : std_logic_vector(15 downto 0) := "0110010010000000";
    
    -- 12 MHz system clock
    signal clk_12mhz : std_logic := '0';
    constant HALF_PERIOD : time := 41.6665 ns; -- Half period for 12 MHz clock
begin
    clk_12mhz <= not clk_12mhz after HALF_PERIOD;

    UUT: entity work.system(arch) 
    port map (
        i_clk => clk_12mhz,
        o_leds => leds,
        i_rst => '0',
        o_ready => ready,
        o_servo => servos,
        
        i_spi_clk => sclk,
        i_spi_mosi => o_mosi,
        i_spi_ss_n => ss_n,
        o_spi_miso => i_miso
    ); 
    
    process
    begin
        wait until ready = '1'; 
        
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
