library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Extends a WIDHT_IN-bit to WIDTH_OUT-bit
-- Signed/unsigned chosen via "is_signed"
entity extender is
	generic (
		WIDTH_IN : positive := 16;
		WIDTH_OUT : positive := 32
	);
	port (
		in0 : in std_logic_vector(WIDTH_IN-1 downto 0);
		out0 : out std_logic_vector(WIDTH_OUT-1 downto 0);
		is_signed : in std_logic
	);
end entity;

architecture arch of extender is
begin
	
	with is_signed select
		out0 <= std_logic_vector(resize(unsigned(in0), out0'length)) when '0',
				std_logic_vector(resize(signed(in0), out0'length)) when others;
	
end arch;