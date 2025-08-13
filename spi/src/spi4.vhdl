library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- https://en.wikipedia.org/wiki/Serial_Peripheral_Interface
-- TODO: CPOL/CPHA

entity spi_slave4 is
    generic (
        WIDTH : positive := 8
    );
    port (
        sclk : in std_logic;
        ss_n : in std_logic;
        i_mosi : in std_logic;
        o_miso : out std_logic; 

        i_rst : in std_logic;   -- Active high reset. All SPI activity is ignored when set.
        o_dr : out std_logic;   -- Data ready: one full width of data has been received
        o_data : out std_logic_vector(WIDTH-1 downto 0)
    );        
end entity spi_slave4;

architecture arch of spi_slave4 is
    signal rx_buffer : std_logic_vector(WIDTH downto 0);
begin

    spi : process(sclk, ss_n)
    begin
        if i_rst = '1' or ss_n = '1' then
            rx_buffer <= (0 => '1', others => '0');
            o_dr <= '0';
        elsif rising_edge(sclk) then
            -- Default: shift in new bit, o_dr low, o_data don't care (keep)
            o_dr <= '0';
            rx_buffer <= rx_buffer(WIDTH-1 downto 0) & i_mosi;

            if rx_buffer(WIDTH) = '1' then
                -- Starting new word. Data was captured last iteration
                rx_buffer <= (1 => '1', 0 => i_mosi, others => '0');
            elsif rx_buffer(WIDTH - 1) = '1' then
                -- About to shift in last bit: set o_dr and o_data
                o_dr <= '1';
                o_data <= rx_buffer(WIDTH-2 downto 0) & i_mosi;
            end if;
        end if;
    end process spi;

    o_miso <= '0' when ss_n = '0' else 'Z'; 

end architecture arch;
