library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;
use work.pltbutils_comp_pkg.all;

entity client_test is
end entity;

architecture rtl of client_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	constant SERIAL: std_logic_vector(27 downto 0) := x"2ad820b";
	
	signal i_clk, i_start, o_busy, o_tx: std_logic;
	signal i_qu: std_logic_vector(1 downto 0);
	signal i_btn: std_logic_vector(3 downto 0);	
	
	signal rx_data: std_logic_vector(68 downto 0);
	signal rx_ready: std_logic;
begin
	
	uut: entity work.client generic map (
		SERIAL => SERIAL
	) port map (i_clk, i_qu, i_btn, i_start, o_busy, o_tx);
	
	uut_aux: entity work.PWM_RX generic map (
		N => 69
	) port map (
		rx => o_tx,
		clk => i_clk,
		data => rx_data,
		data_ready => rx_ready
	);
	
	clkgen: pltbutils_clkgen generic map (
		G_PERIOD => 20 ns
	) port map (
		clk_o => i_clk,
		stop_sim_i => pltbs.stop_sim
	);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("Client", "", pltbv, pltbs);
		
		starttest(1, "Activation", pltbv, pltbs);
		i_qu <= "01";
		i_btn <= "0010";
		i_start <= '1';
		waitclks(1, i_clk, pltbv, pltbs, true);
		i_start <= '0';
		check("Busy", o_busy, '1', pltbv, pltbs);
		waitsig(rx_ready, '1', i_clk, pltbv, pltbs);
		check("QU", rx_data(68 downto 67), i_qu, pltbv, pltbs);
		check("BTN", rx_data(63 downto 60), i_btn, pltbv, pltbs);
		check("SERIAL", rx_data(59 downto 32), SERIAL, pltbv, pltbs);
		waitsig(o_busy, '0', i_clk, pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;