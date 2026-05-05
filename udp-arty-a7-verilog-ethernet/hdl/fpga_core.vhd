library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fpga_core is
    generic (
        TARGET : string := "GENERIC"
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;

        btn         : in  std_logic_vector(3 downto 0);
        sw          : in  std_logic_vector(3 downto 0);
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

        phy_rx_clk  : in  std_logic;
        phy_rxd     : in  std_logic_vector(3 downto 0);
        phy_rx_dv   : in  std_logic;
        phy_rx_er   : in  std_logic;
        phy_tx_clk  : in  std_logic;
        phy_txd     : out std_logic_vector(3 downto 0);
        phy_tx_en   : out std_logic;
        phy_col     : in  std_logic;
        phy_crs     : in  std_logic;
        phy_reset_n : out std_logic;

        uart_rxd    : in  std_logic;
        uart_txd    : out std_logic
    );
end entity fpga_core;

architecture rtl of fpga_core is
    component eth_mac_mii_fifo is
        generic (
            TARGET            : string := "GENERIC";
            CLOCK_INPUT_STYLE : string := "BUFR";
            ENABLE_PADDING    : integer := 1;
            MIN_FRAME_LENGTH  : integer := 64;
            TX_FIFO_DEPTH     : integer := 4096;
            TX_FRAME_FIFO     : integer := 1;
            RX_FIFO_DEPTH     : integer := 4096;
            RX_FRAME_FIFO     : integer := 1
        );
        port (
            rst                : in  std_logic;
            logic_clk          : in  std_logic;
            logic_rst          : in  std_logic;
            tx_axis_tdata      : in  std_logic_vector(7 downto 0);
            tx_axis_tvalid     : in  std_logic;
            tx_axis_tready     : out std_logic;
            tx_axis_tlast      : in  std_logic;
            tx_axis_tuser      : in  std_logic;
            rx_axis_tdata      : out std_logic_vector(7 downto 0);
            rx_axis_tvalid     : out std_logic;
            rx_axis_tready     : in  std_logic;
            rx_axis_tlast      : out std_logic;
            rx_axis_tuser      : out std_logic;
            mii_rx_clk         : in  std_logic;
            mii_rxd            : in  std_logic_vector(3 downto 0);
            mii_rx_dv          : in  std_logic;
            mii_rx_er          : in  std_logic;
            mii_tx_clk         : in  std_logic;
            mii_txd            : out std_logic_vector(3 downto 0);
            mii_tx_en          : out std_logic;
            mii_tx_er          : out std_logic;
            tx_fifo_overflow   : out std_logic;
            tx_fifo_bad_frame  : out std_logic;
            tx_fifo_good_frame : out std_logic;
            rx_error_bad_frame : out std_logic;
            rx_error_bad_fcs   : out std_logic;
            rx_fifo_overflow   : out std_logic;
            rx_fifo_bad_frame  : out std_logic;
            rx_fifo_good_frame : out std_logic;
            cfg_ifg            : in  std_logic_vector(7 downto 0);
            cfg_tx_enable      : in  std_logic;
            cfg_rx_enable      : in  std_logic
        );
    end component;

    component eth_axis_rx is
        port (
            clk                            : in  std_logic;
            rst                            : in  std_logic;
            s_axis_tdata                   : in  std_logic_vector(7 downto 0);
            s_axis_tvalid                  : in  std_logic;
            s_axis_tready                  : out std_logic;
            s_axis_tlast                   : in  std_logic;
            s_axis_tuser                   : in  std_logic;
            m_eth_hdr_valid                : out std_logic;
            m_eth_hdr_ready                : in  std_logic;
            m_eth_dest_mac                 : out std_logic_vector(47 downto 0);
            m_eth_src_mac                  : out std_logic_vector(47 downto 0);
            m_eth_type                     : out std_logic_vector(15 downto 0);
            m_eth_payload_axis_tdata       : out std_logic_vector(7 downto 0);
            m_eth_payload_axis_tvalid      : out std_logic;
            m_eth_payload_axis_tready      : in  std_logic;
            m_eth_payload_axis_tlast       : out std_logic;
            m_eth_payload_axis_tuser       : out std_logic;
            busy                           : out std_logic;
            error_header_early_termination : out std_logic
        );
    end component;

    component eth_axis_tx is
        port (
            clk                        : in  std_logic;
            rst                        : in  std_logic;
            s_eth_hdr_valid            : in  std_logic;
            s_eth_hdr_ready            : out std_logic;
            s_eth_dest_mac             : in  std_logic_vector(47 downto 0);
            s_eth_src_mac              : in  std_logic_vector(47 downto 0);
            s_eth_type                 : in  std_logic_vector(15 downto 0);
            s_eth_payload_axis_tdata   : in  std_logic_vector(7 downto 0);
            s_eth_payload_axis_tvalid  : in  std_logic;
            s_eth_payload_axis_tready  : out std_logic;
            s_eth_payload_axis_tlast   : in  std_logic;
            s_eth_payload_axis_tuser   : in  std_logic;
            m_axis_tdata               : out std_logic_vector(7 downto 0);
            m_axis_tvalid              : out std_logic;
            m_axis_tready              : in  std_logic;
            m_axis_tlast               : out std_logic;
            m_axis_tuser               : out std_logic;
            busy                       : out std_logic
        );
    end component;

    component udp_complete is
        port (
            clk                                    : in  std_logic;
            rst                                    : in  std_logic;
            s_eth_hdr_valid                        : in  std_logic;
            s_eth_hdr_ready                        : out std_logic;
            s_eth_dest_mac                         : in  std_logic_vector(47 downto 0);
            s_eth_src_mac                          : in  std_logic_vector(47 downto 0);
            s_eth_type                             : in  std_logic_vector(15 downto 0);
            s_eth_payload_axis_tdata               : in  std_logic_vector(7 downto 0);
            s_eth_payload_axis_tvalid              : in  std_logic;
            s_eth_payload_axis_tready              : out std_logic;
            s_eth_payload_axis_tlast               : in  std_logic;
            s_eth_payload_axis_tuser               : in  std_logic;
            m_eth_hdr_valid                        : out std_logic;
            m_eth_hdr_ready                        : in  std_logic;
            m_eth_dest_mac                         : out std_logic_vector(47 downto 0);
            m_eth_src_mac                          : out std_logic_vector(47 downto 0);
            m_eth_type                             : out std_logic_vector(15 downto 0);
            m_eth_payload_axis_tdata               : out std_logic_vector(7 downto 0);
            m_eth_payload_axis_tvalid              : out std_logic;
            m_eth_payload_axis_tready              : in  std_logic;
            m_eth_payload_axis_tlast               : out std_logic;
            m_eth_payload_axis_tuser               : out std_logic;
            s_ip_hdr_valid                         : in  std_logic;
            s_ip_hdr_ready                         : out std_logic;
            s_ip_dscp                              : in  std_logic_vector(5 downto 0);
            s_ip_ecn                               : in  std_logic_vector(1 downto 0);
            s_ip_length                            : in  std_logic_vector(15 downto 0);
            s_ip_ttl                               : in  std_logic_vector(7 downto 0);
            s_ip_protocol                          : in  std_logic_vector(7 downto 0);
            s_ip_source_ip                         : in  std_logic_vector(31 downto 0);
            s_ip_dest_ip                           : in  std_logic_vector(31 downto 0);
            s_ip_payload_axis_tdata                : in  std_logic_vector(7 downto 0);
            s_ip_payload_axis_tvalid               : in  std_logic;
            s_ip_payload_axis_tready               : out std_logic;
            s_ip_payload_axis_tlast                : in  std_logic;
            s_ip_payload_axis_tuser                : in  std_logic;
            m_ip_hdr_valid                         : out std_logic;
            m_ip_hdr_ready                         : in  std_logic;
            m_ip_eth_dest_mac                      : out std_logic_vector(47 downto 0);
            m_ip_eth_src_mac                       : out std_logic_vector(47 downto 0);
            m_ip_eth_type                          : out std_logic_vector(15 downto 0);
            m_ip_version                           : out std_logic_vector(3 downto 0);
            m_ip_ihl                               : out std_logic_vector(3 downto 0);
            m_ip_dscp                              : out std_logic_vector(5 downto 0);
            m_ip_ecn                               : out std_logic_vector(1 downto 0);
            m_ip_length                            : out std_logic_vector(15 downto 0);
            m_ip_identification                    : out std_logic_vector(15 downto 0);
            m_ip_flags                             : out std_logic_vector(2 downto 0);
            m_ip_fragment_offset                   : out std_logic_vector(12 downto 0);
            m_ip_ttl                               : out std_logic_vector(7 downto 0);
            m_ip_protocol                          : out std_logic_vector(7 downto 0);
            m_ip_header_checksum                   : out std_logic_vector(15 downto 0);
            m_ip_source_ip                         : out std_logic_vector(31 downto 0);
            m_ip_dest_ip                           : out std_logic_vector(31 downto 0);
            m_ip_payload_axis_tdata                : out std_logic_vector(7 downto 0);
            m_ip_payload_axis_tvalid               : out std_logic;
            m_ip_payload_axis_tready               : in  std_logic;
            m_ip_payload_axis_tlast                : out std_logic;
            m_ip_payload_axis_tuser                : out std_logic;
            s_udp_hdr_valid                        : in  std_logic;
            s_udp_hdr_ready                        : out std_logic;
            s_udp_ip_dscp                          : in  std_logic_vector(5 downto 0);
            s_udp_ip_ecn                           : in  std_logic_vector(1 downto 0);
            s_udp_ip_ttl                           : in  std_logic_vector(7 downto 0);
            s_udp_ip_source_ip                     : in  std_logic_vector(31 downto 0);
            s_udp_ip_dest_ip                       : in  std_logic_vector(31 downto 0);
            s_udp_source_port                      : in  std_logic_vector(15 downto 0);
            s_udp_dest_port                        : in  std_logic_vector(15 downto 0);
            s_udp_length                           : in  std_logic_vector(15 downto 0);
            s_udp_checksum                         : in  std_logic_vector(15 downto 0);
            s_udp_payload_axis_tdata               : in  std_logic_vector(7 downto 0);
            s_udp_payload_axis_tvalid              : in  std_logic;
            s_udp_payload_axis_tready              : out std_logic;
            s_udp_payload_axis_tlast               : in  std_logic;
            s_udp_payload_axis_tuser               : in  std_logic;
            m_udp_hdr_valid                        : out std_logic;
            m_udp_hdr_ready                        : in  std_logic;
            m_udp_eth_dest_mac                     : out std_logic_vector(47 downto 0);
            m_udp_eth_src_mac                      : out std_logic_vector(47 downto 0);
            m_udp_eth_type                         : out std_logic_vector(15 downto 0);
            m_udp_ip_version                       : out std_logic_vector(3 downto 0);
            m_udp_ip_ihl                           : out std_logic_vector(3 downto 0);
            m_udp_ip_dscp                          : out std_logic_vector(5 downto 0);
            m_udp_ip_ecn                           : out std_logic_vector(1 downto 0);
            m_udp_ip_length                        : out std_logic_vector(15 downto 0);
            m_udp_ip_identification                : out std_logic_vector(15 downto 0);
            m_udp_ip_flags                         : out std_logic_vector(2 downto 0);
            m_udp_ip_fragment_offset               : out std_logic_vector(12 downto 0);
            m_udp_ip_ttl                           : out std_logic_vector(7 downto 0);
            m_udp_ip_protocol                      : out std_logic_vector(7 downto 0);
            m_udp_ip_header_checksum               : out std_logic_vector(15 downto 0);
            m_udp_ip_source_ip                     : out std_logic_vector(31 downto 0);
            m_udp_ip_dest_ip                       : out std_logic_vector(31 downto 0);
            m_udp_source_port                      : out std_logic_vector(15 downto 0);
            m_udp_dest_port                        : out std_logic_vector(15 downto 0);
            m_udp_length                           : out std_logic_vector(15 downto 0);
            m_udp_checksum                         : out std_logic_vector(15 downto 0);
            m_udp_payload_axis_tdata               : out std_logic_vector(7 downto 0);
            m_udp_payload_axis_tvalid              : out std_logic;
            m_udp_payload_axis_tready              : in  std_logic;
            m_udp_payload_axis_tlast               : out std_logic;
            m_udp_payload_axis_tuser               : out std_logic;
            ip_rx_busy                             : out std_logic;
            ip_tx_busy                             : out std_logic;
            udp_rx_busy                            : out std_logic;
            udp_tx_busy                            : out std_logic;
            ip_rx_error_header_early_termination   : out std_logic;
            ip_rx_error_payload_early_termination  : out std_logic;
            ip_rx_error_invalid_header             : out std_logic;
            ip_rx_error_invalid_checksum           : out std_logic;
            ip_tx_error_payload_early_termination  : out std_logic;
            ip_tx_error_arp_failed                 : out std_logic;
            udp_rx_error_header_early_termination  : out std_logic;
            udp_rx_error_payload_early_termination : out std_logic;
            udp_tx_error_payload_early_termination : out std_logic;
            local_mac                              : in  std_logic_vector(47 downto 0);
            local_ip                               : in  std_logic_vector(31 downto 0);
            gateway_ip                             : in  std_logic_vector(31 downto 0);
            subnet_mask                            : in  std_logic_vector(31 downto 0);
            clear_arp_cache                        : in  std_logic
        );
    end component;

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

    signal rx_axis_tdata              : std_logic_vector(7 downto 0);
    signal rx_axis_tvalid             : std_logic;
    signal rx_axis_tready             : std_logic;
    signal rx_axis_tlast              : std_logic;
    signal rx_axis_tuser              : std_logic;

    signal tx_axis_tdata              : std_logic_vector(7 downto 0);
    signal tx_axis_tvalid             : std_logic;
    signal tx_axis_tready             : std_logic;
    signal tx_axis_tlast              : std_logic;
    signal tx_axis_tuser              : std_logic;

    signal rx_eth_hdr_ready           : std_logic;
    signal rx_eth_hdr_valid           : std_logic;
    signal rx_eth_dest_mac            : std_logic_vector(47 downto 0);
    signal rx_eth_src_mac             : std_logic_vector(47 downto 0);
    signal rx_eth_type                : std_logic_vector(15 downto 0);
    signal rx_eth_payload_axis_tdata  : std_logic_vector(7 downto 0);
    signal rx_eth_payload_axis_tvalid : std_logic;
    signal rx_eth_payload_axis_tready : std_logic;
    signal rx_eth_payload_axis_tlast  : std_logic;
    signal rx_eth_payload_axis_tuser  : std_logic;

    signal tx_eth_hdr_ready           : std_logic;
    signal tx_eth_hdr_valid           : std_logic;
    signal tx_eth_dest_mac            : std_logic_vector(47 downto 0);
    signal tx_eth_src_mac             : std_logic_vector(47 downto 0);
    signal tx_eth_type                : std_logic_vector(15 downto 0);
    signal tx_eth_payload_axis_tdata  : std_logic_vector(7 downto 0);
    signal tx_eth_payload_axis_tvalid : std_logic;
    signal tx_eth_payload_axis_tready : std_logic;
    signal tx_eth_payload_axis_tlast  : std_logic;
    signal tx_eth_payload_axis_tuser  : std_logic;

    signal rx_ip_hdr_valid            : std_logic;
    signal rx_ip_hdr_ready            : std_logic;
    signal rx_ip_eth_dest_mac         : std_logic_vector(47 downto 0);
    signal rx_ip_eth_src_mac          : std_logic_vector(47 downto 0);
    signal rx_ip_eth_type             : std_logic_vector(15 downto 0);
    signal rx_ip_version              : std_logic_vector(3 downto 0);
    signal rx_ip_ihl                  : std_logic_vector(3 downto 0);
    signal rx_ip_dscp                 : std_logic_vector(5 downto 0);
    signal rx_ip_ecn                  : std_logic_vector(1 downto 0);
    signal rx_ip_length               : std_logic_vector(15 downto 0);
    signal rx_ip_identification       : std_logic_vector(15 downto 0);
    signal rx_ip_flags                : std_logic_vector(2 downto 0);
    signal rx_ip_fragment_offset      : std_logic_vector(12 downto 0);
    signal rx_ip_ttl                  : std_logic_vector(7 downto 0);
    signal rx_ip_protocol             : std_logic_vector(7 downto 0);
    signal rx_ip_header_checksum      : std_logic_vector(15 downto 0);
    signal rx_ip_source_ip            : std_logic_vector(31 downto 0);
    signal rx_ip_dest_ip              : std_logic_vector(31 downto 0);
    signal rx_ip_payload_axis_tdata   : std_logic_vector(7 downto 0);
    signal rx_ip_payload_axis_tvalid  : std_logic;
    signal rx_ip_payload_axis_tready  : std_logic;
    signal rx_ip_payload_axis_tlast   : std_logic;
    signal rx_ip_payload_axis_tuser   : std_logic;

    signal tx_ip_hdr_valid            : std_logic;
    signal tx_ip_hdr_ready            : std_logic;
    signal tx_ip_dscp                 : std_logic_vector(5 downto 0);
    signal tx_ip_ecn                  : std_logic_vector(1 downto 0);
    signal tx_ip_length               : std_logic_vector(15 downto 0);
    signal tx_ip_ttl                  : std_logic_vector(7 downto 0);
    signal tx_ip_protocol             : std_logic_vector(7 downto 0);
    signal tx_ip_source_ip            : std_logic_vector(31 downto 0);
    signal tx_ip_dest_ip              : std_logic_vector(31 downto 0);
    signal tx_ip_payload_axis_tdata   : std_logic_vector(7 downto 0);
    signal tx_ip_payload_axis_tvalid  : std_logic;
    signal tx_ip_payload_axis_tready  : std_logic;
    signal tx_ip_payload_axis_tlast   : std_logic;
    signal tx_ip_payload_axis_tuser   : std_logic;

    signal rx_udp_hdr_valid           : std_logic;
    signal rx_udp_hdr_ready           : std_logic;
    signal rx_udp_eth_dest_mac        : std_logic_vector(47 downto 0);
    signal rx_udp_eth_src_mac         : std_logic_vector(47 downto 0);
    signal rx_udp_eth_type            : std_logic_vector(15 downto 0);
    signal rx_udp_ip_version          : std_logic_vector(3 downto 0);
    signal rx_udp_ip_ihl              : std_logic_vector(3 downto 0);
    signal rx_udp_ip_dscp             : std_logic_vector(5 downto 0);
    signal rx_udp_ip_ecn              : std_logic_vector(1 downto 0);
    signal rx_udp_ip_length           : std_logic_vector(15 downto 0);
    signal rx_udp_ip_identification   : std_logic_vector(15 downto 0);
    signal rx_udp_ip_flags            : std_logic_vector(2 downto 0);
    signal rx_udp_ip_fragment_offset  : std_logic_vector(12 downto 0);
    signal rx_udp_ip_ttl              : std_logic_vector(7 downto 0);
    signal rx_udp_ip_protocol         : std_logic_vector(7 downto 0);
    signal rx_udp_ip_header_checksum  : std_logic_vector(15 downto 0);
    signal rx_udp_ip_source_ip        : std_logic_vector(31 downto 0);
    signal rx_udp_ip_dest_ip          : std_logic_vector(31 downto 0);
    signal rx_udp_source_port         : std_logic_vector(15 downto 0);
    signal rx_udp_dest_port           : std_logic_vector(15 downto 0);
    signal rx_udp_length              : std_logic_vector(15 downto 0);
    signal rx_udp_checksum            : std_logic_vector(15 downto 0);
    signal rx_udp_payload_axis_tdata  : std_logic_vector(7 downto 0);
    signal rx_udp_payload_axis_tvalid : std_logic;
    signal rx_udp_payload_axis_tready : std_logic;
    signal rx_udp_payload_axis_tlast  : std_logic;
    signal rx_udp_payload_axis_tuser  : std_logic;

    signal tx_udp_hdr_valid           : std_logic;
    signal tx_udp_hdr_ready           : std_logic;
    signal tx_udp_ip_dscp             : std_logic_vector(5 downto 0);
    signal tx_udp_ip_ecn              : std_logic_vector(1 downto 0);
    signal tx_udp_ip_ttl              : std_logic_vector(7 downto 0);
    signal tx_udp_ip_source_ip        : std_logic_vector(31 downto 0);
    signal tx_udp_ip_dest_ip          : std_logic_vector(31 downto 0);
    signal tx_udp_source_port         : std_logic_vector(15 downto 0);
    signal tx_udp_dest_port           : std_logic_vector(15 downto 0);
    signal tx_udp_length              : std_logic_vector(15 downto 0);
    signal tx_udp_checksum            : std_logic_vector(15 downto 0);
    signal tx_udp_payload_axis_tdata  : std_logic_vector(7 downto 0);
    signal tx_udp_payload_axis_tvalid : std_logic;
    signal tx_udp_payload_axis_tready : std_logic;
    signal tx_udp_payload_axis_tlast  : std_logic;
    signal tx_udp_payload_axis_tuser  : std_logic;

    signal rx_fifo_udp_payload_axis_tdata  : std_logic_vector(7 downto 0);
    signal rx_fifo_udp_payload_axis_tvalid : std_logic;
    signal rx_fifo_udp_payload_axis_tready : std_logic;
    signal rx_fifo_udp_payload_axis_tlast  : std_logic;
    signal rx_fifo_udp_payload_axis_tuser  : std_logic;

    signal tx_fifo_udp_payload_axis_tdata  : std_logic_vector(7 downto 0);
    signal tx_fifo_udp_payload_axis_tvalid : std_logic;
    signal tx_fifo_udp_payload_axis_tready : std_logic;
    signal tx_fifo_udp_payload_axis_tlast  : std_logic;
    signal tx_fifo_udp_payload_axis_tuser  : std_logic;

    constant local_mac   : std_logic_vector(47 downto 0) := x"02_00_00_00_00_00";
    constant local_ip    : std_logic_vector(31 downto 0) := x"C0_A8_01_80";    -- 192.168.1.128
    constant gateway_ip  : std_logic_vector(31 downto 0) := x"C0_A8_01_01";    -- 192 168 1 1
    constant subnet_mask : std_logic_vector(31 downto 0) := x"FF_FF_FF_00";

    signal match_cond     : std_logic;
    signal no_match       : std_logic;
    signal match_cond_reg : std_logic := '0';
    signal no_match_reg   : std_logic := '0';
    signal first_byte_received     : std_logic := '0';
    signal led_reg        : std_logic_vector(7 downto 0) := (others => '0');

    -- UART signals
    signal uart_tx_en   : std_logic;
    signal uart_tx_data : std_logic_vector(7 downto 0);
    signal uart_tx_busy : std_logic;

    -- UART payload FIFO signals
    signal uart_fifo_s_tvalid : std_logic;
    signal uart_fifo_s_tready : std_logic;
    signal uart_fifo_m_tdata  : std_logic_vector(7 downto 0);
    signal uart_fifo_m_tvalid : std_logic;
    signal uart_fifo_m_tready : std_logic;
    signal uart_fifo_m_tlast  : std_logic;

