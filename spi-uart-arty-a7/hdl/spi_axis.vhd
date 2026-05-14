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
    attribute ASYNC_REG : string;
    -- SPI domain state: assemble one received word from serial MOSI bits.
    signal spi_shift : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal spi_bit_count : integer range 0 to WIDTH-1 := 0;

    -- Holds one completed SPI word until the AXIS side accepts it.
    signal spi_word_data : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    -- Request/ack toggles implement a one-word CDC handshake.
    signal spi_req_toggle : std_logic := '0';
    signal axis_ack_toggle : std_logic := '0';
    signal spi_ack_sync : std_logic_vector(1 downto 0) := (others => '0');

    -- Two-stage synchronizer for the SPI request toggle into the AXIS clock domain.
    signal axis_req_sync : std_logic_vector(1 downto 0) := (others => '0');
    signal axis_req_seen : std_logic := '0';
    -- AXIS output register pair. tvalid stays high until the consumer accepts it.
    signal axis_tvalid : std_logic := '0';
    signal axis_tdata : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

    attribute ASYNC_REG of spi_ack_sync : signal is "TRUE";
    attribute ASYNC_REG of axis_req_sync : signal is "TRUE";
begin

    o_axis_tvalid <= axis_tvalid;
    o_axis_tdata <= axis_tdata;

    spi : process(sclk)
        variable next_shift : std_logic_vector(WIDTH-1 downto 0);
    begin
        if rising_edge(sclk) then
            -- Synchronize AXIS ack toggle back into the SPI clock domain.
            spi_ack_sync(0) <= axis_ack_toggle;
            spi_ack_sync(1) <= spi_ack_sync(0);

            if i_rst = '1' then
                spi_shift <= (others => '0');
                spi_bit_count <= 0;
                spi_word_data <= (others => '0');
                spi_req_toggle <= '0';
                spi_ack_sync <= (others => '0');
            elsif ss_n = '1' then
                spi_shift <= (others => '0');
                spi_bit_count <= 0;
            else
                next_shift := spi_shift;

                -- Shift in the next MOSI bit, MSB first.
                next_shift := next_shift(WIDTH - 2 downto 0) & i_mosi;

                if spi_bit_count = WIDTH - 1 then
                    -- Publish only when there is no outstanding word.
                    -- Outstanding state is spi_req_toggle /= spi_ack_sync(1).
                    if spi_req_toggle = spi_ack_sync(1) then
                        spi_word_data <= next_shift;
                        spi_req_toggle <= not spi_req_toggle;
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
        end if;
    end process spi;

    axis : process(i_axis_clk)
    begin
        if rising_edge(i_axis_clk) then
            -- Synchronize the SPI request toggle into the AXIS clock domain.
            axis_req_sync(0) <= spi_req_toggle;
            axis_req_sync(1) <= axis_req_sync(0);

            if i_axis_rst = '1' then
                -- Clear AXIS-visible state and handshake tracking on reset.
                axis_req_sync <= (others => '0');
                axis_req_seen <= '0';
                axis_tvalid <= '0';
                axis_tdata <= (others => '0');
                axis_ack_toggle <= '0';
            else
                if axis_req_sync(1) /= axis_req_seen then
                    -- New SPI word request observed: capture data and raise tvalid.
                    axis_req_seen <= axis_req_sync(1);
                    axis_tdata <= spi_word_data;
                    axis_tvalid <= '1';
                elsif axis_tvalid = '1' and i_axis_tready = '1' then
                    -- Consumer accepted the word; ack it back to SPI and return idle.
                    axis_tvalid <= '0';
                    axis_ack_toggle <= axis_req_seen;
                end if;
            end if;
        end if;
    end process axis;

    o_miso <= '0' when ss_n = '0' else 'Z'; 

end architecture arch;
