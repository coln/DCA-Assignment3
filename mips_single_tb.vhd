library ieee;
use ieee.std_logic_1164.all;
use work.lib.all;

entity mips_single_tb is
end entity;

architecture arch of mips_single_tb is
	constant WIDTH : positive := 32;
	signal done : std_logic := '0';
	signal clk : std_logic := '0';
	signal mem_clk : std_logic := '0';
	signal rst : std_logic := '0';
begin
	
	-- Generate clk and mem_clk signals (50MHz and 150MHz respectively)
	-- Note: mem_clk has a 5ns phase shift to allow for clk rise/fall time
	clk_gen(clk, done, 50.0E6);
	clk_gen(mem_clk, done, 100.0E6, 5 ns);
	
	U_MIPS_SINGLE : entity work.mips_single
		port map (
			clk => clk,
			mem_clk => mem_clk,
			rst => rst
		);
	
	process
	begin
		rst <= '1';
		wait for 30 ns;
		rst <= '0';
		
		wait for 450 ns;
		
		done <= '1';
		wait;
	end process;
	
end arch;