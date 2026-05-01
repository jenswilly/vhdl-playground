library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ethernet is
port (
    --Sys/Common
    Clk             : in  std_logic; --100 MHz
    Reset           : in  std_logic; --Active high
    UseDHCP         : in  std_logic; --'1' to use DHCP
    IP_Addr         : in  std_logic_vector(31 downto 0); --IP address if not using DHCP
    IP_Ok           : out std_logic; --DHCP ready

    --MAC/MII
    MII_REF_CLK_25M : out std_logic; --MII continous 25 MHz reference clock
    MII_RST_N       : out std_logic; --Phy reset, active low
    MII_COL         : in  std_logic; --Collision detect
    MII_CRS         : in  std_logic; --Carrier sense
    MII_RX_CLK      : in  std_logic; --Receive clock
    MII_CRS_DV      : in  std_logic; --Receive data valid
    MII_RXD         : in  std_logic_vector(3 downto 0); --Receive data
    MII_RXERR       : in  std_logic; --Receive error
    MII_TX_CLK      : in  std_logic; --Transmit clock
    MII_TXEN        : out std_logic; --Transmit enable
    MII_TXD         : out std_logic_vector(3 downto 0); --Transmit data
    MII_MDC         : out std_logic; --Management clock
    MII_MDIO        : inout std_logic; --Management data

    --UDP Basic Server
    UDP0_Reset      : in  std_logic; --Reset interface, active high
    UDP0_Service    : in  std_logic_vector(15 downto 0); --Service
    UDP0_ServerPort : in  std_logic_vector(15 downto 0); --UDP local server port
    UDP0_Connected  : out std_logic; --Client connected
    UDP0_OutIsEmpty : out std_logic; --All outgoing data acked
    UDP0_TxData     : in  std_logic_vector(7 downto 0); --Transmit data
    UDP0_TxValid    : in  std_logic; --Transmit data valid
    UDP0_TxReady    : out std_logic; --Transmit data ready
    UDP0_TxLast     : in  std_logic; --Transmit data last
    UDP0_RxData     : out std_logic_vector(7 downto 0); --Receive data
    UDP0_RxValid    : out std_logic; --Receive data valid
    UDP0_RxReady    : in  std_logic; --Receive data ready
    UDP0_RxLast     : out std_logic  --Transmit data last
);
end entity ethernet;

architecture arch of ethernet is
begin
    i_FC_1001_MII : FC1001_MII
    port map (
        Clk             => Clk,
        Reset           => Reset,
        UseDHCP         => UseDHCP,
        IP_Addr         => IP_Addr,
        IP_Ok           => IP_Ok,
        MII_REF_CLK_25M => MII_REF_CLK_25M,
        MII_RST_N       => MII_RST_N,
        MII_COL         => MII_COL,
        MII_CRS         => MII_CRS,
        MII_RX_CLK      => MII_RX_CLK,
        MII_CRS_DV      => MII_CRS_DV,
        MII_RXD         => MII_RXD,
        MII_RXERR       => MII_RXERR,
        MII_TX_CLK      => MII_TX_CLK,
        MII_TXEN        => MII_TXEN,
        MII_TXD         => MII_TXD,
        MII_MDC         => MII_MDC,
        MII_MDIO        => MII_MDIO,
        UDP0_Reset      => UDP0_Reset,
        UDP0_Service    => UDP0_Service,
        UDP0_ServerPort => UDP0_ServerPort,
        UDP0_Connected  => UDP0_Connected,
        UDP0_OutIsEmpty => UDP0_OutIsEmpty,
        UDP0_TxData     => UDP0_TxData,
        UDP0_TxValid    => UDP0_TxValid,
        UDP0_TxReady    => UDP0_TxReady,
        UDP0_TxLast     => UDP0_TxLast,
        UDP0_RxData     => UDP0_RxData,
        UDP0_RxValid    => UDP0_RxValid,
        UDP0_RxReady    => UDP0_RxReady,
        UDP0_RxLast     => UDP0_RxLast
    );
end architecture arch;