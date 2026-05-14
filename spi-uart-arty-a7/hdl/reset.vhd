library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Automatic reset generation - activates when system is programmed and ready
-- Reset sequence:
-- 1. FPGA configuration completes (GSR released automatically)
-- 2. Clock manager locks to stable frequency
-- 3. 3-stage synchronizer releases reset cleanly
-- 4. System starts normal operation
-- Note: The `reset_sync` signal could also be a variable in the reset process, 
--    but it is recommended to use signal for visibility in simulation, synthesis clarity (flip-flop) 
--    and it is (apparently) standard practice for a reset sync to be implemented as a signal.
--
-- Connections:
-- - i_clk: Input clock signal
-- - i_clk_locked: Input clock locked signal, active high
-- - i_reset: Input reset signal, active high
-- - o_reset: Output reset signal, active high
--

entity reset is
port(
    i_clk : in std_logic;
    i_clk_locked : in std_logic;    -- Input clock locked signal, active high
    i_reset : in std_logic;         -- Input reset signal, active high
    o_reset : out std_logic         -- Output reset signal, active high
);
end entity reset;

architecture arch of reset is
    signal reset_sync : std_logic_vector(2 downto 0) := "000";
begin
    reset : process(i_clk, i_clk_locked, i_reset)
    begin
        if (i_clk_locked = '0' or i_reset = '1') then
            -- Keep in reset until clock manager is locked and stable and external reset is de-asserted
            reset_sync <= "000";
            o_reset <= '1';
        elsif rising_edge(i_clk) then
            -- Release reset after 3 clock cycles
            reset_sync <= reset_sync(1 downto 0) & '1';
            o_reset <= not reset_sync(2);
        end if;
    end process reset;
end architecture arch;