library ieee;
use ieee.std_logic_1164.all;

entity mips_single_tb is
end entity;

architecture arch of mips_single_tb is
	constant WIDTH : positive := 32;
	signal done : std_logic := '0';
	signal clk : std_logic := '0';
	signal mem_clk : std_logic := '0';
	signal rst : std_logic := '0';
begin

	clk <= not clk and not done after 20 ns;
	mem_clk <= not mem_clk and not done after 20 ns;
	
	U_MIPS_SINGLE : entity work.mips_single
		port map (
			clk => clk,
			mem_clk => mem_clk,
			rst => rst
		);
	
	process
	begin
		rst <= '1';
		wait for 55 ns;
		rst <= '0';
		
		wait for 500 ns;
		
		done <= '1';
		wait;
	end process;
	
end arch;