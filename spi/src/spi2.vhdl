library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This version will keep shifting bits on every clock cycle.
-- When SS goes high (inactive), o_busy will be set to '0' and 
-- the rising edge of o_busy can be used to latch the received data.
-- If requires that SS must go high after every N bits.
entity spi_slave2 is
generic(
    N                 : integer := 2;       -- number of bit to serialize
);
port (
    o_busy            : out std_logic;  -- receiving data if '1'
    o_data_parallel   : out std_logic_vector(N-1 downto 0);  -- received data
    i_sclk            : in  std_logic;
    i_ss              : in  std_logic;
    i_mosi            : in  std_logic;
    o_miso            : out std_logic
);
end spi_slave2;

architecture rtl of spi_slave2 is
    signal r_shift_ena  : std_logic;
    signal r_rx_data    : std_logic_vector(N-1 downto 0);  -- received data
begin

    o_data_parallel  <= r_rx_data;
    o_busy           <= r_shift_ena;

    p_spi_slave_input : process(i_sclk)
    begin
        if rising_edge(i_sclk) then
            if(i_ss='0') then
                r_rx_data <= r_rx_data(N-2 downto 0)&i_mosi;
            end if;
        end if;
    end process p_spi_slave_input;

    p_spi_slave_en : process(i_sclk,i_ss)
    begin
        if(i_ss='1') then
            r_shift_ena            <= '0';
        elsif(i_sclk'event and i_sclk = '1'') then -- CPOL='0' => falling edge; CPOL='1' => risinge edge
            r_shift_ena            <= '1';
        end if;
    end process p_spi_slave_en;

end rtl;