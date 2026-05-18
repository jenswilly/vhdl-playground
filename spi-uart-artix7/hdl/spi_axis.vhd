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
    -- Use WIDTH+1 bits: MSB is '1' when starting a new word, as in spi.vhdl
    signal spi_shift : std_logic_vector(WIDTH downto 0) := (0 => '1', others => '0');
    signal spi_word_data : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal spi_data_ready : std_logic := '0';
begin

    spi : process(sclk)
        variable next_shift : std_logic_vector(WIDTH downto 0);
    begin
        if rising_edge(sclk) then
            if i_rst = '1' or ss_n = '1' then
                spi_shift <= (0 => '1', others => '0');
                spi_data_ready <= '0';
            else
                -- Default: shift in new bit, MSB first, keep MSB as marker
                next_shift := spi_shift(WIDTH-1 downto 0) & i_mosi;

                if spi_shift(WIDTH) = '1' then
                    -- Starting new word. Data was captured last iteration
                    next_shift := (1 => '1', 0 => i_mosi, others => '0');
                    spi_data_ready <= '0';
                elsif spi_shift(WIDTH-1) = '1' then
                    -- About to shift in last bit: capture data and flag ready
                    spi_word_data <= spi_shift(WIDTH-2 downto 0) & i_mosi;
                    spi_data_ready <= '1';
                    next_shift := (1 => '1', 0 => i_mosi, others => '0');
                else
                    spi_data_ready <= '0';
                end if;
                spi_shift <= next_shift;
            end if;
        end if;
    end process spi;

    axis : process(i_axis_clk)
    begin
        if rising_edge(i_axis_clk) then
            if i_axis_rst = '1' then
                o_axis_tvalid <= '0';
                o_axis_tdata <= (others => '0');
            else
                -- Pulse tvalid for one cycle when data is ready
                if spi_data_ready = '1' then
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
