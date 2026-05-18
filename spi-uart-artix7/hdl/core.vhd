library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity core is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        i_btn       : in  std_logic;
        o_leds      : out std_logic_vector(7 downto 0);
        uart_txd    : out std_logic;
        spi_sclk    : in  std_logic;
        spi_ss_n    : in  std_logic;
        spi_mosi    : in  std_logic
    );
end entity core;

architecture rtl of core is
    -- Debug signals
    signal debug_active : std_logic;
    signal debug_tvalid : std_logic;
    signal debug_tdata  : std_logic_vector(7 downto 0);

    -- AXI Stream signals between the SPI slave and the FIFO
    signal spi_axis_tvalid : std_logic;
    signal spi_axis_tdata : std_logic_vector(7 downto 0);

    -- Selected FIFO input stream (SPI or debug byte injection)
    signal fifo_in_tvalid : std_logic;
    signal fifo_in_tdata  : std_logic_vector(7 downto 0);

    -- FIFO ready to accept data (not used,should be always unless full)
    signal fifo_axis_tready : std_logic;    

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
    -- Debug process to inject one byte when the button edge is detected.
    debug_process : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                debug_active <= '0';
                debug_tvalid <= '0';
                debug_tdata <= (others => '0');
            else
                -- Default to no injection; pulse high for one cycle on new press.
                debug_tvalid <= '0';

                if i_btn = '1' and debug_active = '0' then
                    debug_active <= '1';
                    debug_tdata <= x"41";
                    debug_tvalid <= '1';
                elsif i_btn = '0' then
                    debug_active <= '0'; -- Button released, clear active flag
                end if;
            end if;
        end if;
    end process debug_process;

    -- Select debug byte injection when requested, otherwise pass through SPI bytes.
    fifo_in_tvalid <= debug_tvalid or spi_axis_tvalid;
    fifo_in_tdata <= debug_tdata when debug_tvalid = '1' else spi_axis_tdata;

    -- Bridge FIFO AXI-stream output to pulse-based UART TX control.
    -- uart_tx_en is asserted for one clk cycle when data is available and UART is idle.
    fifo_to_uart_bridge : process (clk)
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
    end process fifo_to_uart_bridge;

    -- SPI input -> LEDs process
    spi_to_leds :process (clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                o_leds <= (others => '0');
            else
                o_leds <= spi_axis_tdata; -- Display the most recent SPI byte on the LEDs for debugging
            end if;
        end if;
    end process spi_to_leds;


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
            s_axis_tdata => fifo_in_tdata,      -- Data from selected source -> FIFO
            s_axis_tkeep => (others => '1'),
            s_axis_tvalid => fifo_in_tvalid,    -- Data presented to FIFO is valid
            s_axis_tready => fifo_axis_tready,  -- FIFO is ready to accept data
            s_axis_tlast => '0',
            s_axis_tid => (others => '0'),
            s_axis_tdest => (others => '0'),
            s_axis_tuser => (others => '0'),

            -- FIFO outputs
            m_axis_tdata => fifo_axis_tdata,
            m_axis_tvalid => fifo_axis_tvalid,
            m_axis_tready => uart_tx_en_sig    -- Ready to read one byte from FIFO when UART transmit starts
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
