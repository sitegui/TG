library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Transmit a fixed number of bits using PWM format
-- Once 'activate' is turned on, the transmission will start.
-- It will only stop when '0' and after a whole number of frames has been sent.
--
-- The transmission is composed of four stages:
-- 1) preamble: 16 highs alternating with 15 lows (high, low, ..., low, high)
-- 2) header: 8 lows
-- 3) payload: 3 pulses per bit: (high, high, low) for a 0, (high, low, low) for a 1
-- 4) guard time: 10 lows
entity PWM_TX is
	generic (
		N: positive := 8
	);
	port (
		-- All bits to transmit, from LSB (0) to MSB (N-1)
		data: in std_logic_vector(N-1 downto 0);
		-- Each clock cycle corresponds to a pulse
		clk: in std_logic;
		-- When '1', start transmitting
		activate: in std_logic;
		tx: out std_logic;
		-- '1' while transmittion is happening
		busy: out std_logic
	);
end;

architecture rtl of PWM_TX is
	function MAX(a, b: natural) return natural is
	begin
		if a > b then return a;
		else return b;
		end if;
	end;

	type state_t is (off, preamble, header, payload0, payload1, payload2, guard);
	signal state: state_t := off;
	signal counter: natural range 0 to MAX(31, N-1);
	signal data_copy: std_logic_vector(N-1 downto 0);
begin
	process (all) is
	begin
		if rising_edge(clk) then
			counter <= counter + 1;
			
			if state = off then
				tx <= '0';
				busy <= '0';
				counter <= counter;
				if activate = '1' then
					-- Start
					state <= preamble;
					counter <= 0;
					data_copy <= data;
					busy <= '1';
				end if;
			elsif state = preamble then
				-- Preamble
				if counter mod 2 = 0 then
					tx <= '1';
				else
					tx <= '0';
				end if;
				
				if counter = 30 then
					state <= header;
					counter <= 0;
				end if;
			elsif state = header then
				-- Header
				tx <= '0';
				
				if counter = 7 then
					state <= payload0;
					counter <= 0;
				end if;
			elsif state = payload0 then
				-- Payload 1/3: high
				tx <= '1';
				
				state <= payload1;
				counter <= counter;
			elsif state = payload1 then
				-- Payload 2/3: high/low
				if data_copy(counter) = '0' then
					tx <= '1';
				else
					tx <= '0';
				end if;
				
				state <= payload2;
				counter <= counter;
			elsif state = payload2 then
				-- Payload 3/3: low
				tx <= '0';
				
				if counter = N-1 then
					state <= guard;
					counter <= 0;
				else
					state <= payload0;
				end if;
			elsif state = guard then
				-- Guard
				tx <= '0';
				
				if counter = 9 then
					state <= off;
				end if;
			end if;
		end if;
	end process;
end architecture;