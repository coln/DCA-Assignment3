library ieee;
use ieee.std_logic_1164.all;
use work.lib.all;

entity mips_single_tb is
end entity;

architecture arch of mips_single_tb is
	constant WIDTH : positive := 32;
	signal done : std_logic := '0';
	signal clk : std_logic := '0';
	signal notclk : std_logic := '1';
	signal rst : std_logic := '0';
	signal pc : std_logic_vector(WIDTH-1 downto 0);
	
	signal immediate : std_logic_vector(WIDTH-1 downto 0);
	signal jump_address : std_logic_vector(25 downto 0);
	signal jump : std_logic := '0';
	signal branch : std_logic := '0';
	signal zero : std_logic := '0';
	
begin

	clk <= not clk and not done after 10 ns;
	notclk <= not clk;
	
	U_PC : entity work.program_counter
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => notclk,
			rst => rst,
			immediate => immediate,
			jump_address => jump_address,
			branch => branch,
			jump => jump,
			zero => zero,
			pc => pc
		);
		
	process
	begin
		rst <= '1';
		wait for 25 ns;
		rst <= '0';
		
		wait for 100 ns;
		
		-- Try branching
		immediate <= x"00001717";
		br <= '1';
		zero <= '1';
		wait for 20 ns;
		
		br <= '0';
		zero <= '0';
		wait for 50 ns;
		
		-- Try jumping
		jump_address <= x"012345" & "11";
		jump <= '1';
		wait for 20 ns;
		
		jump <= '0';
		wait for 50 ns;
		
		done <= '1';
		wait;
	end process;
	
end arch;