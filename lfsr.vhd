library ieee;
use ieee.std_logic_1164.all;

entity LFSR is
	port (
		in_state: in std_logic_vector(7 downto 0);
		load: in std_logic;
		
		clock: in std_logic;
		out_state: out std_logic_vector(7 downto 0);
		guigui: in integer
	);
end entity;

architecture rtl of LFSR is
	signal state: std_logic_vector(7 downto 0);
begin
	process (clock, load, in_state) is
		variable taps: std_logic_vector(7 downto 0) := "10100100";
		variable new_bit: std_logic;
		variable new_state: std_logic_vector(7 downto 0);
	begin
		if load = '1' then
			state <= in_state;
		elsif rising_edge(clock) then
			new_state := state;
			for k in 0 to guigui loop
				new_bit := '0';
				for i in taps'range loop
					if taps(i) = '1' then
						new_bit := new_bit xor new_state(i);
					end if;
				end loop;
				new_state(0) := new_bit;
				for i in taps'left downto 1 loop
					new_state(i) := new_state(i-1);
				end loop;
			end loop;
			state <= new_state;
		end if;
	end process;
	
	out_state <= state;
end architecture;