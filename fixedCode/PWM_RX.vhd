library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Receive a fixed number of bits using PWM format
--
-- The transmission is composed of four stages:
-- 1) preamble: 16 highs alternating with 15 lows (high, low, ..., low, high)
-- 2) header: 8 lows
-- 3) payload: 3 pulses per bit: (high, high, low) for a 0, (high, low, low) for a 1
-- 4) guard time: 10 lows
entity PWM_RX is
	generic (
		N: positive
	);
	port (
		rx: in std_logic;
		-- Each clock cycle corresponds to a pulse
		clk: in std_logic;
		-- All bits received, from first (0) to last (N-1)
		data: out std_logic_vector(N-1 downto 0);
		-- Rise when data is ready to be read and stay high for 1 clock cycle
		data_ready: out std_logic
	);
end;

architecture rtl of PWM_RX is
	type state_t is (
		off,
		possible_preamble0,
		possible_preamble1,
		preamble_high,
		preamble_low,
		header,
		payload0,
		payload1,
		payload2,
		guard
	);
	signal state: state_t := off;
	signal counter: natural range 0 to N;
	signal data_copy: std_logic_vector(N-1 downto 0);
begin
	process (all) is
	begin
		if rising_edge(clk) then
			case state is
				-- Go from 'off' to 'preamble' when sees HLH
				-- Any other starting sequence will bring it back to 'off'
				when off =>
					if rx = '1' then
						state <= possible_preamble0;
					end if;
				when possible_preamble0 =>
					if rx = '1' then
						state <= off;
					else
						state <= possible_preamble1;
					end if;
				when possible_preamble1 =>
					if rx = '1' then
						state <= preamble_high;
					else
						state <= off;
					end if;
				-- Consume as many LH sequences as possible
				when preamble_high =>
					if rx = '1' then
						state <= off;
					else
						state <= preamble_low;
					end if;
				when preamble_low =>
					if rx = '1' then
						state <= preamble_high;
					else
						state <= header;
					end if;
				-- Consume as many L as possible
				when header =>
					if rx = '1' then
						-- Data transmission start
						-- This H was part of the first bit
						state <= payload1;
						counter <= 0;
						data_copy <= (others => '0');
					end if;
				-- Read data
				when payload1 =>
					-- HHL is 0, HLL is 1
					data_copy(counter) <= not rx;
					state <= payload2;
					counter <= counter + 1;
				when payload2 =>
					if rx = '1' and counter /= N then
						state <= payload0;
					else
						state <= guard;
						data <= data_copy;
						data_ready <= '1';
					end if;
				when payload0 =>
					if rx = '1' then
						-- Error
						state <= off;
					else
						state <= payload1;
					end if;
				when guard =>
					state <= off;
					data_ready <= '0';
			end case;
		end if;
	end process;
end architecture;