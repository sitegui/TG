library ieee;
use ieee.std_logic_1164.all;

entity handson is
	port (
		key: in std_logic_vector(3 downto 0);
		ledr: out std_logic_vector(9 downto 0)
	);
end entity;

architecture rtl of handson is
begin
	ledr(0) <= key(0);
end architecture;