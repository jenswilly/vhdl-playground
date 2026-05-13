-- Usage
--
-- Wire it alongside your existing AXI-Stream data path
--
-- u_crc : crc32_stream
--     port map (
--         clk        => clk,
--         rst        => rst,
--         data_in    => rx_axis_tdata,   -- your AXI-Stream byte
--         data_valid => rx_axis_tvalid,
--         data_last  => rx_axis_tlast,
--         crc_out    => frame_signature,
--         crc_done   => signature_valid
--     );
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crc32_stream is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        -- Streaming input
        data_in    : in  std_logic_vector(7 downto 0);
        data_valid : in  std_logic;   -- pulse high each cycle a byte is valid
        data_last  : in  std_logic;   -- pulse high on last byte of message

        -- Output
        crc_out    : out std_logic_vector(31 downto 0);  -- valid when done=1
        crc_done   : out std_logic
    );
end entity;

architecture rtl of crc32_stream is

    -- CRC-32 polynomial: 0x04C11DB7 (IEEE 802.3), reflected: 0xEDB88320
    -- One-byte update function, fully unrolled into XOR logic
    function crc32_byte(crc : std_logic_vector(31 downto 0);
                        d   : std_logic_vector(7 downto 0))
        return std_logic_vector is
        variable c : std_logic_vector(31 downto 0);
        variable b : std_logic_vector(7 downto 0);
    begin
        -- XOR the low byte of the running CRC with the input byte
        b := crc(7 downto 0) xor d;
        c := crc;

        -- Unrolled reflected CRC-32 polynomial (0xEDB88320)
        -- Each bit of b ripples through the shift register
        -- This is the standard bit-serial unrolling into combinatorial logic
        c(0)  := b(6) xor b(0) xor crc(24) xor crc(30);
        c(1)  := b(7) xor b(6) xor b(1) xor b(0) xor crc(24) xor crc(25) xor crc(30) xor crc(31);
        c(2)  := b(7) xor b(6) xor b(2) xor b(1) xor b(0) xor crc(24) xor crc(25) xor crc(26) xor crc(30) xor crc(31);
        c(3)  := b(7) xor b(3) xor b(2) xor b(1) xor crc(25) xor crc(26) xor crc(27) xor crc(31);
        c(4)  := b(6) xor b(4) xor b(3) xor b(2) xor b(0) xor crc(24) xor crc(26) xor crc(27) xor crc(28) xor crc(30);
        c(5)  := b(7) xor b(6) xor b(5) xor b(4) xor b(3) xor b(1) xor b(0) xor crc(24) xor crc(25) xor crc(27) xor crc(28) xor crc(29) xor crc(30) xor crc(31);
        c(6)  := b(7) xor b(6) xor b(5) xor b(4) xor b(2) xor b(1) xor crc(25) xor crc(26) xor crc(28) xor crc(29) xor crc(30) xor crc(31);
        c(7)  := b(7) xor b(5) xor b(3) xor b(2) xor b(0) xor crc(24) xor crc(26) xor crc(27) xor crc(29) xor crc(31);
        c(8)  := b(4) xor b(3) xor b(1) xor b(0) xor crc(0) xor crc(24) xor crc(25) xor crc(27) xor crc(28);
        c(9)  := b(5) xor b(4) xor b(2) xor b(1) xor crc(1) xor crc(25) xor crc(26) xor crc(28) xor crc(29);
        c(10) := b(5) xor b(3) xor b(2) xor b(0) xor crc(2) xor crc(24) xor crc(26) xor crc(27) xor crc(29);
        c(11) := b(4) xor b(3) xor b(1) xor b(0) xor crc(3) xor crc(24) xor crc(25) xor crc(27) xor crc(28);
        c(12) := b(6) xor b(5) xor b(4) xor b(2) xor b(1) xor b(0) xor crc(4) xor crc(24) xor crc(25) xor crc(26) xor crc(28) xor crc(29) xor crc(30);
        c(13) := b(7) xor b(6) xor b(5) xor b(3) xor b(2) xor b(1) xor crc(5) xor crc(25) xor crc(26) xor crc(27) xor crc(29) xor crc(30) xor crc(31);
        c(14) := b(7) xor b(6) xor b(4) xor b(3) xor b(2) xor crc(6) xor crc(26) xor crc(27) xor crc(28) xor crc(30) xor crc(31);
        c(15) := b(7) xor b(5) xor b(4) xor b(3) xor crc(7) xor crc(27) xor crc(28) xor crc(29) xor crc(31);
        c(16) := b(5) xor b(4) xor b(0) xor crc(8) xor crc(24) xor crc(28) xor crc(29);
        c(17) := b(6) xor b(5) xor b(1) xor crc(9) xor crc(25) xor crc(29) xor crc(30);
        c(18) := b(7) xor b(6) xor b(2) xor crc(10) xor crc(26) xor crc(30) xor crc(31);
        c(19) := b(7) xor b(3) xor crc(11) xor crc(27) xor crc(31);
        c(20) := b(4) xor crc(12) xor crc(28);
        c(21) := b(5) xor crc(13) xor crc(29);
        c(22) := b(0) xor crc(14) xor crc(24);
        c(23) := b(6) xor b(1) xor b(0) xor crc(15) xor crc(24) xor crc(25) xor crc(30);
        c(24) := b(7) xor b(2) xor b(1) xor crc(16) xor crc(25) xor crc(26) xor crc(31);
        c(25) := b(3) xor b(2) xor crc(17) xor crc(26) xor crc(27);
        c(26) := b(6) xor b(4) xor b(3) xor b(0) xor crc(18) xor crc(24) xor crc(27) xor crc(28) xor crc(30);
        c(27) := b(7) xor b(5) xor b(4) xor b(1) xor crc(19) xor crc(25) xor crc(28) xor crc(29) xor crc(31);
        c(28) := b(6) xor b(5) xor b(2) xor crc(20) xor crc(26) xor crc(29) xor crc(30);
        c(29) := b(7) xor b(6) xor b(3) xor crc(21) xor crc(27) xor crc(30) xor crc(31);
        c(30) := b(7) xor b(4) xor crc(22) xor crc(28) xor crc(31);
        c(31) := b(5) xor crc(23) xor crc(29);

        return c;
    end function;

    signal crc_reg  : std_logic_vector(31 downto 0) := x"FFFFFFFF";

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                crc_reg  <= x"FFFFFFFF";   -- standard CRC-32 initialisation
                crc_done <= '0';
                crc_out  <= (others => '0');

            elsif data_valid = '1' then
                crc_reg  <= crc32_byte(crc_reg, data_in);
                crc_done <= '0';

                if data_last = '1' then
                    -- Final XOR with 0xFFFFFFFF is standard for CRC-32
                    crc_out  <= crc32_byte(crc_reg, data_in) xor x"FFFFFFFF";
                    crc_done <= '1';
                    crc_reg  <= x"FFFFFFFF";  -- auto-reset for next message
                end if;
            else
                crc_done <= '0';
            end if;
        end if;
    end process;

end architecture rtl;