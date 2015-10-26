library ieee;
use ieee.std_logic_1164.all;

entity reg is
	generic (
		WIDTH : positive := 32
	);
	port (
		clk : in std_logic;
		D : in std_logic_vector(WIDTH-1 downto 0);
		Q : out std_logic_vector(WIDTH-1 downto 0);
		wr : in std_logic;
		clr : in std_logic
	);
end entity;

architecture arch of reg is
begin

	process(clk, clr)
	begin
		if(clr = '1') then
			Q <= (others => '0');
		elsif(rising_edge(clk)) then
			if(wr = '1') then
				Q <= D;
			end if;
		end if;
	end process;

end arch;