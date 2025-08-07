library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity clock is
port(
    i_clk : in std_logic;          -- Input clock signal
    i_rst : in std_logic;          -- Input reset signal
    o_48mhz_clk : out std_logic;   -- Output clock signal at 48 MHz
    o_clk_locked : out std_logic   -- Output clock locked signal, active high
);
end entity clock;

architecture arch of clock is
    signal clkfb : std_logic;
begin
    -- Clock Manager (MMCM) for generating 48Hz from 12 MHz system clock
    mmcme2_inst : MMCME2_BASE
    generic map (
        clkfbout_mult_f => 64.0,    -- 12 * 64 = 768 MH
        clkin1_period => 83.333,    -- 12 MHz = 83.333 ns period
        clkout0_divide_f => 16.0    -- 768 MHz / 16 = 48 MHz
    )
    port map (
        clkout0 => o_48mhz_clk, -- Output: 48 MHz
        clkfbout => clkfb,
        clkfbin => clkfb,
        clkin1 => i_clk,        -- Input: 12 MHz
        pwrdwn => '0',          -- Always powered on
        rst => i_rst,
        locked => clk_locked    -- Output: '1' when clock is locked
    );

end architecture arch;