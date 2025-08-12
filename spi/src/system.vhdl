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
    constant RESOLUTION : positive := 180;  -- 181 degrees: from +90 (180) to -90 (0); 0 (90) is midpoint
    
    -- Clock and reset signals
    signal clk_locked : std_logic;
    signal clk_48mhz : std_logic;
    signal reset : std_logic;

    -- SPI signals
    signal spi_dr : std_logic;
    signal spi_data : std_logic_vector(15 downto 0);
    
    -- FIFO signals
    signal fifo_empty : std_logic;

 
    -- Edge detection for spi_dr because we only want to write to FIFO once per spi_dr pulse
    signal spi_dr_prev : std_logic := '0';
    signal spi_dr_pulse : std_logic := '0';

    -- Servo positions
    signal pwm_bits : std_logic_vector(15 downto 0) := "0101101001011010";    -- Data read from FIFO. 
    signal pwm_0_pos : integer range 0 to RESOLUTION := 90;
    signal pwm_1_pos : integer range 0 to RESOLUTION := 90;
    
    -- From IP Sources/IP/fifo_0/Instantiation Template/fifo_0.vho
    COMPONENT fifo_0
      PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC 
      );
    END COMPONENT;
                
begin
    -- Make sure we only have spi_dr_pulse high for one 48 MHz clock cycle
    -- when spi_dr goes high (which might happen unsynchronized to the 48 MHz clock)
    -- so we don't write spi_data to the FIFO more than once.
    edge_detect: process(clk_48mhz)
    begin
        if rising_edge(clk_48mhz) then
            spi_dr_prev <= spi_dr;
            spi_dr_pulse <= spi_dr and not spi_dr_prev;
        end if;
    end process edge_detect;

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
    spi_inst : entity work.spi_slave(arch)
    generic map ( WIDTH => 16 )
    port map (
        sclk => i_spi_clk,
        i_mosi => i_spi_mosi,
        o_miso => o_spi_miso,
        ss_n => i_spi_ss_n,
        i_rst => reset,
        o_dr => spi_dr,
        o_data => spi_data
    );

    -- FIFO instance
    fifo_inst : fifo_0
    port map (
        clk => clk_48mhz,
        rst => reset,
        din => spi_data,
        wr_en => spi_dr_pulse,
        rd_en => not fifo_empty,
        dout => pwm_bits,
        empty => fifo_empty
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
        i_position => 90, -- Hardcoded for now
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
        i_position => 90, -- Hardcoded for now
        o_pwm => o_servo(1)
    );

    set_pwm_pos : process(reset, pwm_bits, fifo_empty)
    begin
        if not reset then
            if rising_edge(fifo_empty) then -- fifo goes to empty again: data has been read
                pwm_0_pos <= to_integer(unsigned(pwm_bits(15 downto 8)));
                pwm_1_pos <= to_integer(unsigned(pwm_bits(7 downto 0)));
            end if;
        end if;
    end process set_pwm_pos;
    
    o_ready <= not reset;
    o_leds(0) <= not fifo_empty;
    o_leds(1) <= clk_locked;
    
end architecture arch;