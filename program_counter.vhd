library ieee;
use ieee.std_logic_1164.all;
use work.lib.all;

-- Program counter logic
-- Note: The Immediate input must already be sign-extended to WIDTH bits
-- Note: The PC always adds 4, so when calculating branch addresses, they should
-- be calculated from the address following the condition
entity program_counter is
	generic (
		WIDTH : positive := 32
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		immediate : in std_logic_vector(WIDTH-1 downto 0);
		jump_address : in std_logic_vector(JTYPE_ADDRESS_WIDTH-1 downto 0);
		branch : in std_logic;
		jump : in std_logic;
		zero : in std_logic;
		pc : out std_logic_vector(WIDTH-1 downto 0)
	);
end entity;

architecture arch of program_counter is
	signal pc_reg_output : std_logic_vector(WIDTH-1 downto 0);
	signal pc_inc4_output : std_logic_vector(WIDTH-1 downto 0);
	signal pc_immediate_output : std_logic_vector(WIDTH-1 downto 0);
	signal branch_mux_sel : std_logic;
	signal pc_branch_output : std_logic_vector(WIDTH-1 downto 0);
	signal new_jump_address : std_logic_vector(WIDTH-1 downto 0);
	signal next_pc : std_logic_vector(WIDTH-1 downto 0);
begin
	
	-- Since instructions are 32-bits (4 bytes) wide, we don't need the last LSBs
	pc <= pc_reg_output(WIDTH-1 downto 2) & "00";
	
	-- Increment PC on falling edge
	U_REG : entity work.reg
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => clk,
			D => next_pc,
			Q => pc_reg_output,
			wr => '1',
			clr => rst
		);
	
	-- Add 4 because MIPS instructions are 4-bytes long
	U_PC_ADD_4 : entity work.add 
		generic map (
			WIDTH => WIDTH
		)
		port map (
			in0 => pc_reg_output,
			in1 => int2slv(4, WIDTH),
			sum => pc_inc4_output,
			cin => '0'
		);
	
	-- Adds immedate address
	U_PC_ADD_IMM : entity work.add
		generic map (
			WIDTH => WIDTH
		)
		port map (
			in0 => pc_inc4_output,
			in1 => immediate,
			sum => pc_immediate_output,
			cin => '0'
		);		
	
	-- Selects between "pc + immediate" or "pc + 4" depending on branch
	branch_mux_sel <= branch and zero;
	
	U_BRANCH_MUX : entity work.mux2
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => branch_mux_sel,
			in0 => pc_inc4_output,
			in1 => pc_immediate_output,
			output => pc_branch_output
		);
	
	-- Selects between pc_branch_output and jump_output
	-- New jump address is PC[31:28] & JMP[25:2] & "00", shifting left by 2 for word boundary
	new_jump_address <= pc_reg_output(WIDTH-1 downto JTYPE_ADDRESS_WIDTH + 2) & jump_address & "00";
	U_JUMP_MUX : entity work.mux2
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => jump,
			in0 => pc_branch_output,
			in1 => new_jump_address,
			output => next_pc
		);
	
end arch;