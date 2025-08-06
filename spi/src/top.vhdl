library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Top-level disign for RC PWM test
-- Be sure to define CLK (100 MHz) and LED[0:3] in constraints file

entity top is
    port(
        sysclk : in std_logic;
        led : out std_logic_vector(0 to 1)
    );        
end entity top;

architecture rtl of top is
    signal spi_clk : std_logic;
    signal o_spi_mosi : std_logic;
    signal i_spi_miso : std_logic;
    signal spi_ss_n : std_logic;
    signal spi_dr : std_logic;
    signal spi_data : std_logic_vector(7 downto 0);
    
    signal fifo_rst : std_logic := '0';
    signal fifo_rd_en : std_logic := '0';
    signal fifo_dout : std_logic_vector(7 downto 0);
    signal fifo_full : std_logic;
    signal fifo_empty : std_logic;
    
    component fifo_0 is
    port (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC
        );
    end component  fifo_0;
    
begin
    spi1 : entity work.spi_slave(arch)
    generic map ( WIDTH => 8 )
    port map (
        sclk => spi_clk,
        i_mosi => o_spi_mosi,
        o_miso => i_spi_miso,
        ss_n => spi_ss_n,
        o_dr => spi_dr,
        o_data => spi_data
    );
    
    fifo : fifo_0 
    port map (
        clk => sysclk,
        rst => fifo_rst,
        din => spi_data,
        wr_en => spi_dr,
        rd_en => fifo_rd_en,
        dout => fifo_dout,
        full => fifo_full,
        empty => fifo_empty
    );
        
    -- LED assignments
    led(0) <= spi_dr;
    led(1) <= fifo_empty;
    
end architecture rtl;