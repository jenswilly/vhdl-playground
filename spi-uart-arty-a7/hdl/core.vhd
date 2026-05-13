library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity core is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;

        led0_r      : out std_logic;
        led0_g      : out std_logic;
        led0_b      : out std_logic;
        led1_r      : out std_logic;
        led1_g      : out std_logic;
        led1_b      : out std_logic;
        led2_r      : out std_logic;
        led2_g      : out std_logic;
        led2_b      : out std_logic;
        led3_r      : out std_logic;
        led3_g      : out std_logic;
        led3_b      : out std_logic;
        led4        : out std_logic;
        led5        : out std_logic;
        led6        : out std_logic;
        led7        : out std_logic;

        uart_txd    : out std_logic;

        spi_sclk    : in  std_logic;
        spi_ss_n    : in  std_logic;
        spi_mosi    : in  std_logic
    );
end entity core;

architecture rtl of core is
    -- AXI Stream signals between the SPI slave and the FIFO
    signal spi_axis_tvalid : std_logic;
    signal spi_axis_tdata : std_logic_vector(7 downto 0);

    -- AXI Stream handshake from FIFO input back to SPI output
    signal fifo_axis_tready : std_logic;    -- FIFO ready to accept data (should be always unless full)

    -- AXI Stream signals between the FIFO output and UART bridge logic
    signal fifo_axis_tvalid : std_logic;
    signal fifo_axis_tdata : std_logic_vector(7 downto 0);

    -- AXI Stream FIFO component declaration
    component axis_fifo is
        generic (
            DEPTH       : integer := 8192;
            DATA_WIDTH  : integer := 8;
            KEEP_ENABLE : integer := 0;
            ID_ENABLE   : integer := 0;
            DEST_ENABLE : integer := 0;
            USER_ENABLE : integer := 1;
            USER_WIDTH  : integer := 1;
            FRAME_FIFO  : integer := 0
        );
        port (
            clk               : in  std_logic;
            rst               : in  std_logic;
            s_axis_tdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            s_axis_tkeep      : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0);
            s_axis_tvalid     : in  std_logic;
            s_axis_tready     : out std_logic;
            s_axis_tlast      : in  std_logic;
            s_axis_tid        : in  std_logic_vector(7 downto 0);
            s_axis_tdest      : in  std_logic_vector(7 downto 0);
            s_axis_tuser      : in  std_logic_vector(USER_WIDTH-1 downto 0);
            m_axis_tdata      : out std_logic_vector(DATA_WIDTH-1 downto 0);
            m_axis_tkeep      : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
            m_axis_tvalid     : out std_logic;
            m_axis_tready     : in  std_logic;
            m_axis_tlast      : out std_logic;
            m_axis_tid        : out std_logic_vector(7 downto 0);
            m_axis_tdest      : out std_logic_vector(7 downto 0);
            m_axis_tuser      : out std_logic_vector(USER_WIDTH-1 downto 0);
            status_overflow   : out std_logic;
            status_bad_frame  : out std_logic;
            status_good_frame : out std_logic
        );
    end component;

    -- UART TX component declaration
    component uart_tx is
        generic (
            BIT_RATE      : integer := 9600;
            CLK_HZ        : integer := 50_000_000;
            PAYLOAD_BITS  : integer := 8;
            STOP_BITS     : integer := 1

        );
        port (
            clk          : in  std_logic;
            resetn       : in  std_logic;
            uart_txd     : out std_logic;
            uart_tx_busy : out std_logic;
            uart_tx_en   : in  std_logic;
            uart_tx_data : in  std_logic_vector(PAYLOAD_BITS-1 downto 0)
        );
    end component;

    -- UART bridge control signals
    signal uart_tx_en_sig : std_logic;
    signal uart_tx_busy_sig : std_logic;

begin
    -- Bridge FIFO AXI-stream output to pulse-based UART TX control.
    -- uart_tx_en is asserted for one clk cycle when data is available and UART is idle.
    p_fifo_to_uart_bridge : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                uart_tx_en_sig <= '0';
            else
                uart_tx_en_sig <= '0'; -- Reset to 0 every cycle, only pulse high when conditions are met below.

                -- Consume one FIFO byte only when UART can start a new frame.
                if fifo_axis_tvalid = '1' and uart_tx_busy_sig = '0' then
                    uart_tx_en_sig <= '1';
                end if;
            end if;
        end if;
    end process;


    -- SPI slave instance
    spi_axis : entity work.spi_slave_axis(arch)
        generic map (
            WIDTH => 8
        )
        port map (
            sclk => spi_sclk,
            ss_n => spi_ss_n,
            i_mosi => spi_mosi,
            o_miso => open, -- Not used in this design

            i_rst => rst,

            i_axis_clk => clk,
            i_axis_rst => rst,
            i_axis_tready => fifo_axis_tready,  -- Ready to accept data when FIFO is ready
            o_axis_tvalid => spi_axis_tvalid,
            o_axis_tdata => spi_axis_tdata
        );

    -- FIFO instance
    fifo : axis_fifo
        generic map (
            DEPTH => 8192,
            DATA_WIDTH => 8,
            USER_ENABLE => 1,
            USER_WIDTH => 1
        )
        port map (
            -- FIFO control
            clk => clk,
            rst => rst,

            -- FIFO inputs
            s_axis_tdata => spi_axis_tdata,     -- Data from SPI slave -> FIFO
            s_axis_tkeep => (others => '1'),
            s_axis_tvalid => spi_axis_tvalid,   -- Data presented to FIFO is valid
            s_axis_tready => fifo_axis_tready,  -- FIFO is ready to accept data
            s_axis_tlast => '0',
            s_axis_tid => (others => '0'),
            s_axis_tdest => (others => '0'),
            s_axis_tuser => (others => '0'),

            -- FIFO outputs
            m_axis_tdata => fifo_axis_tdata,
            m_axis_tvalid => fifo_axis_tvalid,
            m_axis_tready => uart_tx_en_sig,    -- Ready to read one byte from FIFO when UART transmit starts
            m_axis_tkeep => open,
            m_axis_tlast => open,
            m_axis_tid => open,
            m_axis_tdest => open,
            m_axis_tuser => open,
            status_overflow => open,
            status_bad_frame => open,
            status_good_frame => open
        );

    -- UART TX instance
    uart_tx_inst : uart_tx
        generic map (
            BIT_RATE => 115_200,
            CLK_HZ => 100_000_000
        )
        port map (
            clk => clk,
            -- uart_tx uses active-low reset, so core active-high rst is inverted.
            resetn => not rst,
            -- Serial TX output routed directly to the top-level UART pin.
            uart_txd => uart_txd,
            -- Busy feedback gates FIFO consumption and next transmit trigger.
            uart_tx_busy => uart_tx_busy_sig,
            -- One-cycle transmit start pulse generated in p_fifo_to_uart_bridge.
            uart_tx_en => uart_tx_en_sig,
            -- Current FIFO output byte sent over UART when uart_tx_en pulses.
            uart_tx_data => fifo_axis_tdata
        );    

end architecture rtl;
