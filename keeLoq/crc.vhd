library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Calculate the cyclic redundancy check code
entity crc is
	generic (N: natural);
	port (
		i_data: in std_logic_vector(N-1 downto 0);
		o_crc: out std_logic_vector(1 downto 0)
	);
end entity;

architecture rtl of crc is
	signal crc0, crc1: std_logic_vector(N downto 0);
begin
	crc0(0) <= '0';
	crc1(0) <= '0';
	cycle: for i in 0 to N-1 generate
		crc1(i + 1) <= crc0(i) xor i_data(i);
		crc0(i + 1) <= crc1(i + 1) xor crc1(i);
	end generate cycle;
	o_crc <= crc1(N) & crc0(N);
end architecture;