begin
    match_cond <= '1' when rx_udp_dest_port = x"04D2" else '0'; -- 1234
    no_match <= not match_cond;

    rx_ip_hdr_ready <= '1';
    rx_ip_payload_axis_tready <= '1';

    tx_ip_hdr_valid <= '0';
    tx_ip_dscp <= (others => '0');
    tx_ip_ecn <= (others => '0');
    tx_ip_length <= (others => '0');
    tx_ip_ttl <= (others => '0');
    tx_ip_protocol <= (others => '0');
    tx_ip_source_ip <= (others => '0');
    tx_ip_dest_ip <= (others => '0');
    tx_ip_payload_axis_tdata <= (others => '0');
    tx_ip_payload_axis_tvalid <= '0';
    tx_ip_payload_axis_tlast <= '0';
    tx_ip_payload_axis_tuser <= '0';

    tx_udp_hdr_valid <= rx_udp_hdr_valid and match_cond;
    rx_udp_hdr_ready <= (tx_eth_hdr_ready and match_cond) or no_match;
    tx_udp_ip_dscp <= (others => '0');
    tx_udp_ip_ecn <= (others => '0');
    tx_udp_ip_ttl <= x"40";
    tx_udp_ip_source_ip <= local_ip;
    tx_udp_ip_dest_ip <= rx_udp_ip_source_ip;
    tx_udp_source_port <= rx_udp_dest_port;
    tx_udp_dest_port <= rx_udp_source_port;
    tx_udp_length <= rx_udp_length;
    tx_udp_checksum <= (others => '0');

    tx_udp_payload_axis_tdata <= tx_fifo_udp_payload_axis_tdata;
    tx_udp_payload_axis_tvalid <= tx_fifo_udp_payload_axis_tvalid;
    tx_fifo_udp_payload_axis_tready <= tx_udp_payload_axis_tready;
    tx_udp_payload_axis_tlast <= tx_fifo_udp_payload_axis_tlast;
    tx_udp_payload_axis_tuser <= tx_fifo_udp_payload_axis_tuser;

    rx_fifo_udp_payload_axis_tdata <= rx_udp_payload_axis_tdata;
    rx_fifo_udp_payload_axis_tvalid <= rx_udp_payload_axis_tvalid and match_cond_reg;
    rx_udp_payload_axis_tready <= ((rx_fifo_udp_payload_axis_tready and uart_fifo_s_tready) and match_cond_reg) or no_match_reg;
    rx_fifo_udp_payload_axis_tlast <= rx_udp_payload_axis_tlast;
    rx_fifo_udp_payload_axis_tuser <= rx_udp_payload_axis_tuser;
    uart_fifo_s_tvalid <= rx_udp_payload_axis_tvalid and match_cond_reg;
    uart_fifo_m_tready <= uart_tx_en;

    led0_r <= '0';
    led0_b <= '0';
    led1_r <= '0';
    led1_b <= '0';
    led2_r <= '0';
    led2_b <= '0';
    led3_r <= '0';
    led3_b <= '0';
    led0_g <= led_reg(7);
    led1_g <= led_reg(6);
    led2_g <= led_reg(5);
    led3_g <= led_reg(4);
    led4 <= led_reg(3);
    led5 <= led_reg(2);
    led6 <= led_reg(1);
    led7 <= led_reg(0);
    phy_reset_n <= not rst;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                match_cond_reg <= '0';
                no_match_reg <= '0';
            else
                if rx_udp_payload_axis_tvalid = '1' then
                    if (match_cond_reg = '0' and no_match_reg = '0') or
                       (rx_udp_payload_axis_tvalid = '1' and rx_udp_payload_axis_tready = '1' and rx_udp_payload_axis_tlast = '1') then
                        match_cond_reg <= match_cond;
                        no_match_reg <= no_match;
                    end if;
                else
                    match_cond_reg <= '0';
                    no_match_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    -- LED process: copy first byte of UDP payload to LEDs when a packet is received
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                led_reg <= (others => '0');
                first_byte_received <= '0';
            else
                if tx_udp_payload_axis_tvalid = '1' then
                    -- If receiving the first byte of the packet, copy it to the LED register
                    if first_byte_received = '0' then
                        led_reg <= tx_udp_payload_axis_tdata;
                        first_byte_received <= '1';
                    end if;

                    -- Reset the first_byte_received flag when the end of the packet is reached
                    if tx_udp_payload_axis_tlast = '1' then
                        first_byte_received <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- UART process: forward bytes from UART FIFO to UART transmitter
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                uart_tx_en   <= '0';
                uart_tx_data <= (others => '0');
            else
                uart_tx_en <= '0';
                if uart_fifo_m_tvalid = '1' and uart_tx_busy = '0' and uart_tx_en = '0' then
                    uart_tx_en   <= '1';
                    uart_tx_data <= uart_fifo_m_tdata;
                end if;
            end if;
        end if;
    end process;

    uart_tx_inst : uart_tx
        generic map (
            BIT_RATE => 115_200,
            CLK_HZ => 125_000_000
        )
        port map (
            clk => clk,
            resetn => not rst,
            uart_txd => uart_txd,
            uart_tx_busy => uart_tx_busy,
            uart_tx_en => uart_tx_en,
            uart_tx_data => uart_tx_data
        );

    eth_mac_inst : eth_mac_mii_fifo
        generic map (
            TARGET => TARGET,
            CLOCK_INPUT_STYLE => "BUFR",
            ENABLE_PADDING => 1,
            MIN_FRAME_LENGTH => 64,
            TX_FIFO_DEPTH => 4096,
            TX_FRAME_FIFO => 1,
            RX_FIFO_DEPTH => 4096,
            RX_FRAME_FIFO => 1
        )
        port map (
            rst => rst,
            logic_clk => clk,
            logic_rst => rst,
            tx_axis_tdata => tx_axis_tdata,
            tx_axis_tvalid => tx_axis_tvalid,
            tx_axis_tready => tx_axis_tready,
            tx_axis_tlast => tx_axis_tlast,
            tx_axis_tuser => tx_axis_tuser,
            rx_axis_tdata => rx_axis_tdata,
            rx_axis_tvalid => rx_axis_tvalid,
            rx_axis_tready => rx_axis_tready,
            rx_axis_tlast => rx_axis_tlast,
            rx_axis_tuser => rx_axis_tuser,
            mii_rx_clk => phy_rx_clk,
            mii_rxd => phy_rxd,
            mii_rx_dv => phy_rx_dv,
            mii_rx_er => phy_rx_er,
            mii_tx_clk => phy_tx_clk,
            mii_txd => phy_txd,
            mii_tx_en => phy_tx_en,
            mii_tx_er => open,
            tx_fifo_overflow => open,
            tx_fifo_bad_frame => open,
            tx_fifo_good_frame => open,
            rx_error_bad_frame => open,
            rx_error_bad_fcs => open,
            rx_fifo_overflow => open,
            rx_fifo_bad_frame => open,
            rx_fifo_good_frame => open,
            cfg_ifg => x"0C",
            cfg_tx_enable => '1',
            cfg_rx_enable => '1'
        );

    eth_axis_rx_inst : eth_axis_rx
        port map (
            clk => clk,
            rst => rst,
            s_axis_tdata => rx_axis_tdata,
            s_axis_tvalid => rx_axis_tvalid,
            s_axis_tready => rx_axis_tready,
            s_axis_tlast => rx_axis_tlast,
            s_axis_tuser => rx_axis_tuser,
            m_eth_hdr_valid => rx_eth_hdr_valid,
            m_eth_hdr_ready => rx_eth_hdr_ready,
            m_eth_dest_mac => rx_eth_dest_mac,
            m_eth_src_mac => rx_eth_src_mac,
            m_eth_type => rx_eth_type,
            m_eth_payload_axis_tdata => rx_eth_payload_axis_tdata,
            m_eth_payload_axis_tvalid => rx_eth_payload_axis_tvalid,
            m_eth_payload_axis_tready => rx_eth_payload_axis_tready,
            m_eth_payload_axis_tlast => rx_eth_payload_axis_tlast,
            m_eth_payload_axis_tuser => rx_eth_payload_axis_tuser,
            busy => open,
            error_header_early_termination => open
        );

    eth_axis_tx_inst : eth_axis_tx
        port map (
            clk => clk,
            rst => rst,
            s_eth_hdr_valid => tx_eth_hdr_valid,
            s_eth_hdr_ready => tx_eth_hdr_ready,
            s_eth_dest_mac => tx_eth_dest_mac,
            s_eth_src_mac => tx_eth_src_mac,
            s_eth_type => tx_eth_type,
            s_eth_payload_axis_tdata => tx_eth_payload_axis_tdata,
            s_eth_payload_axis_tvalid => tx_eth_payload_axis_tvalid,
            s_eth_payload_axis_tready => tx_eth_payload_axis_tready,
            s_eth_payload_axis_tlast => tx_eth_payload_axis_tlast,
            s_eth_payload_axis_tuser => tx_eth_payload_axis_tuser,
            m_axis_tdata => tx_axis_tdata,
            m_axis_tvalid => tx_axis_tvalid,
            m_axis_tready => tx_axis_tready,
            m_axis_tlast => tx_axis_tlast,
            m_axis_tuser => tx_axis_tuser,
            busy => open
        );

    udp_complete_inst : udp_complete
        port map (
            clk => clk,
            rst => rst,
            s_eth_hdr_valid => rx_eth_hdr_valid,
            s_eth_hdr_ready => rx_eth_hdr_ready,
            s_eth_dest_mac => rx_eth_dest_mac,
            s_eth_src_mac => rx_eth_src_mac,
            s_eth_type => rx_eth_type,
            s_eth_payload_axis_tdata => rx_eth_payload_axis_tdata,
            s_eth_payload_axis_tvalid => rx_eth_payload_axis_tvalid,
            s_eth_payload_axis_tready => rx_eth_payload_axis_tready,
            s_eth_payload_axis_tlast => rx_eth_payload_axis_tlast,
            s_eth_payload_axis_tuser => rx_eth_payload_axis_tuser,
            m_eth_hdr_valid => tx_eth_hdr_valid,
            m_eth_hdr_ready => tx_eth_hdr_ready,
            m_eth_dest_mac => tx_eth_dest_mac,
            m_eth_src_mac => tx_eth_src_mac,
            m_eth_type => tx_eth_type,
            m_eth_payload_axis_tdata => tx_eth_payload_axis_tdata,
            m_eth_payload_axis_tvalid => tx_eth_payload_axis_tvalid,
            m_eth_payload_axis_tready => tx_eth_payload_axis_tready,
            m_eth_payload_axis_tlast => tx_eth_payload_axis_tlast,
            m_eth_payload_axis_tuser => tx_eth_payload_axis_tuser,
            s_ip_hdr_valid => tx_ip_hdr_valid,
            s_ip_hdr_ready => tx_ip_hdr_ready,
            s_ip_dscp => tx_ip_dscp,
            s_ip_ecn => tx_ip_ecn,
            s_ip_length => tx_ip_length,
            s_ip_ttl => tx_ip_ttl,
            s_ip_protocol => tx_ip_protocol,
            s_ip_source_ip => tx_ip_source_ip,
            s_ip_dest_ip => tx_ip_dest_ip,
            s_ip_payload_axis_tdata => tx_ip_payload_axis_tdata,
            s_ip_payload_axis_tvalid => tx_ip_payload_axis_tvalid,
            s_ip_payload_axis_tready => tx_ip_payload_axis_tready,
            s_ip_payload_axis_tlast => tx_ip_payload_axis_tlast,
            s_ip_payload_axis_tuser => tx_ip_payload_axis_tuser,
            m_ip_hdr_valid => rx_ip_hdr_valid,
            m_ip_hdr_ready => rx_ip_hdr_ready,
            m_ip_eth_dest_mac => rx_ip_eth_dest_mac,
            m_ip_eth_src_mac => rx_ip_eth_src_mac,
            m_ip_eth_type => rx_ip_eth_type,
            m_ip_version => rx_ip_version,
            m_ip_ihl => rx_ip_ihl,
            m_ip_dscp => rx_ip_dscp,
            m_ip_ecn => rx_ip_ecn,
            m_ip_length => rx_ip_length,
            m_ip_identification => rx_ip_identification,
            m_ip_flags => rx_ip_flags,
            m_ip_fragment_offset => rx_ip_fragment_offset,
            m_ip_ttl => rx_ip_ttl,
            m_ip_protocol => rx_ip_protocol,
            m_ip_header_checksum => rx_ip_header_checksum,
            m_ip_source_ip => rx_ip_source_ip,
            m_ip_dest_ip => rx_ip_dest_ip,
            m_ip_payload_axis_tdata => rx_ip_payload_axis_tdata,
            m_ip_payload_axis_tvalid => rx_ip_payload_axis_tvalid,
            m_ip_payload_axis_tready => rx_ip_payload_axis_tready,
            m_ip_payload_axis_tlast => rx_ip_payload_axis_tlast,
            m_ip_payload_axis_tuser => rx_ip_payload_axis_tuser,
            s_udp_hdr_valid => tx_udp_hdr_valid,
            s_udp_hdr_ready => tx_udp_hdr_ready,
            s_udp_ip_dscp => tx_udp_ip_dscp,
            s_udp_ip_ecn => tx_udp_ip_ecn,
            s_udp_ip_ttl => tx_udp_ip_ttl,
            s_udp_ip_source_ip => tx_udp_ip_source_ip,
            s_udp_ip_dest_ip => tx_udp_ip_dest_ip,
            s_udp_source_port => tx_udp_source_port,
            s_udp_dest_port => tx_udp_dest_port,
            s_udp_length => tx_udp_length,
            s_udp_checksum => tx_udp_checksum,
            s_udp_payload_axis_tdata => tx_udp_payload_axis_tdata,
            s_udp_payload_axis_tvalid => tx_udp_payload_axis_tvalid,
            s_udp_payload_axis_tready => tx_udp_payload_axis_tready,
            s_udp_payload_axis_tlast => tx_udp_payload_axis_tlast,
            s_udp_payload_axis_tuser => tx_udp_payload_axis_tuser,
            m_udp_hdr_valid => rx_udp_hdr_valid,
            m_udp_hdr_ready => rx_udp_hdr_ready,
            m_udp_eth_dest_mac => rx_udp_eth_dest_mac,
            m_udp_eth_src_mac => rx_udp_eth_src_mac,
            m_udp_eth_type => rx_udp_eth_type,
            m_udp_ip_version => rx_udp_ip_version,
            m_udp_ip_ihl => rx_udp_ip_ihl,
            m_udp_ip_dscp => rx_udp_ip_dscp,
            m_udp_ip_ecn => rx_udp_ip_ecn,
            m_udp_ip_length => rx_udp_ip_length,
            m_udp_ip_identification => rx_udp_ip_identification,
            m_udp_ip_flags => rx_udp_ip_flags,
            m_udp_ip_fragment_offset => rx_udp_ip_fragment_offset,
            m_udp_ip_ttl => rx_udp_ip_ttl,
            m_udp_ip_protocol => rx_udp_ip_protocol,
            m_udp_ip_header_checksum => rx_udp_ip_header_checksum,
            m_udp_ip_source_ip => rx_udp_ip_source_ip,
            m_udp_ip_dest_ip => rx_udp_ip_dest_ip,
            m_udp_source_port => rx_udp_source_port,
            m_udp_dest_port => rx_udp_dest_port,
            m_udp_length => rx_udp_length,
            m_udp_checksum => rx_udp_checksum,
            m_udp_payload_axis_tdata => rx_udp_payload_axis_tdata,
            m_udp_payload_axis_tvalid => rx_udp_payload_axis_tvalid,
            m_udp_payload_axis_tready => rx_udp_payload_axis_tready,
            m_udp_payload_axis_tlast => rx_udp_payload_axis_tlast,
            m_udp_payload_axis_tuser => rx_udp_payload_axis_tuser,
            ip_rx_busy => open,
            ip_tx_busy => open,
            udp_rx_busy => open,
            udp_tx_busy => open,
            ip_rx_error_header_early_termination => open,
            ip_rx_error_payload_early_termination => open,
            ip_rx_error_invalid_header => open,
            ip_rx_error_invalid_checksum => open,
            ip_tx_error_payload_early_termination => open,
            ip_tx_error_arp_failed => open,
            udp_rx_error_header_early_termination => open,
            udp_rx_error_payload_early_termination => open,
            udp_tx_error_payload_early_termination => open,
            local_mac => local_mac,
            local_ip => local_ip,
            gateway_ip => gateway_ip,
            subnet_mask => subnet_mask,
            clear_arp_cache => '0'
        );

    udp_payload_fifo : axis_fifo
        generic map (
            DEPTH => 8192,
            DATA_WIDTH => 8,
            KEEP_ENABLE => 0,
            ID_ENABLE => 0,
            DEST_ENABLE => 0,
            USER_ENABLE => 1,
            USER_WIDTH => 1,
            FRAME_FIFO => 0
        )
        port map (
            clk => clk,
            rst => rst,
            s_axis_tdata => rx_fifo_udp_payload_axis_tdata,
            s_axis_tkeep => "0",
            s_axis_tvalid => rx_fifo_udp_payload_axis_tvalid,
            s_axis_tready => rx_fifo_udp_payload_axis_tready,
            s_axis_tlast => rx_fifo_udp_payload_axis_tlast,
            s_axis_tid => (others => '0'),
            s_axis_tdest => (others => '0'),
            s_axis_tuser(0) => rx_fifo_udp_payload_axis_tuser,
            m_axis_tdata => tx_fifo_udp_payload_axis_tdata,
            m_axis_tkeep => open,
            m_axis_tvalid => tx_fifo_udp_payload_axis_tvalid,
            m_axis_tready => tx_fifo_udp_payload_axis_tready,
            m_axis_tlast => tx_fifo_udp_payload_axis_tlast,
            m_axis_tid => open,
            m_axis_tdest => open,
            m_axis_tuser(0) => tx_fifo_udp_payload_axis_tuser,
            status_overflow => open,
            status_bad_frame => open,
            status_good_frame => open
        );

    uart_payload_fifo : axis_fifo
        generic map (
            DEPTH       => 8192,
            DATA_WIDTH  => 8,
            KEEP_ENABLE => 0,
            ID_ENABLE   => 0,
            DEST_ENABLE => 0,
            USER_ENABLE => 1,
            USER_WIDTH  => 1,
            FRAME_FIFO  => 0
        )
        port map (
            clk               => clk,
            rst               => rst,
            s_axis_tdata      => rx_udp_payload_axis_tdata,
            s_axis_tkeep      => "0",
            s_axis_tvalid     => uart_fifo_s_tvalid,
            s_axis_tready     => uart_fifo_s_tready,
            s_axis_tlast      => rx_udp_payload_axis_tlast,
            s_axis_tid        => (others => '0'),
            s_axis_tdest      => (others => '0'),
            s_axis_tuser      => (others => '0'),
            m_axis_tdata      => uart_fifo_m_tdata,
            m_axis_tkeep      => open,
            m_axis_tvalid     => uart_fifo_m_tvalid,
            m_axis_tready     => uart_fifo_m_tready,
            m_axis_tlast      => uart_fifo_m_tlast,
            m_axis_tid        => open,
            m_axis_tdest      => open,
            m_axis_tuser      => open,
            status_overflow   => open,
            status_bad_frame  => open,
            status_good_frame => open
        );
end architecture rtl;
