library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- https://en.wikipedia.org/wiki/Serial_Peripheral_Interface

entity spi_slave1 is
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
end entity spi_slave1;

architecture arch of spi_slave1 is
begin

    spi : process(sclk, ss_n)
        variable rx_buffer : std_logic_vector(WIDTH downto 0); -- Use variable for immediate updates
    begin
        if i_rst = '1' or ss_n = '1' then
            -- Reset on SS going inactive
            rx_buffer := (0 => '1', others => '0');
            o_dr <= '0';
            o_data <= (others => '0');
        elsif rising_edge(sclk) then  -- TODO: CPHA. 0 = sample on _from_ CLK idle; 1 = sample on _to_ CLK idle.
            o_dr <= '0';
            o_data <= (others => '0');

            if rx_buffer(WIDTH) = '1' then
                -- Start new word. The old one has already been captured.
                rx_buffer := (1 => '1', 0 => i_mosi, others => '0');
            else 
                rx_buffer := rx_buffer(WIDTH-1 downto 0) & i_mosi; -- Sample and shift

                -- Check if we have a full word
                if rx_buffer(WIDTH) = '1' then
                    -- Might this cause timing issues?
                    o_dr <= '1';  -- Set data ready flag
                    o_data <= rx_buffer(WIDTH-1 downto 0); -- Output the received data
                end if;
            end if;
        end if;
    end process spi;

    o_miso <= '0' when ss_n = '0' else 'Z'; -- High-Z when not selected 

end architecture arch;
