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
	constant tx_code: std_logic_vector(9 downto 0) := "1110111011";
	signal tx_rx, code_ready, authorized: std_logic;
	signal rx_code: std_logic_vector(9 downto 0);
begin
	-- Represent a transmitter
	peripheral: entity work.PWM_TX
		generic map (N => 10)
		port map (
			data => tx_code,
			clk => clock_50,
			activate => key(0),
			tx => tx_rx
		);
	
	-- Represent a receiver
	centralRX: entity work.PWM_RX
		generic map (N => 10)
		port map (
			rx => tx_rx,
			clk => clock_50,
			data => rx_code,
			data_ready => code_ready
		);
	
	process (code_ready, rx_code) is
	begin
		if code_ready = '1' and rx_code = tx_code then
			authorized <= '1';
		end if;
	end process;
	
	ledr(0) <= authorized;
end architecture;