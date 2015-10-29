library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lib.all;

-- MIPS Generic width ALU
--
-- Control signals:
-- bit4 = A inverse
-- bit3 = B inverse
-- bit2/1 = MUX4 select
-- bit0 = Signed (0) or Unsigned (1)
entity alu is
	generic (
		WIDTH : positive := 32
	);
	port (
		-- Inputs A & B
		inA : in std_logic_vector(WIDTH-1 downto 0);
		inB : in std_logic_vector(WIDTH-1 downto 0);
		
		-- Controls, Shift amount (shamt), and shift direction (shdir)
		control : in std_logic_vector(ALU_CONTROL_WIDTH-1 downto 0);
		shiftAmt : in std_logic_vector(RTYPE_SHAMT_WIDTH-1 downto 0);
		shiftDir : in std_logic;
		
		-- ALU Output
		output : out std_logic_vector(WIDTH-1 downto 0);
		carry : out std_logic;
		zero : out std_logic;
		sign : out std_logic;
		overflow : out std_logic
	);
end entity;

architecture arch of alu is
	signal A : std_logic_vector(WIDTH-1 downto 0);
	signal B : std_logic_vector(WIDTH-1 downto 0);
	
	signal logical_and : std_logic_vector(WIDTH-1 downto 0);
	signal logical_or : std_logic_vector(WIDTH-1 downto 0);
	signal add : std_logic_vector(WIDTH downto 0);
	signal set_on_less_than : std_logic_vector(WIDTH-1 downto 0);
	signal shift_output : std_logic_vector(WIDTH-1 downto 0);
	
	signal mux_output : std_logic_vector(WIDTH-1 downto 0);
begin
	
	-- Final output of the ALU using a 4-to-1 mux
	U_MUX4 : entity work.mux4
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => control(2 downto 1),
			in0 => logical_and,
			in1 => logical_or,
			in2 => add(WIDTH-1 downto 0),
			in3 => set_on_less_than,
			output => mux_output
		);
	
	with control select
		output <= shift_output when "00110",
				  mux_output when others;
	
	with control(4) select
		A <= inA when '0',
			 not inA when others;
	
	with control(3) select
		B <= inB when '0',
			 not inB when others;
	
	-- Since the control line is setting A/B inverse
	-- addition and subtraction is the same
	-- A + B = A + B
	-- A - B = A + not(B) + 1
	-- The unsigned() casts are there because we already accounted for sign using
	-- the above method
	add <= std_logic_vector(
				slv2unsigned(A, WIDTH+1)
				+ slv2unsigned(B, WIDTH+1)
				+ logic2unsigned(control(3), WIDTH+1)
			);
	
	-- Sign flags
	process(A, B, control, add)
	begin
		carry <= add(WIDTH);
		sign <= add(WIDTH-1);
		zero <= '0';
		overflow <= '0';
		
		-- Essentially a giant OR of all the bits to check for zero
		if(signed(add(WIDTH-1 downto 0)) = 0) then
			zero <= '1';
		end if;
		
		-- If both input and output signs conflict, overflow
		-- Do not overflow for "unsigned" operations
		if((A(WIDTH-1) = '1' and B(WIDTH-1) = '1' and add(WIDTH-1) = '0')
			or (A(WIDTH-1) = '0' and B(WIDTH-1) = '0' and add(WIDTH-1) = '1'))
		then
			overflow <= '1' and not control(0);
		end if;
	end process;
	
	
	-- Logical NOR is set using the A/B inverse control lines
	logical_and <= A and B;
	logical_or <= A or B;
	
	-- SLT unsigned -> control = "01111"
	-- SLT signed   -> control = "11110"
	-- Determine which type based on control(4)
	set_on_less_than(WIDTH-1 downto 1) <= (others => '0');
	with control(0) select
		set_on_less_than(0) <= bool2logic(unsigned(inA) < unsigned(inB)) when '1',
							   bool2logic(signed(inA) < signed(inB)) when others;
	
	
	-- Shift left or right by shiftAmnt
	with shiftDir select
		shift_output <= std_logic_vector(SHIFT_LEFT(unsigned(B), to_integer(unsigned(shiftAmt)))) when '0',
						std_logic_vector(SHIFT_RIGHT(unsigned(B), to_integer(unsigned(shiftAmt)))) when others;
	
end arch;