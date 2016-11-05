library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;

entity client_test is
end entity;

architecture rtl of client_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	signal i_clk, i_start, i_rx, o_busy, o_tx: std_logic;
	signal i_data: std_logic_vector(0 to 7);
	
	signal tx_data: std_logic_vector(0 to 79);
	signal tx_start, tx_busy: std_logic;
	
	signal rx_data: std_logic_vector(0 to 239);
	signal rx_ready: std_logic;
	
	constant SERIAL: std_logic_vector(0 to 31) := x"0fb5f9e9";
begin
	
	uut: entity work.client
		generic map (
			x"8c1794134dd36f9f532d2ca5332facc39b3b523a",
			x"b3d97a8ea2c561aa28a9da20f7b11c5820bb7fd7",
			SERIAL,
			50000
		)
		port map (i_clk, i_data, i_start, i_rx, o_busy, o_tx);
	
	aux_tx: entity work.PWM_TX generic map (
		N => 80
	) port map (
		clk => i_clk,
		data => tx_data,
		activate => tx_start,
		tx => i_rx,
		busy => tx_busy
	);
	
	aux_rx: entity work.PWM_RX generic map (
		N => 240
	) port map (
		clk => i_clk,
		rx => o_tx,
		data => rx_data,
		data_ready => rx_ready
	);
	
	clkgen: entity work.pltbutils_clkgen
		port map (
			clk_o => i_clk,
			clk_n_o => open,
			stop_sim_i => pltbs.stop_sim
		);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("Client", "", pltbv, pltbs);
		
		-- Startup
		starttest("Busy on startup", pltbv, pltbs);
		waitclks(1, i_clk, pltbv, pltbs, true);
		check("Busy", o_busy, '1', pltbv, pltbs);
		waitsig(o_busy, '0', i_clk, pltbv, pltbs, true);
		endtest(pltbv, pltbs);
		
		-- Client first
		starttest("First message", pltbv, pltbs);
		i_data <= x"be";
		i_start <= '1';
		waitclks(1, i_clk, pltbv, pltbs, true);
		i_start <= '0';
		check("Busy", o_busy, '1', pltbv, pltbs);
		waitsig(rx_ready, '1', i_clk, pltbv, pltbs, true);
		check("Frame: serial", rx_data(0 to 31), SERIAL, pltbv, pltbs);
		check("Frame: client nonce", rx_data(32 to 71), x"cb575e218d", pltbv, pltbs);
		check("Frame: data", rx_data(72 to 79), i_data, pltbv, pltbs);
		check("Frame: zeros", rx_data(80 to 239), (0 to 159 => '0'), pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		-- Server first
		starttest("Second message", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		-- Client last
		starttest("Third message", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;