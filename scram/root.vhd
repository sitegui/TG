library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- key(0) : send
-- ledr(0) : received (holded for 1s)
-- ledr(1) : passed (holded for 1s)

entity root is
	port (
		key: in std_logic_vector(0 downto 0);
		clock_50: in std_logic;
		ledr: out std_logic_vector(1 downto 0)
	);
end;

architecture rtl of root is
	signal rx_tx1, rx_tx2, received, authorized: std_logic;
	signal counter: natural;
begin
	ent_client: entity work.client port map (
		i_clk => clock_50,
		i_data => x"d4",
		i_start => key(0),
		i_rx => rx_tx1,
		o_busy => open,
		o_tx => rx_tx2
	);
	
	ent_server: entity work.server port map (
		i_clk => clock_50,
		i_rx => rx_tx2,
		o_tx => rx_tx1,
		o_received => received,
		o_valid => authorized,
		o_data => open
	);
	
	process (all) is
	begin
		if rising_edge(clock_50) then
			if received then
				ledr(0) <= '1';
				counter <= 0;
			elsif authorized then
				ledr(1) <= '1';
				counter <= 0;
			elsif counter = 50e6 then
				ledr(0) <= '0';
				ledr(1) <= '0';
				counter <= 0;
			else
				counter <= counter + 1;
			end if;
		end if;
	end process;
end architecture;