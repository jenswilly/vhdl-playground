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
-- So make sure the AXI clock is significantly faster than the SPI clock and use a FIFO or similar

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

        i_axis_clk : in std_logic;
        i_axis_rst : in std_logic;      -- Active high reset for the AXI Stream clock domain.
        i_axis_tready : in std_logic;   -- Downstream is ready to accept data
        o_axis_tvalid : out std_logic;  -- Has valid data for the downstream to consume
        o_axis_tdata : out std_logic_vector(WIDTH-1 downto 0)
    );        
end entity spi_slave_axis;

architecture arch of spi_slave_axis is
    -- SPI domain state: assemble one received word from serial MOSI bits.
    signal spi_shift : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal spi_bit_count : integer range 0 to WIDTH-1 := 0;

    -- Toggle flips when a complete word is ready for the AXIS domain.
    signal spi_word_toggle : std_logic := '0';
    -- Holds the completed SPI word until the AXIS side samples it.
    signal spi_word_data : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

    -- Two-stage synchronizer for the word-ready toggle into the AXIS clock domain.
    signal axis_word_toggle_sync : std_logic_vector(1 downto 0) := (others => '0');
    signal axis_word_toggle_seen : std_logic := '0';
    -- AXIS output register pair. tvalid stays high until the consumer accepts it.
    signal axis_tvalid : std_logic := '0';
    signal axis_tdata : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

    -- Backpressure feedback from the AXIS side, sampled back into the SPI clock domain.
    signal spi_tvalid_sync : std_logic_vector(1 downto 0) := (others => '0');
begin

    o_axis_tvalid <= axis_tvalid;
    o_axis_tdata <= axis_tdata;

    spi : process(sclk, ss_n, i_rst)
        variable next_shift : std_logic_vector(WIDTH-1 downto 0);
    begin
        if i_rst = '1' or ss_n = '1' then
            spi_shift <= (others => '0');
            spi_bit_count <= 0;
        elsif rising_edge(sclk) then
            next_shift := spi_shift;

            -- Shift in the next MOSI bit, MSB first.
            next_shift := next_shift(WIDTH - 2 downto 0) & i_mosi;

            if spi_bit_count = WIDTH - 1 then
                -- Word complete. Publish it only if the AXIS side is not already holding one.
                -- If axis_tvalid is still asserted, the previous word has not been consumed yet,
                -- so this new word is intentionally dropped under the no-buffer policy.
                if spi_tvalid_sync(1) = '0' then
                    spi_word_data <= next_shift;
                    spi_word_toggle <= not spi_word_toggle;
                end if;

                -- Start collecting the next SPI word.
                spi_shift <= (others => '0');
                spi_bit_count <= 0;
            else
                -- Keep shifting until the word is complete.
                spi_shift <= next_shift;
                spi_bit_count <= spi_bit_count + 1;
            end if;
        end if;
    end process spi;

    axis : process(i_axis_clk, i_axis_rst)
    begin
        if i_axis_rst = '1' then
            -- Clear the AXIS-visible state on reset.
            axis_word_toggle_sync <= (others => '0');
            axis_word_toggle_seen <= '0';
            axis_tvalid <= '0';
            axis_tdata <= (others => '0');
        elsif rising_edge(i_axis_clk) then
            -- Synchronize the SPI-domain toggle into the AXIS clock domain.
            axis_word_toggle_sync(0) <= spi_word_toggle;
            axis_word_toggle_sync(1) <= axis_word_toggle_sync(0);

            if axis_word_toggle_sync(1) /= axis_word_toggle_seen then
                -- A new SPI word has arrived: capture it and raise tvalid.
                axis_word_toggle_seen <= axis_word_toggle_sync(1);
                axis_tdata <= spi_word_data;
                axis_tvalid <= '1';
            elsif axis_tvalid = '1' and i_axis_tready = '1' then
                -- Consumer accepted the word, so the AXIS output can return idle.
                axis_tvalid <= '0';
            end if;
        end if;
    end process axis;

    spi_tvalid : process(sclk, ss_n, i_rst)
    begin
        if i_rst = '1' or ss_n = '1' then
            -- Backpressure feedback is cleared whenever the SPI side is reset or deselected.
            spi_tvalid_sync <= (others => '0');
        elsif rising_edge(sclk) then
            -- Sample the AXIS-side valid flag back into the SPI clock domain.
            spi_tvalid_sync(0) <= axis_tvalid;
            spi_tvalid_sync(1) <= spi_tvalid_sync(0);
        end if;
    end process spi_tvalid;

    o_miso <= '0' when ss_n = '0' else 'Z'; 

end architecture arch;
