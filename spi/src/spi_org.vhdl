library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- https://en.wikipedia.org/wiki/Serial_Peripheral_Interface

entity spi_slave0 is
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
end entity spi_slave0;

architecture arch of spi_slave0 is
    signal rx_buffer : std_logic_vector(WIDTH downto 0);
begin

    spi : process(sclk, ss_n)
        variable tmp_buffer : std_logic_vector(WIDTH downto 0); -- Use temporary variable to have only one assignment to rx_buffer
    begin
        if i_rst = '1' or ss_n = '1' then
            -- Reset bit bufffer on SS going active
            tmp_buffer := (0 => '1', others => '0');
            o_dr <= '0';
        else
            if rising_edge(sclk) then  -- TODO: CPHA. 0 = sample on _from_ CLK idle; 1 = sample on _to_ CLK idle.
                if rx_buffer(WIDTH) = '1' then
                    -- Start new word
                    tmp_buffer := (1 => '1', 0 => i_mosi, others => '0');
                else 
                    -- Capture bit and shift
                    tmp_buffer := rx_buffer(WIDTH-1 downto 0) & i_mosi; -- Sample and shift
                end if;
            end if;
        end if;
        
        rx_buffer <= tmp_buffer;

        o_dr <= tmp_buffer(WIDTH);
        o_data <= tmp_buffer(WIDTH-1 downto 0) when tmp_buffer(WIDTH) = '1' else (others => 'Z');
    end process spi;

    o_miso <= '0' when ss_n = '0' else 'Z'; -- High-Z when not selected 

end architecture arch;
