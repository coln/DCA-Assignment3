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
	constant ALU_OP_WIDTH : positive := 4;
	subtype ALU_OP_RANGE is natural range ALU_OP_WIDTH-1 downto 0;
	constant ALU_OP_FUNC : std_logic_vector(ALU_OP_RANGE) := "1000";
	constant ALU_OP_AND : std_logic_vector(ALU_OP_RANGE) := "0000";
	constant ALU_OP_SUB : std_logic_vector(ALU_OP_RANGE) := "0010";
	constant ALU_OP_SUBU : std_logic_vector(ALU_OP_RANGE) := "0011";
	constant ALU_OP_ADD : std_logic_vector(ALU_OP_RANGE) := "0100";
	constant ALU_OP_ADDU : std_logic_vector(ALU_OP_RANGE) := "0101";
	constant ALU_OP_OR : std_logic_vector(ALU_OP_RANGE) := "1100";
	constant ALU_OP_SLT : std_logic_vector(ALU_OP_RANGE) := "1110";
	constant ALU_OP_SLTU : std_logic_vector(ALU_OP_RANGE) := "1011";
	
	
	-- ALU Constants
	constant ALU_CONTROL_WIDTH : positive := 5;
	subtype ALU_CONTROL_RANGE is natural range ALU_CONTROL_WIDTH-1 downto 0;
	constant ALU_ADD : std_logic_vector(ALU_CONTROL_RANGE) := "00100";
	constant ALU_ADDU : std_logic_vector(ALU_CONTROL_RANGE) := "00101";
	constant ALU_SUB : std_logic_vector(ALU_CONTROL_RANGE) := "01100";
	constant ALU_SUBU : std_logic_vector(ALU_CONTROL_RANGE) := "01101";
	constant ALU_AND : std_logic_vector(ALU_CONTROL_RANGE) := "00000";
	constant ALU_OR : std_logic_vector(ALU_CONTROL_RANGE) := "00010";
	constant ALU_NOR : std_logic_vector(ALU_CONTROL_RANGE) := "11000";
	constant ALU_SLT : std_logic_vector(ALU_CONTROL_RANGE) := "01110";
	constant ALU_SLTU : std_logic_vector(ALU_CONTROL_RANGE) := "11111";
	constant ALU_SHIFT : std_logic_vector(ALU_CONTROL_RANGE) := "00110";
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
	function logic2unsigned(value : std_logic; width : positive) return unsigned;
	function logic2unsigned(value : std_logic) return unsigned;
	function slv2unsigned(value : std_logic_vector; width : integer) return unsigned;
	function slv2unsigned(value : std_logic_vector) return unsigned;
	function int2slv(value : integer; width : positive; signed : boolean := false) return std_logic_vector;
	function get_log2(num_bits : positive) return positive;
	
	-- Testbench ONLY
	procedure clk_gen(signal clk : out std_logic;
					  signal done : in std_logic;
					  constant FREQ : real;
					  PHASE : time := 0 fs);
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
	
	-- std_logic to unsigned with specific length
	function logic2unsigned(value : std_logic) return unsigned is
	begin
		return logic2unsigned(value, 1);
	end logic2unsigned;
	
	function logic2unsigned(value : std_logic; width : positive) return unsigned is
		variable temp : std_logic_vector(0 downto 0);
	begin
		temp(0) := value;
		if(width > 1) then
			return resize(unsigned(temp), width);
		else
			return unsigned(temp);
		end if;
	end logic2unsigned;
	
	
	-- std_logic_vector to unsigned with specific length
	function slv2unsigned(value : std_logic_vector) return unsigned is
	begin
		return slv2unsigned(value, value'length);
	end slv2unsigned;
	
	function slv2unsigned(value : std_logic_vector; width : positive) return unsigned is
	begin
		return resize(unsigned(value), width);
	end slv2unsigned;
	
	
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
	
	
	-- Advanced procedure for clock generation, with period adjust to match 
	-- frequency over time, and run control by signal
	-- NOTE: FOR TESTBENCH USE ONLY
	-- Also note: REAL type (for FREQ) needs the ".0" at the end 
	-- of the number, e.g. "5.0" instead of "5"
	procedure clk_gen(
		signal clk : out std_logic;
		signal done : in std_logic;
		constant FREQ : real;
		constant PHASE : time := 0 fs
	) is
		constant HIGH_TIME   : time := 0.5 sec / FREQ;  -- High time as fixed value
		variable low_time_v  : time;                    -- Low time calculated per cycle; always >= HIGH_TIME
		variable cycles_v    : real := 0.0;             -- Number of cycles
		variable freq_time_v : time := 0 fs;            -- Time used for generation of cycles
	begin
		-- Check the arguments
		assert (HIGH_TIME /= 0 fs)
			report "clk_gen: High time is zero; time resolution to large for frequency" severity FAILURE;
			
		-- Initial phase shift
		clk <= '0';
		wait for PHASE;
		
		-- Generate cycles
		loop
			-- Only high pulse if not done
			if(done = '0' or done = 'L')then
				clk <= not done;
			else
				exit;
			end if;
			wait for HIGH_TIME;
			
			-- Low part of cycle
			clk <= '0';
			low_time_v := 1 sec * ((cycles_v + 1.0) / FREQ) - freq_time_v - HIGH_TIME;  -- + 1.0 for cycle after current
			wait for low_time_v;
			-- Cycle counter and time passed update
			cycles_v := cycles_v + 1.0;
			freq_time_v := freq_time_v + HIGH_TIME + low_time_v;
		end loop;
	end procedure;
	
end lib;