library ieee;
use ieee.std_logic_1164.all;

-- Simple 4-bit Carry Look-Ahead Adder
entity cla4 is
	port (
		in0 : in std_logic_vector(3 downto 0);
		in1 : in std_logic_vector(3 downto 0);
		sum : out std_logic_vector(3 downto 0);
		cin : in std_logic;
		cout : out std_logic
	);
end entity;

architecture arch of cla4 is
	signal g : std_logic_vector(3 downto 0);
	signal p : std_logic_vector(3 downto 0);
	signal carry : std_logic_vector(4 downto 0);
begin
	
	-- Generate and propagate
	-- g = a and b
	g(3) <= in0(3) and in1(3);
	g(2) <= in0(2) and in1(2);
	g(1) <= in0(1) and in1(1);
	g(0) <= in0(0) and in1(0);
	-- p = a xor b 
	p(3) <= in0(3) xor in1(3);
	p(2) <= in0(2) xor in1(2);
	p(1) <= in0(1) xor in1(1);
	p(0) <= in0(0) xor in1(0);
	
	
	-- Calculate carry bits
	-- c1 = g0 + p0*c0
	-- c2 = g1 + p1*g0 + p1*p0*c0
	-- c3 = g2 + p2*g1 + p2*p1*g0 + p2*p1*p0*c0
	-- c4 = g3 + p3*g2 + p3*p2*g1 + p3*p2*p1*g0 + p3*p2*p1*p0*c0
	carry(0) <= cin;
	carry(1) <= g(0) or (p(0) and carry(0));
	carry(2) <= g(1) or (p(1) and g(0)) or (p(1) and p(0) and carry(0));
	carry(3) <= g(2) or (p(2) and g(1)) or (p(2) and p(1) and g(0))
				or (p(2) and p(1) and p(0) and carry(0));
	carry(4) <= g(3) or (p(3) and g(2)) or (p(3) and p(2) and g(1))
				or (p(3) and p(2) and p(1) and g(0))
				or (p(3) and p(2) and p(1) and p(0) and carry(0));
	
	
	-- Calculate final sum
	sum <= p xor carry(3 downto 0);
	cout <= carry(4);
	
end arch;