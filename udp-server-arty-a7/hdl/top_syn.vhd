library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port (
        -- System
        CLK100MHZ: in STD_LOGIC;
        
        -- LEDs/buttons
        led : out std_logic_vector(0 to 3);
        btn : in std_logic_vector(0 to 0);

        -- Ethernet MII  DP83848J
        eth_ref_clk     : out std_logic;                    -- Reference Clock X1
            
        eth_mdc         : out std_logic;
        eth_mdio        : inout std_logic;
        eth_rstn        : out std_logic;                    -- Reset Phy
    
        eth_rx_clk      : in  std_logic;                     -- Rx Clock
        eth_rx_dv       : in  std_logic;                     -- Rx Data Valid
        eth_rxd         : in  std_logic_vector(3 downto 0);  -- RxData
            
        eth_rxerr       : in  std_logic;                     -- Receive Error
        eth_col         : in  std_logic;                     -- Ethernet Collision
        eth_crs         : in  std_logic;                     -- Ethernet Carrier Sense
                    
        eth_tx_clk      : in  std_logic;                     -- Tx Clock
        eth_tx_en       : out std_logic;                     -- Transmit Enable
        eth_txd         : out std_logic_vector(3 downto 0)   -- Transmit Data
    );
end entity top;

architecture rtl of top is
    -- Clock and reset signals
    signal i_rst            : std_logic;    -- Reset input. Active high. Mapped to btn(0)
    signal reset            : std_logic;    -- Global synchronized reset signal. Active high.

    -- Network signals
    signal IP_Ok            : std_logic;
    signal tx_data          : std_logic_vector(7 downto 0);
    signal rx_data          : std_logic_vector(7 downto 0);
    signal tx_valid         : std_logic;
    signal tx_ready         : std_logic;
    signal tx_last          : std_logic;
    signal rx_valid         : std_logic;
    signal rx_ready         : std_logic;
    signal rx_last          : std_logic;


begin
    -- Global reset handler synchronized to the 100 MHz clock
    reset_inst : entity work.reset(arch)
    port map (
        i_clk => CLK100MHZ,
        i_clk_locked => '1',    -- Clock locked at startup...
        i_reset => i_rst,
        o_reset => reset        -- Use this signal for everything except the clock generator
    );

    ethernet_inst: entity work.ethernet(arch)
    port map (
        Clk             => CLK100MHZ,       -- 100 MHz
        Reset           => reset,           -- Active high

        ----------------------------------------------------------------
        -- System Setup
        ----------------------------------------------------------------
        UseDHCP         => '0',
        IP_Addr         => x"C0A80063", -- 192.168.0.99
        
        ----------------------------------------------------------------
        -- System Status
        ----------------------------------------------------------------
        IP_Ok           => IP_Ok,           -- '1' when DHCP has solved IP
        
        ----------------------------
        -- MII Interface
        ----------------------------
        MII_REF_CLK_25M => eth_ref_clk,
        MII_RST_N       => eth_rstn,
        MII_COL         => eth_col,
        MII_CRS         => eth_crs, 
        MII_RX_CLK      => eth_rx_clk,
        MII_CRS_DV      => eth_rx_dv,
        MII_RXD         => eth_rxd,
        MII_RXERR       => eth_rxerr,   
        MII_TX_CLK      => eth_tx_clk,
        MII_TXEN        => eth_tx_en,
        MII_TXD         => eth_txd,        
        
        -- UDP
        UDP0_Reset      => reset, --Reset interface, active high
        UDP0_Service    => (others => '0'), --Service
        UDP0_ServerPort => x"1388", --UDP local server port
        UDP0_Connected  => open, --Client connected
        UDP0_OutIsEmpty => open, --All outgoing data acked
        UDP0_TxData     => tx_data, --Transmit data
        UDP0_TxValid    => tx_valid, --Transmit data valid
        UDP0_TxReady    => tx_ready, --Transmit data ready
        UDP0_TxLast     => tx_last, --Transmit data last
        UDP0_RxData     => rx_data, --Receive data
        UDP0_RxValid    => rx_valid, --Receive data valid
        UDP0_RxReady    => rx_ready, --Receive data ready
        UDP0_RxLast     => rx_last  --Transmit data last
    );
end architecture rtl;
        