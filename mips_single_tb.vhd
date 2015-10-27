library ieee;
use ieee.std_logic_1164.all;

entity mips_single_tb is
end entity;

architecture arch of mips_single_tb is
	constant WIDTH : positive := 32;
	signal done : std_logic := '0';
	signal clk : std_logic := '0';
	signal rst : std_logic := '0';
begin

	clk <= not clk and not done after 10 ns;
	
	U_MIPS_SINGLE : entity work.mips_single
		port map (
			clk => clk,
			rst => rst
		);
	
	process
	begin
		rst <= '1';
		wait for 25 ns;
		rst <= '0';
		
		wait for 200 ns;
		
		done <= '1';
		wait;
	end process;
	
end arch;