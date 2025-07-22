library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity pwm is
    generic (
        CLK_FREQ : integer range 1e6 to integer'HIGH := 10e6;   -- Input clock frequency (Hz) should be at least 1 MHz
        RESOLUTION : integer := 256;      -- PWM resolution (8-bit)
        PWM_FREQ : integer := 50;         -- PWM frequency (Hz). 50 is 20 ms period
        MIN_PULSE_WIDTH_US : integer range 1 to 1000000 / PWM_FREQ := 1000;   -- Minimum pulse width in microseconds
        MAX_PULSE_WIDTH_US : integer range 1 to 1000000 / PWM_FREQ := 2000   -- Maximum pulse width in microseconds
    );
    port (
        i_clk : in std_logic;
        i_enable : in std_logic;
        i_position : in integer range 0 to RESOLUTION; -- Position input. 0 is min pulse width, RESOLUTION-1 is max pulse width.
        o_pwm : out std_logic
    );
end pwm;

architecture behavioral of pwm is
    constant TICKS_PER_US : integer := CLK_FREQ / 1e6; -- Clock cycles per microsecond
    constant MIN_PULSE_TICKS : integer := (MIN_PULSE_WIDTH_US * TICKS_PER_US);
    constant MAX_PULSE_TICKS : integer := (MAX_PULSE_WIDTH_US * TICKS_PER_US);
    constant TICKS_PER_POSITION_STEP : integer := (MAX_PULSE_TICKS - MIN_PULSE_TICKS) / RESOLUTION;
    constant TICKS_PER_PERIOD : integer := CLK_FREQ / PWM_FREQ; -- Clock cycles per PWM period

    signal clk_counter : integer range 0 to TICKS_PER_PERIOD - 1 := 0;

begin
    pwm_output : process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            if(i_enable = '1') then
                if(clk_counter = TICKS_PER_PERIOD - 1) then
                    clk_counter <= 0; -- Reset counter after reaching period
                else
                    clk_counter <= clk_counter + 1; -- Increment counter for next cycle
                end if;

                o_pwm <= '1' when clk_counter < (i_position * TICKS_PER_POSITION_STEP) + MIN_PULSE_TICKS else '0';
            end if;
        end if;
    end process pwm_output;

end behavioral;
