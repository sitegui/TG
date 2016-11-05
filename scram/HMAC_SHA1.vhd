library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Get the HMAC of 160 bits using SHA1
entity HMAC_SHA1 is
	port (
		i_clk: in std_logic;
		i_key: in std_logic_vector(0 to 159);
		i_data: in std_logic_vector(0 to 159);
		-- Start generating random bits when '1'
		i_start: in std_logic;
		o_mac: out std_logic_vector(0 to 159);
		-- Operation done on fall
		o_busy: out std_logic := '0';

		-- SHA1 shared ports (must share the same clock)
		o_sha1_data1: out std_logic_vector(0 to 159);
		o_sha1_data2: out std_logic_vector(0 to 511);
		o_sha1_start: out std_logic;
		i_sha1_hash: in std_logic_vector(0 to 159);
		i_sha1_busy: in std_logic
	);
end;

architecture rtl of HMAC_SHA1 is
	type t_state is (off, inner, outer);
	signal state: t_state := off;
	constant inner_pad: std_logic_vector(0 to 511) := x"36363636363636363636363636363636363636363636363636363636363636363636363636363636363636363636363636363636363636363636363636363636";
	constant outer_pad: std_logic_vector(0 to 511) := x"5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c";
begin
	process (all) is
	begin
		if rising_edge(i_clk) then
			case state is
			when off =>
				-- Wait for i_start
				o_busy <= '0';
				if i_start then
					-- Configure inner hashing
					o_busy <= '1';
					o_sha1_data1 <= i_data;
					o_sha1_data2 <= (i_key & (160 to 511 => '0')) xor inner_pad;
					o_sha1_start <= '1';
					
					state <= inner;
				end if;
			when inner =>
				-- Wait for i_sha1_busy
				o_sha1_start <= '0';
				if not o_sha1_start and not i_sha1_busy then
					-- Configure outer hashing
					o_sha1_data1 <= i_sha1_hash;
					o_sha1_data2 <= (i_key & (160 to 511 => '0')) xor outer_pad;
					o_sha1_start <= '1';
					
					state <= outer;
				end if;
			when outer =>
				-- Wait for i_sha1_busy
				o_sha1_start <= '0';
				if not o_sha1_start and not i_sha1_busy then
					-- Done
					o_mac <= i_sha1_hash;
					state <= off;
				end if;
			end case;
		end if;
	end process;
end architecture;