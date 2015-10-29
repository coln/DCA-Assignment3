library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lib.all;

-- MIPS single-cycle processor implementation
-- clk and rst - Main processor
-- mem_clk - Memory clock (should be ~3-4 times faster)
entity mips_single is
	generic (
		WIDTH : positive := DATA_WIDTH
	);
	port (
		clk : in std_logic;
		mem_clk : in std_logic;
		rst : in std_logic
	);
end entity;

architecture arch of mips_single is
	signal instruction : std_logic_vector(WIDTH-1 downto 0);
	signal pc_clk : std_logic;
	signal pc : std_logic_vector(WIDTH-1 downto 0);
	signal pc_inc : std_logic_vector(WIDTH-1 downto 0);
	signal pc_jump_address : std_logic_vector(JTYPE_ADDRESS_WIDTH-1 downto 0);
	signal pc_en : std_logic;
	
	-- Register File
	signal dest_mux_output : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal reg_output_A : std_logic_vector(WIDTH-1 downto 0);
	signal reg_output_B : std_logic_vector(WIDTH-1 downto 0);
	signal reg_write_addr : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal reg_write_data : std_logic_vector(WIDTH-1 downto 0);
	
	-- Extender
	signal extender_output : std_logic_vector(WIDTH-1 downto 0);
	
	-- ALU
	signal alu_input_B : std_logic_vector(WIDTH-1 downto 0);
	signal alu_control : std_logic_vector(ALU_CONTROL_WIDTH-1 downto 0);
	signal alu_shiftdir : std_logic;
	signal alu_output : std_logic_vector(WIDTH-1 downto 0);
	signal alu_carry : std_logic;
	signal alu_zero : std_logic;
	signal alu_sign : std_logic;
	signal alu_overflow : std_logic;
	
	-- Load Upper Immediate Mux (LUI)
	signal lui_mux : std_logic_vector(WIDTH-1 downto 0);
	signal lui_output : std_logic_vector(WIDTH-1 downto 0);
	
	-- PC to REG31 mux
	signal pc2reg31_output : std_logic_vector(WIDTH-1 downto 0);
	
	-- Memory
	signal data_mem_output : std_logic_vector(WIDTH-1 downto 0);
	
	-- Control signals
	signal ctrl_beq : std_logic;
	signal ctrl_bne : std_logic;
	signal ctrl_jump : std_logic;
	signal ctrl_jump_addr_src : std_logic;
	signal ctrl_pc2reg31 : std_logic;
	signal ctrl_reg_dest : std_logic;
	signal ctrl_reg_wr : std_logic;
	signal ctrl_extender : std_logic;
	signal ctrl_alu_src : std_logic;
	signal ctrl_alu_op : std_logic_vector(ALU_OP_WIDTH-1 downto 0);
	signal ctrl_lui_src : std_logic;
	signal ctrl_byte : std_logic;
	signal ctrl_half : std_logic;
	signal ctrl_mem_rd : std_logic;
	signal ctrl_mem_wr : std_logic;
	signal ctrl_mem2reg : std_logic;
