library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- https://en.wikipedia.org/wiki/Serial_Peripheral_Interface
-- TODO: CPOL/CPHA
-- Shifts on all clock cycles. Not keeping track of how much has been received.
-- Data ready is externally checked as rising edge of ss_n

entity spi_slave5 is
    generic (
        WIDTH : positive := 8
    );
    port (
        sclk : in std_logic;
        ss_n : in std_logic;
        i_mosi : in std_logic;
        o_miso : out std_logic; 

        i_rst : in std_logic;   -- Active high reset. All SPI activity is ignored when set.
        o_data : out std_logic_vector(WIDTH-1 downto 0)
    );        
end entity spi_slave5;

architecture arch of spi_slave5 is
begin
    spi : process(sclk, ss_n)
    begin
        if i_rst = '1' or ss_n = '1' then
            o_data <= (others => '0');
        elsif rising_edge(sclk) then
            o_data <= o_data(WIDTH-1 downto 0) & i_mosi;
        end if;
    end process spi;

    o_miso <= '0' when ss_n = '0' else 'Z'; 

end architecture arch;
