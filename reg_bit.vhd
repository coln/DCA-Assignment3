library ieee;
use ieee.std_logic_1164.all;

-- Register for a single-bit input and output
entity reg_bit is
	generic (
		WIDTH : positive := 32
	);
	port (
		clk : in std_logic;
		D : in std_logic;
		Q : out std_logic;
		wr : in std_logic;
		clr : in std_logic
	);
end entity;

architecture arch of reg_bit is
begin

	process(clk, clr)
	begin
		if(clr = '1') then
			Q <= '0';
		elsif(rising_edge(clk)) then
			if(wr = '1') then
				Q <= D;
			end if;
		end if;
	end process;

end arch;