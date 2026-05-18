library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- https://en.wikipedia.org/wiki/Serial_Peripheral_Interface
-- TODO: CPOL/CPHA
--
-- This module implements an SPI slave that outputs received words on an AXI Stream interface.
-- The SPI and AXIS sides are clocked independently, so the design includes synchronization logic
-- to safely transfer data between the two clock domains. The AXIS interface is unidirectional
-- (SPI slave to AXIS master) and has no buffering, so the AXIS consumer must be able to accept 
-- each word before the next one is received over SPI.
-- So make sure the AXI clock is significantly faster than the SPI clock and use a FIFO or 
-- similar.

entity spi_slave_axis is
    generic (
        WIDTH : positive := 8
    );
    port (
        sclk : in std_logic;
        ss_n : in std_logic;
        i_mosi : in std_logic;
        o_miso : out std_logic; 

        i_rst : in std_logic;   -- Active high reset for the SPI clock domain.

        -- Minimal AXI Stream. NB: no axis_tready - assuming downstream is always ready
        i_axis_clk : in std_logic;
        i_axis_rst : in std_logic;      -- Active high reset for the AXI Stream clock domain.
        o_axis_tvalid : out std_logic;  -- Has valid data for the downstream to consume
        o_axis_tdata : out std_logic_vector(WIDTH-1 downto 0)
    );        
end entity spi_slave_axis;

architecture arch of spi_slave_axis is
    -- SPI domain state: assemble one received word from serial MOSI bits.
    signal spi_shift : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal spi_bit_count : integer range 0 to WIDTH-1 := 0;
    signal spi_word_data : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal spi_data_toggle : std_logic := '0';

    -- Synchronize SPI byte-ready event into AXI clock domain.
    signal spi_data_toggle_sync_0 : std_logic := '0';
    signal spi_data_toggle_sync_1 : std_logic := '0';
    signal spi_data_toggle_last   : std_logic := '0';
begin

    spi : process(sclk)
        variable next_shift : std_logic_vector(WIDTH-1 downto 0);
    begin
        if rising_edge(sclk) then
            if i_rst = '1' or ss_n = '1' then
                spi_shift <= (others => '0');
                spi_bit_count <= 0;
            else
                -- CPOL=0, CPHA=0: sample MOSI on rising edge, MSB first.
                next_shift := spi_shift(WIDTH-2 downto 0) & i_mosi;
                spi_shift <= next_shift;

                if spi_bit_count = WIDTH-1 then
                    -- Completed one full word exactly every WIDTH SCLK edges.
                    spi_word_data <= next_shift;
                    spi_data_toggle <= not spi_data_toggle;
                    spi_bit_count <= 0;
                else
                    spi_bit_count <= spi_bit_count + 1;
                end if;
            end if;
        end if;
    end process spi;

    axis : process(i_axis_clk)
    begin
        if rising_edge(i_axis_clk) then
            if i_axis_rst = '1' then
                spi_data_toggle_sync_0 <= '0';
                spi_data_toggle_sync_1 <= '0';
                spi_data_toggle_last <= '0';
                o_axis_tvalid <= '0';
                o_axis_tdata <= (others => '0');
            else
                -- Cross domain event transfer: detect one toggle edge per received SPI word.
                spi_data_toggle_sync_0 <= spi_data_toggle;
                spi_data_toggle_sync_1 <= spi_data_toggle_sync_0;

                if spi_data_toggle_sync_1 /= spi_data_toggle_last then
                    spi_data_toggle_last <= spi_data_toggle_sync_1;
                    o_axis_tdata <= spi_word_data;
                    o_axis_tvalid <= '1';
                else
                    o_axis_tvalid <= '0';
                end if;
            end if;
        end if;
    end process axis;

    o_miso <= '0' when ss_n = '0' else 'Z'; 

end architecture arch;
