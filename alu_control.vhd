library ieee;
use ieee.std_logic_1164.all;
use work.lib.all;

-- MIPS ALU Control unit
entity alu_control is
	port (
		func : in std_logic_vector(5 downto 0);
		ALUop : in std_logic_vector(2 downto 0);
		control : out std_logic_vector(3 downto 0);
		shiftDir : out std_logic
	);
end entity;

architecture arch of alu_control is
	signal func_cntrl : std_logic_vector(3 downto 0);
begin
	
	-- Determine shift direction based upon function code
	with func select
		shiftDir <= '1' when "000010",
					'0' when others;
	
	-- Determine the control bits (used below) for each function code
	with func select
		func_cntrl <= ALU_OP_ADD when RTYPE_FUNC_ADD,
					  ALU_OP_ADD when RTYPE_FUNC_ADDU,
					  ALU_OP_AND when RTYPE_FUNC_AND,
					  ALU_OP_ADD when RTYPE_FUNC_JR,
					  ALU_OP_NOR when RTYPE_FUNC_NOR,
					  ALU_OP_OR when RTYPE_FUNC_OR,
					  ALU_OP_SLT_SIGNED when RTYPE_FUNC_SLT,
					  ALU_OP_SLT_UNSIGNED when RTYPE_FUNC_SLTU,
					  ALU_OP_SHIFT when RTYPE_FUNC_SLL,
					  ALU_OP_SHIFT when RTYPE_FUNC_SRL,
					  ALU_OP_SUB when RTYPE_FUNC_SUB,
					  ALU_OP_SUB when RTYPE_FUNC_SUBU,
					  "0000" when others;
	
	-- Determine the output controls using "ALUop" and "func"
	with ALUop select
		control <= func_cntrl when CTRL_ALU_OP_FUNC,
				   ALU_OP_AND when CTRL_ALU_OP_AND,
				   ALU_OP_SUB when CTRL_ALU_OP_SUB,
				   ALU_OP_ADD when CTRL_ALU_OP_ADD,
				   ALU_OP_OR when CTRL_ALU_OP_OR,
				   ALU_OP_SLT_UNSIGNED when CTRL_ALU_OP_SLTU,
				   ALU_OP_SLT_SIGNED when CTRL_ALU_OP_SLT,
				   "0000" when others;
	
end arch;
