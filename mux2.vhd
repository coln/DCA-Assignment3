library ieee;
use ieee.std_logic_1164.all;
use work.lib.all;

-- 2-to-1 generic data width multiplexer
entity mux2 is
	generic (
		WIDTH : positive := 32
	);
	port (
		sel : in std_logic;
		in0 : in std_logic_vector(WIDTH-1 downto 0);
		in1 : in std_logic_vector(WIDTH-1 downto 0);
		output : out std_logic_vector(WIDTH-1 downto 0)
	);
end mux2;

architecture arch of mux2 is
begin
	with sel select
		output <= in0 when '0',
				  in1 when others;
end arch;
