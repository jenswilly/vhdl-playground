library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- For MMCME2_BASE
Library UNISIM;
use UNISIM.vcomponents.all;

-- Top-level design for SPI-to-FIFO interface on Cmod-A7
-- This design is the "system" entity that integrates the SPI slave, FIFO, and LED control.
--
-- Required inputs are:
-- - `i_clk`: 12 MHz system clock (which will be scaled to 48 MHz for FIFO and reset logic)
-- - `o_led`: active high LED output indicating "FIFO not empty"
-- - `i_spi_clk`: SPI clock input
-- - `i_spi_mosi`: SPI input
-- - `i_spi_ss_n`: SPI CS/SS (active low) input
-- - `o_spi_miso`: SPI output (nothing is output from this system)
--

entity system is
port(
    i_clk : in std_logic;
    o_leds : out std_logic_vector(0 to 1);
    i_rst : in std_logic;                   -- Global reset. Active high.
    o_ready : out std_logic;                -- Clock and reset handler ready.
    o_servo : out std_logic_vector(0 to 1); -- Output servo PWM
    
    -- SPI input
    i_spi_clk : in std_logic;
    i_spi_mosi : in std_logic;
    i_spi_ss_n : in std_logic;
    o_spi_miso : out std_logic
);        
end entity system;

architecture arch of system is
    constant RESOLUTION : positive := 255;
    
    -- Clock and reset signals
    signal clk_locked : std_logic;
    signal clk_48mhz : std_logic;
    signal reset : std_logic;

    -- SPI signals
    signal spi_dr : std_logic;
    signal spi_data : std_logic_vector(15 downto 0);
    signal spi_busy : std_logic;
    
    -- Servo positions
    signal pwm_0_pos : integer range 0 to 255 := 128;
    signal pwm_1_pos : integer range 0 to 255 := 128;
    
    component spi_slave2 is
    generic(
        N                     : integer := 2;      -- number of bit to serialize
        CPOL                  : std_logic := '0' );  -- clock polarity
    port (
        o_busy                      : out std_logic;  -- receiving data if '1'
        i_data_parallel             : in  std_logic_vector(N-1 downto 0);  -- data to sent
        o_data_parallel             : out std_logic_vector(N-1 downto 0);  -- received data
        i_sclk                      : in  std_logic;
        i_ss                        : in  std_logic;
        i_mosi                      : in  std_logic;
        o_miso                      : out std_logic);
    end component spi_slave2;
begin
    -- 48 MHz clock generation from the 12 MHz system clock
    -- (Not strictly necessary in our case...)
    clock_48mhz_inst : entity work.clock(arch)
    port map (
        i_clk => i_clk,
        i_rst => i_rst, -- Use input reset here. `reset` signal depends on this clock.
        o_48mhz_clk => clk_48mhz,
        o_clk_locked => clk_locked
    );

    -- Global reset handler synchronized to the 48 MHz clock
    reset_inst : entity work.reset(arch)
    port map (
        i_clk => clk_48mhz,
        i_clk_locked => clk_locked,
        i_reset => i_rst,
        o_reset => reset -- Use this signal for everything except the clock generator
    );
    
    -- SPI slave in only synchronized to the SPI clock
    -- spi_inst : entity work.spi_slave(arch)
    -- generic map ( WIDTH => 16 )
    -- port map (
    --     sclk => i_spi_clk,
    --     i_mosi => i_spi_mosi,
    --     o_miso => o_spi_miso,
    --     ss_n => i_spi_ss_n,
    --     i_rst => reset,
    --     o_dr => spi_dr,
    --     o_data => spi_data
    -- );
    spi_inst : spi_slave2
    generic map (
        N => 16,
        CPOL => '0'
    )
    port map (
        o_busy => spi_busy,
        i_data_parallel => (others => '0'),
        o_data_parallel => spi_data,
        i_sclk => i_spi_clk,
        i_ss => i_spi_ss_n,
        i_mosi => i_spi_mosi,
        o_miso => o_spi_miso
    );

    -- PWM instances
    pwm_inst_0 : entity work.pwm(arch)
    generic map (
        CLK_FREQ => 48e6,
        RESOLUTION => RESOLUTION  -- 181 degrees: from +90 (180) to -90 (0); 0 (90) is midpoint
    )
    port map (
        i_clk => clk_48mhz,
        i_enable => not reset,
        i_position => pwm_0_pos,
        o_pwm => o_servo(0)
    );
    
    pwm_inst_1: entity work.pwm(arch)
    generic map (
        CLK_FREQ => 48e6,
        RESOLUTION => RESOLUTION
    )
    port map (
        i_clk => clk_48mhz,
        i_enable => not reset,
        i_position => pwm_1_pos,
        o_pwm => o_servo(1)
    );

    set_pos : process(spi_dr, spi_busy, spi_data)
        variable tmp0 : std_logic_vector(7 downto 0);
        variable tmp1 : std_logic_vector(7 downto 0);
        variable pos0 : integer range 0 to 255;
        variable pos1 : integer range 0 to 255;
    begin
        -- if spi_dr = '1' then
        if falling_edge(spi_busy) then
            tmp0 := spi_data(15 downto 8);
            pos0 := to_integer(unsigned(tmp0));
            if pos0 > RESOLUTION then
                pos0 := RESOLUTION;
            end if;
            
            tmp1 := spi_data(7 downto 0);
            pos1 := to_integer(unsigned(tmp1));
            if pos1 > RESOLUTION then
                pos1 := RESOLUTION;
            end if;
            
            pwm_0_pos <= pos0;
            pwm_1_pos <= pos1;
        end if;
    end process;

    o_ready <= not reset;
    o_leds(0) <= spi_dr;
    o_leds(1) <= clk_locked;
    
end architecture arch;