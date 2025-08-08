library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- This VHDL code implements a PWM (Pulse Width Modulation) generator for RC type servos.
-- These servos typically require a PWM signal with a frequency of 50 Hz (20 ms period),
-- where the pulse width can vary between 1000 us and 2000 us with 1500 us being center position.
-- 
-- A 'position' input is used to control the pulse width, where 0 corresponds to the minimum pulse width (1000 us)
-- and the maximum value corresponds to the maximum pulse width (2000 us).
--
-- All changes (also enable) are synchronous to the input clock.
--
-- Configuration (generic) parameters:
-- - CLK_FREQ: Input clock frequency in Hz. This must be at least 1 MHz. Defaults to 10 MHz.
-- - RESOLUTION: Position resolution. Defaults to 256 with 0 = min, 128 = midpoint, 256 = max.
--               It is recommended to use an even number in order to be able to use the midpoint exactly.
-- - PWM_FREQ: PWM frequency in Hz. Defaults to 50 Hz for a 20 ms period for standard servos.
-- - MIN_PULSE_WIDTH_US: Minimum pulse width in microseconds. Defaults to 1000 us. Also known as "endpoint".
-- - MAX_PULSE_WIDTH_US: Maximum pulse width in microseconds. Defaults to 2000 us. Also known as "endpoint".
--
-- Port description:
-- - i_clk: Input clock signal. Frequency must match CLK_FREQ.
-- - i_enable: Enable signal to activate PWM output. If '0', PWM output is low.
-- - i_position: Input position value ranging from 0 to RESOLUTION, controlling the pulse width.
-- - o_pwm: Output PWM signal.
--

entity pwm is
    generic (
        CLK_FREQ : integer range 1e6 to integer'HIGH := 10e6;   -- Input clock frequency (Hz) must be at least 1 MHz
        RESOLUTION : integer := 256;      -- Position resolution (257 steps, 0 = min, 128 = midpoint, 256 = max)
        PWM_FREQ : integer := 50;         -- PWM frequency (Hz). 50 is 20 ms period
        MIN_PULSE_WIDTH_US : integer range 1 to (1e6 / PWM_FREQ) := 1000;   -- Minimum pulse width in microseconds
        MAX_PULSE_WIDTH_US : integer range 1 to (1e6 / PWM_FREQ) := 2000    -- Maximum pulse width in microseconds
    );
    port (
        i_clk : in std_logic;
        i_enable : in std_logic;
        i_position : in integer range 0 to RESOLUTION; -- Position input. 0 is min pulse width, RESOLUTION is max pulse width.
        o_pwm : out std_logic
    );
end entity pwm;

architecture arch of pwm is
    -- Pre-calculated constants derived from generic parameters
    constant TICKS_PER_US : integer := CLK_FREQ / 1e6; -- Clock cycles per microsecond
    constant MIN_PULSE_TICKS : integer := (MIN_PULSE_WIDTH_US * TICKS_PER_US);
    constant MAX_PULSE_TICKS : integer := (MAX_PULSE_WIDTH_US * TICKS_PER_US);
    constant TICKS_PER_POSITION_STEP : integer := (MAX_PULSE_TICKS - MIN_PULSE_TICKS) / RESOLUTION;
    constant TICKS_PER_PERIOD : integer := CLK_FREQ / PWM_FREQ; -- Clock cycles per PWM period

    signal clk_counter : integer range 0 to TICKS_PER_PERIOD - 1 := 0;

begin
    pwm_output : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_enable = '1' then
                -- Increment/wrap around clock counter each PWM period
                if clk_counter = TICKS_PER_PERIOD - 1 then
                    clk_counter <= 0;
                else
                    clk_counter <= clk_counter + 1;
                end if;

                o_pwm <= '1' when clk_counter < (i_position * TICKS_PER_POSITION_STEP) + MIN_PULSE_TICKS else '0';
            end if;
        end if;
    end process pwm_output;
end architecture arch;