begin
	
	-- Altsyncram Memory Module (from Quartus Megawizard plugin)
	-- Since this is a simulation, the memory module is only 256 locations deep
	-- Maps to memory location 0x00400000
	pc_en <= not rst and bool2logic(pc(31 downto 8) = x"004000");
	
	U_INSTR_MEMORY : entity work.instr_memory
		port map (
			address => pc(7 downto 0),
			clock => mem_clk,
			rden => pc_en,
			q => instruction
		);
	
	-- Jump Address mux (selects between address in instruction and in regster)
	-- Used with J, JAL, and JR
	U_JUMP_ADDRESS_MUX : entity work.mux2
		generic map (
			WIDTH => JTYPE_ADDRESS_WIDTH
		)
		port map (
			sel => ctrl_jump_addr_src,
			in0 => instruction(JTYPE_ADDRESS_RANGE),
			in1 => reg_output_A(JTYPE_ADDRESS_WIDTH-1 downto 0),
			output => pc_jump_address
		);
	
	-- Program Counter (updates on falling edge)
	-- Would normally shift the extender output left by 2 for the word address boundary,
	-- but I am using 32-bit wide instruction memory, so this is unnecessary
	-- Update the PC on the falling edge
	pc_clk <= not clk;
	--extender_output_shifted <= std_logic_vector(SHIFT_LEFT(unsigned(extender_output), 2));
	U_PC : entity work.program_counter
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => pc_clk,
			rst => rst,
			immediate => extender_output,
			jump_address => pc_jump_address,
			beq => ctrl_beq,
			bne => ctrl_bne,
			jump => ctrl_jump,
			zero => alu_zero,
			pc => pc,
			pc_inc => pc_inc
		);
	
	-- Control Logic
	U_CONTROL : entity work.control
		port map (
			opcode => instruction(OPCODE_RANGE),
			func => instruction(RTYPE_FUNC_RANGE),
			beq => ctrl_beq,
			bne => ctrl_bne,
			jump => ctrl_jump,
			jump_addr_src => ctrl_jump_addr_src,
			pc2reg31 => ctrl_pc2reg31,
			reg_dest => ctrl_reg_dest,
			reg_wr => ctrl_reg_wr,
			extender => ctrl_extender,
			alu_src => ctrl_alu_src,
			alu_op => ctrl_alu_op,
			lui_src => ctrl_lui_src,
			byte => ctrl_byte,
			half => ctrl_half,
			mem_rd => ctrl_mem_rd,
			mem_wr => ctrl_mem_wr,
			mem2reg => ctrl_mem2reg
		);
	
	-- Destination Register select (between RT and RD)
	U_DEST_MUX : entity work.mux2
		generic map (
			WIDTH => get_log2(WIDTH)
		)
		port map (
			sel => ctrl_reg_dest,
			in0 => instruction(RT_RANGE),
			in1 => instruction(RTYPE_RD_RANGE),
			output => dest_mux_output
		);
	
	-- Jump and Link (selects between DEST_MUX and register 31)
	U_JAL_MUX : entity work.mux2
		generic map (
			WIDTH => get_log2(WIDTH)
		)
		port map (
			sel => ctrl_pc2reg31,
			in0 => dest_mux_output,
			in1 => int2slv(31, get_log2(WIDTH)),
			output => reg_write_addr
		);
	
	-- 32 Registers
	U_REG_FILE : entity work.reg_file
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => clk,
			rst => rst,
			wr => ctrl_reg_wr,
			rr0 => instruction(RS_RANGE),
			rr1 => instruction(RT_RANGE),
			q0 => reg_output_A,
			q1 => reg_output_B,
			rw => reg_write_addr,
			d => reg_write_data
		);
	
	-- Sign Extender for Immedate Value
	U_EXTENDER : entity work.extender
		generic map (
			WIDTH_IN => ITYPE_IMMEDIATE_WIDTH,
			WIDTH_OUT => WIDTH
		)
		port map (
			in0 => instruction(ITYPE_IMMEDIATE_RANGE),
			out0 => extender_output,
			is_signed => ctrl_extender
		);
	
	-- ALU Input B Mux
	U_ALU_INPUT_MUX : entity work.mux2
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => ctrl_alu_src,
			in0 => reg_output_B,
			in1 => extender_output,
			output => alu_input_B
		);
	
	-- ALU
	U_ALU_CONTROL : entity work.alu_control
		port map (
			func => instruction(RTYPE_FUNC_RANGE),
			ALUop => ctrl_alu_op,
			control => alu_control,
			shiftDir => alu_shiftdir
		);
	U_ALU : entity work.alu
		generic map (
			WIDTH => WIDTH
		)
		port map (
			inA => reg_output_A,
			inB => alu_input_B,
			control => alu_control,
			shiftAmt => instruction(RTYPE_SHAMT_RANGE),
			shiftDir => alu_shiftdir,
			output => alu_output,
			carry => alu_carry,
			zero => alu_zero,
			sign => alu_sign,
			overflow => alu_overflow
		);
	
	
	
	-- Altsyncram Data Memory Module
	-- Byte addressable
	U_DATA_MEMORY : entity work.data_memory_wrapper
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => mem_clk,
			rst => rst,
			address => alu_output,
			data => reg_output_B,
			rden => ctrl_mem_rd,
			wren => ctrl_mem_wr,
			byte => ctrl_byte,
			half => ctrl_half,
			output => data_mem_output
		);
	
	
	
	-- Load Upper Immediate (LUI): Imm[31:16] & Rt[15:0] or ALU ouptut
	lui_mux <= instruction(ITYPE_IMMEDIATE_RANGE) & reg_output_B(WIDTH-ITYPE_IMMEDIATE_WIDTH-1 downto 0);
	U_LUI_MUX : entity work.mux2
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => ctrl_lui_src,
			in0 => alu_output,
			in1 => lui_mux,
			output => lui_output
		);
	
	-- Jump and Link (JAL): PC + 4 or ALU to mem2reg MUX
	U_PC2REG31_MUX : entity work.mux2
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => ctrl_pc2reg31,
			in0 => lui_output,
			in1 => pc_inc,
			output => pc2reg31_output
		);
	
	--  Memory-to-Reg Mux (between ALU and Data Memory)
	U_MEM2REG_MUX : entity work.mux2
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => ctrl_mem2reg,
			in0 => pc2reg31_output,
			in1 => data_mem_output,
			output => reg_write_data
		);
	
end arch;