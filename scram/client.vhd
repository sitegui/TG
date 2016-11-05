library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Implement a client in a SCRAM scheme
-- 
entity client is
	generic (
		-- Client key (must be random)
		KEY_C: std_logic_vector(0 to 159);
		-- Seed for PRNG (must be random)
		SEED: std_logic_vector(0 to 159);
		-- Device serial (must be unique)
		SERIAL: std_logic_vector(0 to 31);
		-- Max number of clock cycles to wait for an answer
		-- from the server
		RX_TIMEOUT: natural
	);
	port (
		i_clk: in std_logic;
		-- Associated data to transfer
		i_data: in std_logic_vector(0 to 7);
		-- Start transmission on '1'
		i_start: in std_logic;
		-- RX
		i_rx: in std_logic;
		-- Transmission is done on fall
		o_busy: out std_logic;
		-- TX
		o_tx: out std_logic
	);
end;

architecture rtl of client is
	type t_state is (
		startup1, -- configure hashing KEY_C
		startup2, -- waiting for hashing KEY_C
		off, -- waiting for i_start
		wait_nonce, -- waiting for PRNG
		tx1, -- transmitting first message (serial | nonce_c | data
		rx, -- waiting to receive answer. may timeout
		proof, -- waiting to compute client proof
		tx2 -- transmitting second message
	);
	signal state: t_state := startup1;
	signal nonce_s: std_logic_vector(0 to 39);
	signal key_sha1_start: std_logic;
	
	-- SHA1
	type t_sha1_sel is (key, prng, hmac);
	signal sha1_sel: t_sha1_sel;
	signal sha1_data1, sha1_hash: std_logic_vector(0 to 159);
	signal sha1_data2: std_logic_vector(0 to 511);
	signal sha1_mode, sha1_start, sha1_busy: std_logic;
	
	-- PRNG
	signal prng_start, prng_busy, prng_sha1_start: std_logic;
	signal nonce_c: std_logic_vector(0 to 39);
	signal prng_sha1_data: std_logic_vector(0 to 159);
	
	-- TX
	signal tx_data: std_logic_vector(0 to 239);
	signal tx_start, tx_busy: std_logic;
	
	-- RX
	signal rx_data: std_logic_vector(0 to 79);
	signal rx_ready: std_logic;
	signal rx_timer: natural range 0 to RX_TIMEOUT;
	
	-- HMAC SHA1
	signal hmac_key, hmac_data, hmac_mac, hmac_sha1_data1: std_logic_vector(0 to 159);
	signal hmac_start, hmac_busy, hmac_sha1_start: std_logic;
	signal hmac_sha1_data2: std_logic_vector(0 to 511);
begin
	ent_sha1: entity work.SHA1 port map (
		i_clk => i_clk,
		i_data1 => sha1_data1,
		i_data2 => sha1_data2,
		i_mode => sha1_mode,
		i_start => sha1_start,
		o_hash => sha1_hash,
		o_busy => sha1_busy
	);
	
	ent_prng: entity work.SHA1_PRNG generic map (
		N => 40,
		SEED => SEED
	) port map (
		i_clk => i_clk,
		i_start => prng_start,
		o_random => nonce_c,
		o_busy => prng_busy,
		o_sha1_data => prng_sha1_data,
		o_sha1_start => prng_sha1_start,
		i_sha1_hash => sha1_hash,
		i_sha1_busy => sha1_busy
	);
	
	ent_tx: entity work.PWM_TX generic map (
		N => 240
	)
	port map (
		clk => i_clk,
		data => tx_data,
		activate => tx_start,
		tx => o_tx,
		busy => tx_busy
	);
	
	ent_rx: entity work.PWM_RX generic map (
		N => 80
	)
	port map (
		clk => i_clk,
		rx => i_rx,
		data => rx_data,
		data_ready => rx_ready
	);
	
	ent_hmac: entity work.HMAC_SHA1 port map (
		i_clk => i_clk,
		i_key => hmac_key,
		i_data => hmac_data,
		i_start => hmac_start,
		o_mac => hmac_mac,
		o_busy => hmac_busy,
		o_sha1_data1 => hmac_sha1_data1,
		o_sha1_data2 => hmac_sha1_data2,
		o_sha1_start => hmac_sha1_start,
		i_sha1_hash => sha1_hash,
		i_sha1_busy => sha1_busy
	);
	-- proof = key_c xor HMAC(H(key_c), serial | nonce_c | nonce_s | data | zeros)
	hmac_data(0 to 31) <= SERIAL;
	hmac_data(32 to 71) <= nonce_c;
	hmac_data(72 to 111) <= rx_data(40 to 79);
	hmac_data(112 to 119) <= i_data;
	hmac_data(120 to 159) <= (others => '0');
	
	process (all) is
	begin
		if rising_edge(i_clk) then
			case state is
			when startup1 =>
				-- Hash key
				o_busy <= '1';
				sha1_sel <= key;
				key_sha1_start <= '1';
				state <= startup2;
			when startup2 =>
				-- Wait for hash
				key_sha1_start <= '0';
				if not key_sha1_start and not sha1_busy then
					-- Set as HMAC key
					hmac_key <= sha1_hash;
					state <= off;
				end if;
			when off =>
				-- Wait for i_start
				o_busy <= '0';
				if i_start then
					-- Configure PRNG to generate random value
					-- The result will be used as nonce
					sha1_sel <= prng;
					prng_start <= '1';
					o_busy <= '1';
					
					state <= wait_nonce;
				end if;
			when wait_nonce =>
				-- Wait for PRNG
				prng_start <= '0';
				if not prng_start and not prng_busy then
					-- Configure TX to send first frame:
					-- serial:32 | nonce_c:40 | data:8 | zero:160
					tx_data(0 to 31) <= SERIAL;
					tx_data(32 to 71) <= nonce_c;
					tx_data(72 to 79) <= i_data;
					tx_data(80 to 239) <= (others => '0');
					tx_start <= '1';
					
					state <= tx1;
				end if;
			when tx1 =>
				-- Wait transmission
				tx_start <= '0';
				if not tx_start and not tx_busy then
					-- Set receiver timeout
					rx_timer <= RX_TIMEOUT;
					state <= rx;
				end if;
			when rx =>
				-- Wait server answer
				if rx_timer = 0 then
					-- ERROR: timeout
					state <= off;
				elsif rx_ready then
					-- Got answer:
					-- nonce_c:40 | nonce_s:40
					if rx_data(0 to 39) /= nonce_c then
						-- ERROR: client nonce does not match
						state <= off;
					else
						-- Start computation of client proof:
						nonce_s <= rx_data(40 to 79);
						hmac_start <= '1';
						sha1_sel <= hmac;
						
						state <= proof;
					end if;
				end if;
				rx_timer <= rx_timer - 1;
			when proof =>
				-- Wait for HMAC
				hmac_start <= '0';
				if not hmac_start and not hmac_busy then
					-- Configure TX to send second frame:
					-- nonce_c:40 | nonce_s:40 | proof:160
					tx_data(0 to 39) <= nonce_c;
					tx_data(40 to 79) <= nonce_s;
					tx_data(80 to 239) <= KEY_C xor hmac_mac;
					tx_start <= '1';
					
					state <= tx2;
				end if;
			when tx2 =>
				-- Wait transmission
				tx_start <= '0';
				if not tx_start and not tx_busy then
					state <= off;
				end if;
			end case;
		end if;
	end process;
	
	-- MUX for SHA1
	process (all) is
	begin
		case sha1_sel is
		when key =>
			sha1_mode <= '0';
			sha1_data1 <= KEY_C;
			sha1_start <= key_sha1_start;
		when prng =>
			sha1_mode <= '0';
			sha1_data1 <= prng_sha1_data;
			sha1_start <= prng_sha1_start;
		when hmac =>
			sha1_mode <= '1';
			sha1_data1 <= hmac_sha1_data1;
			sha1_data2 <= hmac_sha1_data2;
			sha1_start <= hmac_sha1_start;
		end case;
	end process;
end architecture;