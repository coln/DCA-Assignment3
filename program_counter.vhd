library ieee;
use ieee.std_logic_1164.all;
use work.lib.all;

-- Program counter logic
-- Note: The Immediate input must already be sign-extended to WIDTH bits
-- Note: The PC always adds 4, so when calculating branch addresses, they should
-- be calculated from the address following the condition
--
-- The output signal "pc_inc" is only used for the JAL instruction
entity program_counter is
	generic (
		WIDTH : positive := 32
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		immediate : in std_logic_vector(WIDTH-1 downto 0);
		jump_address : in std_logic_vector(JTYPE_ADDRESS_WIDTH-1 downto 0);
		beq : in std_logic;
		bne : in std_logic;
		jump : in std_logic;
		zero : in std_logic;
		pc : out std_logic_vector(WIDTH-1 downto 0);
		pc_inc : out std_logic_vector(WIDTH-1 downto 0)
	);
end entity;

architecture arch of program_counter is
	signal delay_cycle : std_logic;
	signal not_delay_cycle : std_logic;
	
	signal pc_reg_output : std_logic_vector(WIDTH-1 downto 0);
	signal pc_inc1_output : std_logic_vector(WIDTH-1 downto 0);
	signal pc_immediate_output : std_logic_vector(WIDTH-1 downto 0);
	signal branch_mux_sel : std_logic;
	signal pc_branch_output : std_logic_vector(WIDTH-1 downto 0);
	signal new_jump_address : std_logic_vector(WIDTH-1 downto 0);
	signal next_pc : std_logic_vector(WIDTH-1 downto 0);
begin
	
	-- Used only with the JAL instruction
	pc_inc <= pc_inc1_output;
	
	-- Because the PC starts off by incrementing, delay one cycle after reset
	-- to allow the first address to propagate through the processor
	U_DELAY_CYCLE : entity work.reg_bit
		generic map (
			WIDTH => 1
		)
		port map (
			clk => clk,
			D => '1',
			Q => delay_cycle,
			wr => '1',
			clr => rst
		);
	-- Because work.reg "RST" is low true
	not_delay_cycle <= not delay_cycle;
	
	
	-- Set PC to 0x00400000 on reset
	pc <= INSTR_BASE_ADDR(31 downto 16) & pc_reg_output(15 downto 0);
	
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
			clr => not_delay_cycle
		);
	
	-- Although MIPS increments the PC by 4, since the memory is 32-bits wide,
	-- We only need to increment the PC by 1 and can multiplex the bytes later
	U_PC_ADD_1 : entity work.add 
		generic map (
			WIDTH => WIDTH
		)
		port map (
			in0 => pc_reg_output,
			in1 => int2slv(1, WIDTH),
			sum => pc_inc1_output,
			cin => '0'
		);
	
	-- Adds immedate address
	U_PC_ADD_IMM : entity work.add
		generic map (
			WIDTH => WIDTH
		)
		port map (
			in0 => pc_inc1_output,
			in1 => immediate,
			sum => pc_immediate_output,
			cin => '0'
		);		
	
	-- Selects between "pc + immediate" or "pc + 4" depending on branch
	branch_mux_sel <= (beq and zero) or (bne and not zero);
	
	U_BRANCH_MUX : entity work.mux2
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => branch_mux_sel,
			in0 => pc_inc1_output,
			in1 => pc_immediate_output,
			output => pc_branch_output
		);
	
	-- Selects between pc_branch_output and jump_output
	-- New jump address is PC[31:26] & JMP[25:0]
	new_jump_address <= pc_reg_output(WIDTH-1 downto JTYPE_ADDRESS_WIDTH) & jump_address;
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