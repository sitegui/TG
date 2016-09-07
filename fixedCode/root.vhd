library ieee;
use ieee.std_logic_1164.all;

-- key(0) : send
-- ledr(0) : authorized

entity root is
	port (
		key: in std_logic_vector(0 downto 0);
		clock_50: in std_logic;
		ledr: out std_logic_vector(0 downto 0)
	);
end;

architecture rtl of root is
	constant code: std_logic_vector(9 downto 0) := "1110111011";
	signal tx, authorized: std_logic;
begin
	-- Represent a transmitter
	peripheral: entity work.PWM_TX
		generic map (N => 10)
		port map (
			data => code,
			clk => clock_50,
			activate => key(0),
			tx => tx
		);
	
	-- Represent a receiver
	central: entity work.fixedCode
		generic map (N => 10)
		port map (
			code => code,
			intake => tx,
			clk => clock_50,
			authorized => authorized
		);
	
	process (authorized) is
	begin
		if authorized then
			ledr(0) <= '1';
		end if;
	end process;
end architecture;