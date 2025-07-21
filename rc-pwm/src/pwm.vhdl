library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm is
    generic (
        CLK_FREQ : integer := 10000000;   -- Input clock frequency (Hz)
        RESOLUTION : integer := 256;      -- PWM resolution (8-bit)
        PWM_FREQ : integer := 50;         -- PWM frequency (Hz). 50 is 20 ms period
        MIN_PULSE_WIDTH_US : integer range 1 to 1000000 / PWM_FREQ := 1000;   -- Minimum pulse width in microseconds
        MAX_PULSE_WIDTH_US : integer range 1 to 1000000 / PWM_FREQ := 2000   -- Maximum pulse width in microseconds
    );
    port (
        i_clk : in std_logic;
        i_enable : in std_logic;
        i_duty_cycle : in integer range 0 to RESOLUTION - 1; -- Duty cycle input
        o_pwm : out std_logic
    );
end pwm;

architecture behavioral of pwm is
    constant CLK_DIVISOR : integer := (CLK_FREQ / PWM_FREQ) / RESOLUTION - 1; --FIXME: Probably not use RESOLUTION here to account for min/max pulse width
    signal pwm_clk_enable : std_logic;
    signal pwm_clk_counter : integer range 0 to CLK_DIVISOR - 1 := 0;
    signal pwm_counter : integer range 0 to RESOLUTION - 1 := 0;

begin
    pwm_clk : process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            if(pwm_clk_counter = CLK_DIVISOR) then
                pwm_clk_counter <= 0;
                pwm_clk_enable <= '1';
            else
                pwm_clk_enable <= '0';
                pwm_clk_counter <= pwm_clk_counter + 1;
            end if;
        end if;
    end process pwm_clk;

    pwm_output : process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            if(i_enable = '1' and pwm_clk_enable = '1') then
                -- FIXME: Now duty_cycle is for the entire period not taking min/max pulse width into account
                o_pwm <= '1' when pwm_counter < i_duty_cycle else '0';
                if(pwm_counter = RESOLUTION - 1) then
                    pwm_counter <= 0; -- Reset counter after reaching resolution
                else
                    pwm_counter <= pwm_counter + 1;
                end if;
            end if;
        end if;
    end process pwm_output;

end behavioral;
