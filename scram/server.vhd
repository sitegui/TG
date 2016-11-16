library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Implement a server in a SCRAM scheme
-- This is sample implementation with support for only one device
entity server is
	generic (
		-- Client key hashed
		HASHED_KEY_C: std_logic_vector(0 to 159) := x"3ab449876b5245d3c70671fb463531002a70ae4e";
		-- Seed for PRNG (must be random)
		SEED: std_logic_vector(0 to 159) := x"eee103ee0886b420de356c3d0f6346738dd98761";
		-- Device serial
		SERIAL: std_logic_vector(0 to 31) := x"390415b9";
		-- Max number of clock cycles to wait for an answer
		-- from the client
		RX_TIMEOUT: positive := 50000
	);
	port (
		i_clk: in std_logic;
		-- RX
		i_rx: in std_logic;
		-- TX
		o_tx: out std_logic;
		-- Rise for 1 clock cycle when receives a message
		o_received: out std_logic;
		-- Rise for 1 clock cycle when completes authorization
		o_valid: out std_logic;
		-- Associated data transfered
		-- Written to when o_valid turns '1'
		o_data: out std_logic_vector(0 to 7)
	);
end;

architecture rtl of server is
	type t_state is (
		rx1, -- waiting client first message
		wait_nonce, -- waiting for PRNG
		tx, -- transmitting server first message (serial | nonce_c | data)
		rx2, -- waiting for client last message. May timeout
		check1, -- waiting for HMAC over auth
		check2 -- waiting for SHA1 over key_c
	);
	signal state: t_state := rx1;
	signal nonce_c: std_logic_vector(0 to 39);
	signal key_sha1_start: std_logic;
	signal data: std_logic_vector(0 to 7);
	signal proof: std_logic_vector(0 to 159);
	
	-- SHA1
	type t_sha1_sel is (key, prng, hmac);
	signal sha1_sel: t_sha1_sel;
	signal sha1_data1, sha1_hash: std_logic_vector(0 to 159);
	signal sha1_data2: std_logic_vector(0 to 511);
	signal sha1_mode, sha1_start, sha1_busy: std_logic;
	
	-- PRNG
	signal prng_start, prng_busy, prng_sha1_start: std_logic;
	signal nonce_s: std_logic_vector(0 to 39);
	signal prng_sha1_data: std_logic_vector(0 to 159);
	
	-- TX
	signal tx_data: std_logic_vector(0 to 79);
	signal tx_start, tx_busy: std_logic;
	
	-- RX
	signal rx_data: std_logic_vector(0 to 239);
	signal rx_ready: std_logic;
	signal rx_timer: natural range 0 to RX_TIMEOUT;
	
	-- HMAC SHA1
	signal hmac_data, hmac_mac, hmac_sha1_data1: std_logic_vector(0 to 159);
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
		o_random => nonce_s,
		o_busy => prng_busy,
		o_sha1_data => prng_sha1_data,
		o_sha1_start => prng_sha1_start,
		i_sha1_hash => sha1_hash,
		i_sha1_busy => sha1_busy
	);
	
	ent_tx: entity work.PWM_TX generic map (
		N => 80
	)
	port map (
		clk => i_clk,
		data => tx_data,
		activate => tx_start,
		tx => o_tx,
		busy => tx_busy
	);
	tx_data <= nonce_c & nonce_s;
	
	ent_rx: entity work.PWM_RX generic map (
		N => 240
	)
	port map (
		clk => i_clk,
		rx => i_rx,
		data => rx_data,
		data_ready => rx_ready
	);
	o_received <= rx_ready;
	
	ent_hmac: entity work.HMAC_SHA1 port map (
		i_clk => i_clk,
		i_key => HASHED_KEY_C,
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
	hmac_data <= SERIAL & nonce_c & nonce_s & data & (120 to 159 => '0');
	
	process (all) is
	begin
		if rising_edge(i_clk) then
			case state is
			when rx1 =>
				-- Wait for client first message
				o_valid <= '0';
				if rx_ready then
					-- Extract info from frame
					if rx_data(0 to 31) /= SERIAL then
						-- ERROR: unknown serial
						state <= rx1;
					elsif rx_data(80 to 239) /= (80 to 239 => '0') then
						-- ERROR: invalid padding
						state <= rx1;
					else
						nonce_c <= rx_data(32 to 71);
						data <= rx_data(72 to 79);
					
						-- Configure PRNG to generate random value
						-- The result will be used as nonce
						sha1_sel <= prng;
						prng_start <= '1';
						
						state <= wait_nonce;
					end if;
				end if;
			when wait_nonce =>
				-- Wait for PRNG
				prng_start <= '0';
				if not prng_start and not prng_busy then
					-- Configure TX to send first frame:
					-- nonce_c:40 | nonce_s:40
					tx_start <= '1';
					
					state <= tx;
				end if;
			when tx =>
				-- Wait transmission
				tx_start <= '0';
				if not tx_start and not tx_busy then
					-- Set receiver timeout
					rx_timer <= RX_TIMEOUT;
					state <= rx2;
				end if;
			when rx2 =>
				-- Wait server answer
				if rx_timer = 1 then
					-- ERROR: timeout
					state <= rx1;
				elsif rx_ready then
					-- Got answer:
					-- nonce_c:40 | nonce_s:40 | proof:160
					if rx_data(0 to 39) /= nonce_c then
						-- ERROR: client nonce does not match
						state <= rx1;
					elsif rx_data(40 to 79) /= nonce_s then
						-- ERROR: server nonce does not match
						state <= rx1;
					else
						-- Start checking client proof
						proof <= rx_data(80 to 239);
						hmac_start <= '1';
						sha1_sel <= hmac;
						
						state <= check1;
					end if;
				end if;
				rx_timer <= rx_timer - 1;
			when check1 =>
				-- Wait for HMAC
				hmac_start <= '0';
				if not hmac_start and not hmac_busy then
					-- Get hashed key to compare to stored value
					key_sha1_start <= '1';
					sha1_sel <= key;
					
					state <= check2;
				end if;
			when check2 =>
				-- Wait for SHA1
				key_sha1_start <= '0';
				if not key_sha1_start and not sha1_busy then
					-- Check if hashed key_c matches
					if sha1_hash = HASHED_KEY_C then
						o_valid <= '1';
						o_data <= data;
					end if;
					
					state <= rx1;
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
			sha1_data1 <= hmac_mac xor proof;
			sha1_start <= key_sha1_start;
			sha1_data2 <= (others => '0');
		when prng =>
			sha1_mode <= '0';
			sha1_data1 <= prng_sha1_data;
			sha1_start <= prng_sha1_start;
			sha1_data2 <= (others => '0');
		when hmac =>
			sha1_mode <= '1';
			sha1_data1 <= hmac_sha1_data1;
			sha1_start <= hmac_sha1_start;
			sha1_data2 <= hmac_sha1_data2;
		end case;
	end process;
end architecture;