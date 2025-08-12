library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- This version uses a bit counter and sets o_dr and o_data directly
-- when a full word is received.

entity spi_slave3 is
    generic (
        WIDTH : positive := 8
    );
    port (
        sclk : in std_logic;
        ss_n : in std_logic;
        i_mosi : in std_logic;
        o_miso : out std_logic; 

        i_rst : in std_logic;
        o_dr : out std_logic;
        o_data : out std_logic_vector(WIDTH-1 downto 0)
    );        
end entity spi_slave3;

architecture arch of spi_slave3 is
    signal bit_counter : integer range 0 to WIDTH-1;
    signal shift_reg : std_logic_vector(WIDTH-1 downto 0);
begin

    o_miso <= '0' when ss_n = '0' else 'Z';

    spi_process : process(sclk, ss_n, i_rst)
    begin
        if i_rst = '1' or ss_n = '1' then
            bit_counter <= 0;
            shift_reg <= (others => '0');
            o_dr <= '0';
            o_data <= (others => '0');
            
        elsif rising_edge(sclk) then
            o_dr <= '0';  -- Default
            shift_reg <= shift_reg(WIDTH-2 downto 0) & i_mosi;
            
            if bit_counter = WIDTH-1 then
                bit_counter <= 0;
                o_dr <= '1';  -- Direct assignment
                o_data <= shift_reg(WIDTH-2 downto 0) & i_mosi;
            else
                bit_counter <= bit_counter + 1;
            end if;
        end if;
    end process;

end architecture;