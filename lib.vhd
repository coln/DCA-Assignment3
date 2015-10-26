library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package lib is
	
	-- Data Constant
	constant DATA_WIDTH : positive := 32;
	
	-- Global Instruction Constants
	constant OPCODE_WIDTH : positive := 6;
	constant RS_WIDTH : positive := 5;
	constant RT_WIDTH : positive := 5;
	subtype OPCODE_RANGE is natural range 31 downto 26;
	subtype RS_RANGE is natural range 25 downto 21;
	subtype RT_RANGE is natural range 20 downto 16;
	
	-- RTYPE Instruction Constants
	constant RTYPE_RD_WIDTH : positive := 5;
	constant RTYPE_SHAMT_WIDTH : positive := 5;
	constant RTYPE_FUNC_WIDTH : positive := 6;
	subtype RTYPE_RD_RANGE is natural range 15 downto 11;
	subtype RTYPE_SHAMT_RANGE is natural range 10 downto 6;
	subtype RTYPE_FUNC_RANGE is natural range 5 downto 0;
	
	-- ITYPE Instruction Constants
	constant ITYPE_IMMEDIATE_WIDTH : positive := 16;
	subtype ITYPE_IMMEDIATE_RANGE is natural range 15 downto 0;
	
	-- JTYPE Instruction Constants
	constant JTYPE_ADDRESS_WIDTH : positive := 26;
	subtype JTYPE_ADDRESS_RANGE is natural range 25 downto 0;
	
	-- Opcode Constants
	constant OPCODE_RTYPE : std_logic_vector(OPCODE_RANGE) := "000000";
	constant OPCODE_ADDI : std_logic_vector(OPCODE_RANGE) := "001000";
	constant OPCODE_ADDIU : std_logic_vector(OPCODE_RANGE) := "001001";
	constant OPCODE_ANDI : std_logic_vector(OPCODE_RANGE) := "001100";
	constant OPCODE_BEQ : std_logic_vector(OPCODE_RANGE) := "000100";
	constant OPCODE_BNE : std_logic_vector(OPCODE_RANGE) := "000101";
	constant OPCODE_J : std_logic_vector(OPCODE_RANGE) := "000010";
	constant OPCODE_JAL : std_logic_vector(OPCODE_RANGE) := "000011";
	constant OPCODE_LBU : std_logic_vector(OPCODE_RANGE) := "100100";
	constant OPCODE_LHU : std_logic_vector(OPCODE_RANGE) := "100101";
	constant OPCODE_LUI : std_logic_vector(OPCODE_RANGE) := "001111";
	constant OPCODE_LW : std_logic_vector(OPCODE_RANGE) := "100011";
	constant OPCODE_ORI : std_logic_vector(OPCODE_RANGE) := "001101";
	constant OPCODE_SLTI : std_logic_vector(OPCODE_RANGE) := "001010";
	constant OPCODE_SLTIU : std_logic_vector(OPCODE_RANGE) := "001011";
	constant OPCODE_SB : std_logic_vector(OPCODE_RANGE) := "101000";
	constant OPCODE_SH : std_logic_vector(OPCODE_RANGE) := "101001";
	constant OPCODE_SW : std_logic_vector(OPCODE_RANGE) := "101011";
	
	
	-- Program Counter
	constant INSTR_BASE_ADDR : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00400000";
	constant DATA_BASE_ADDR : std_logic_vector(DATA_WIDTH-1 downto 0) := x"10000000";
	
	-- Controller Constants
	-- ALUop
	constant CTRL_ALU_OP_FUNC : std_logic_vector(2 downto 0) := "100";
	constant CTRL_ALU_OP_AND : std_logic_vector(2 downto 0) := "000";
	constant CTRL_ALU_OP_SUB : std_logic_vector(2 downto 0) := "001";
	constant CTRL_ALU_OP_ADD : std_logic_vector(2 downto 0) := "010";
	constant CTRL_ALU_OP_OR : std_logic_vector(2 downto 0) := "110";
	constant CTRL_ALU_OP_SLTU : std_logic_vector(2 downto 0) := "101";
	constant CTRL_ALU_OP_SLT : std_logic_vector(2 downto 0) := "111";
	
	
	-- ALU Constants
	constant ALU_OP_WIDTH : positive := 3;
	constant ALU_CONTROL_WIDTH : positive := 4;
	subtype ALU_CONTROL_RANGE is natural range ALU_CONTROL_WIDTH-1 downto 0;
	constant ALU_OP_ADD : std_logic_vector(ALU_CONTROL_RANGE) := "0010";
	constant ALU_OP_SUB : std_logic_vector(ALU_CONTROL_RANGE) := "0110";
	constant ALU_OP_AND : std_logic_vector(ALU_CONTROL_RANGE) := "0000";
	constant ALU_OP_OR : std_logic_vector(ALU_CONTROL_RANGE) := "0001";
	constant ALU_OP_NOR : std_logic_vector(ALU_CONTROL_RANGE) := "1100";
	constant ALU_OP_SLT_SIGNED : std_logic_vector(ALU_CONTROL_RANGE) := "0111";
	constant ALU_OP_SLT_UNSIGNED : std_logic_vector(ALU_CONTROL_RANGE) := "1111";
	constant ALU_OP_SHIFT : std_logic_vector(ALU_CONTROL_RANGE) := "0011";
	-- ALU Function Codes (from the instruction itself)
	subtype ALU_FUNC_RANGE is natural range RTYPE_FUNC_WIDTH-1 downto 0;
	constant RTYPE_FUNC_ADD : std_logic_vector(ALU_FUNC_RANGE) := "100000";
	constant RTYPE_FUNC_ADDU : std_logic_vector(ALU_FUNC_RANGE) := "100001";
	constant RTYPE_FUNC_AND : std_logic_vector(ALU_FUNC_RANGE) := "100100";
	constant RTYPE_FUNC_JR : std_logic_vector(ALU_FUNC_RANGE) := "001000";
	constant RTYPE_FUNC_NOR : std_logic_vector(ALU_FUNC_RANGE) := "100111";
	constant RTYPE_FUNC_OR : std_logic_vector(ALU_FUNC_RANGE) := "100101";
	constant RTYPE_FUNC_SLT : std_logic_vector(ALU_FUNC_RANGE) := "101010";
	constant RTYPE_FUNC_SLTU : std_logic_vector(ALU_FUNC_RANGE) := "101011";
	constant RTYPE_FUNC_SLL : std_logic_vector(ALU_FUNC_RANGE) := "000000";
	constant RTYPE_FUNC_SRL : std_logic_vector(ALU_FUNC_RANGE) := "000010";
	constant RTYPE_FUNC_SUB : std_logic_vector(ALU_FUNC_RANGE) := "100010";
	constant RTYPE_FUNC_SUBU : std_logic_vector(ALU_FUNC_RANGE) := "100011";
	
	
	
	function bool2logic(expr : boolean) return std_logic;
	function int2slv(value : integer; width : positive; signed : boolean := false) return std_logic_vector;
	function get_log2(num_bits : positive) return positive;
end lib;

package body lib is
	
	-- Converts a boolean value to a std_logic value
	function bool2logic(expr : boolean) return std_logic is
	begin
		if(expr) then
			return '1';
		else
			return '0';
		end if;
	end bool2logic;
	
	-- Returns a std_logic_vector (slv) representation of "value"
	-- Note: This will return an signed slv if the "value" < 0 or if signed = true
	function int2slv(value : integer; width : positive; signed : boolean := false) return std_logic_vector is
	begin
		if(value >= 0 and signed = false) then
			return std_logic_vector(to_unsigned(value, width));
		else
			return std_logic_vector(to_signed(value, width));
		end if;
	end;
	
	-- Determines how many bits are needed for "num_bits"
	-- I.E. determines x for num_bits = 2^x
	function get_log2(num_bits : positive) return positive is
	begin
		return integer(ceil(log2(real(num_bits))));
	end get_log2;
	
end lib;