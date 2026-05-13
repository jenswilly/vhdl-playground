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

    signal fifo_axis_tready : std_logic;
    signal fifo_axis_tvalid : std_logic;
    signal fifo_axis_tdata : std_logic_vector(7 downto 0);

    -- 
    
begin
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
            i_axis_tready => fifo_axis_tready,
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
            m_axis_tready => open,
        );

    -- UART TX instance
    uart_tx_inst : uart_tx
        generic map (
            BIT_RATE => 115_200,
            CLK_HZ => 100_000_000
        )
        port map (
            clk => clk,
            resetn => not rst,
            uart_txd => uart_txd,
            uart_tx_busy => uart_tx_busy,
            uart_tx_en => uart_tx_en,
            uart_tx_data => uart_tx_data
        );    

end architecture rtl;
