library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pwm is
    generic (
        CLK_FREQ : integer := 10000000          -- Clock frequency
        RESOLUTION : integer := 256             -- PWM resolution (8-bit)
        PWM_FREQ : integer := 50;               -- PWM frequency in Hz. 50 is 20 ms period
        MIN_PULSE_WIDTH_US : integer range 1 to 1 / PWM_FREQ * 1000000 := 1000;   -- Minimum pulse width in microseconds
        MAX_PULSE_WIDTH_US : integer range 1 to 1 / PWM_FREQ * 1000000 := 2000   -- Maximum pulse width in microseconds
    );
    port (
        i_clk : in std_logic;
        i_enable : in std_logic;
        i_duty_cycle : in integer range 0 to resolution - 1; -- Duty cycle input
        o_pwm : out std_logic
    );
end pwm;

architecture behavioral of pwm is
    constant CLK_DIVISOR : integer := (CLK_FREQ / PWM_FREQ) - 1; -- TODO: Multiply by resolution here?
    signal pwm_clk_enable : std_logic;
    signal pwm_counter : integer range 0 to CLK_DIVISOR - 1 := 0;

begin
    pwm_clk : process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            if(pwm_counter = CLK_DIVISOR) then
                pwm_counter <= 0;
                pwm_clk_enable <= '1';
            else
                pwm_clk_enable <= '0';
                pwm_counter <= pwm_counter + 1;
            end if;
        end if;
    end process pwm_clk;

    pwm_output : process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            if(i_enable = '1' and pwm_clk_enable = '1') then
                -- TODO: Calculate required pwm_counter for 1/0 based on duty cycle and resolution
                if(i_duty_cycle >= MIN_PULSE_WIDTH_US and i_duty_cycle <= MAX_PULSE_WIDTH_US) then
                    o_pwm <= '1' when pwm_counter < (i_duty_cycle * CLK_DIVISOR / RESOLUTION) else '0';
                else
                    o_pwm <= '0'; -- Out of bounds duty cycle
                end if;
            else
                o_pwm <= '0'; -- PWM disabled
            end if;
        end if;
    end process pwm_output;

end behavioral;
