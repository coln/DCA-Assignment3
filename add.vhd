library ieee;
use ieee.std_logic_1164.all;

-- Generic width adder using a CLA4 as units
-- Therefore WIDTH must be divisible by 4
entity add is
	generic (
		WIDTH : positive := 32
	);
	port (
		in0 : in std_logic_vector(WIDTH-1 downto 0);
		in1 : in std_logic_vector(WIDTH-1 downto 0);
		sum : out std_logic_vector(WIDTH-1 downto 0);
		cin : in std_logic;
		cout : out std_logic
	);
end entity;

architecture arch of add is
	signal carry : std_logic_vector(WIDTH/4 downto 0);
begin
	
	-- Ripple carry using WIDTH/4 4-bit carry look-ahead adders
	carry(0) <= cin;
	
	U_ADD : for i in 1 to WIDTH/4 generate
		
		U_CLA4 : entity work.cla4
			port map (
				in0 => in0((i * 4) - 1 downto (i - 1) * 4),
				in1 => in1((i * 4) - 1 downto (i - 1) * 4),
				sum => sum((i * 4) - 1 downto (i - 1) * 4),
				cin => carry(i - 1),
				cout => carry(i)
			);
		
	end generate;
	
	cout <= carry(WIDTH/4);
	
end arch;