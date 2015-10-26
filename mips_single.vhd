library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lib.all;

entity mips_single is
	generic (
		WIDTH : positive := DATA_WIDTH
	);
	port (
		clk : in std_logic;
		rst : in std_logic
	);
end entity;

architecture arch of mips_single is
	signal notclk : std_logic;
	signal instruction : std_logic_vector(WIDTH-1 downto 0);
	
	signal pc : std_logic_vector(WIDTH-1 downto 0);
	signal pc_en : std_logic;
	
	-- Register File
	signal reg_output_A : std_logic_vector(WIDTH-1 downto 0);
	signal reg_output_B : std_logic_vector(WIDTH-1 downto 0);
	signal reg_write_addr : std_logic_vector(get_log2(WIDTH)-1 downto 0);
	signal reg_write_data : std_logic_vector(WIDTH-1 downto 0);
	
	-- Extender
	signal extender_output : std_logic_vector(WIDTH-1 downto 0);
	signal extender_output_shifted : std_logic_vector(WIDTH-1 downto 0);
	
	-- ALU
	signal alu_input_B : std_logic_vector(WIDTH-1 downto 0);
	signal alu_control : std_logic_vector(ALU_CONTROL_WIDTH-1 downto 0);
	signal alu_shiftdir : std_logic;
	signal alu_output : std_logic_vector(WIDTH-1 downto 0);
	signal alu_carry : std_logic;
	signal alu_zero : std_logic;
	signal alu_sign : std_logic;
	signal alu_overflow : std_logic;
	
	-- Memory
	signal data_read_en : std_logic;
	signal data_write_en : std_logic;
	signal data_mem_output : std_logic_vector(WIDTH-1 downto 0);
	
	-- Control signals
	signal ctrl_branch : std_logic;
	signal ctrl_jump : std_logic;
	signal ctrl_reg_dest : std_logic;
	signal ctrl_reg_wr : std_logic;
	signal ctrl_alu_src : std_logic;
	signal ctrl_alu_op : std_logic_vector(ALU_OP_WIDTH-1 downto 0);
	signal ctrl_mem_rd : std_logic;
	signal ctrl_mem_wr : std_logic;
	signal ctrl_mem2reg : std_logic;
begin
	
	-- Inverse of clk
	notclk <= not clk;
	
	-- Altsyncram Memory Module (from Quartus Megawizard plugin)
	-- Since this is a simulation, the memory module is only 256 locations deep
	-- Maps to memory location 0x00400000
	pc_en <= bool2logic(pc(31 downto 8) = x"004000");
	
	U_INSTR_MEMORY : entity work.instr_memory
		port map (
			address => pc(7 downto 0),
			clock => clk,
			rden => pc_en,
			q => instruction
		);
	
	-- Program Counter (updates on falling edge)
	-- Shift the extender output left by two for the word address boundary
	extender_output_shifted <= std_logic_vector(SHIFT_LEFT(unsigned(extender_output), 2));
	U_PC : entity work.program_counter
		generic map (
			WIDTH => WIDTH
		)
		port map (
			clk => notclk,
			rst => rst,
			immediate => extender_output_shifted,
			jump_address => instruction(JTYPE_ADDRESS_RANGE),
			branch => ctrl_branch,
			jump => ctrl_jump,
			zero => alu_zero,
			pc => pc
		);
	
	-- Control Logic
	U_CONTROL : entity work.control
		port map (
			opcode => instruction(OPCODE_RANGE),
			branch => ctrl_branch,
			jump => ctrl_jump,
			reg_dest => ctrl_reg_dest,
			reg_wr => ctrl_reg_wr,
			alu_src => ctrl_alu_src,
			alu_op => ctrl_alu_op,
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
			is_signed => '1'
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
	-- Again, due to simulation only use part of output as address
	-- Maps to DATA_BASE_ADDR (0x10000000)
	data_read_en <= ctrl_mem_rd and bool2logic(alu_output(31 downto 8) = DATA_BASE_ADDR(31 downto 8));
	data_write_en <= ctrl_mem_wr and bool2logic(alu_output(31 downto 8) = DATA_BASE_ADDR(31 downto 8));
	U_DATA_MEMORY : entity work.data_memory
		port map (
			address => alu_output(7 downto 0),
			clock => clk,
			data => reg_output_B,
			rden => data_read_en,
			wren => data_write_en,
			q => data_mem_output
		);
	
	--  Memory-to-Reg Mux (between ALU and Data Memory)
	U_MEM2REG_MUX : entity work.mux2
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => ctrl_mem2reg,
			in0 => alu_output,
			in1 => data_mem_output,
			output => reg_write_data
		);
	
end arch;