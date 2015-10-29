library ieee;
use ieee.std_logic_1164.all;
use work.lib.all;

-- MIPS ALU Control unit
entity alu_control is
	port (
		func : in std_logic_vector(RTYPE_FUNC_WIDTH-1 downto 0);
		ALUop : in std_logic_vector(ALU_OP_WIDTH-1 downto 0);
		control : out std_logic_vector(ALU_CONTROL_WIDTH-1 downto 0);
		shiftDir : out std_logic
	);
end entity;

architecture arch of alu_control is
	signal func_cntrl : std_logic_vector(ALU_CONTROL_WIDTH-1 downto 0);
begin
	
	-- Determine shift direction based upon function code
	with func select
		shiftDir <= '1' when "000010",
					'0' when others;
	
	-- Control for the function code (if one exists)
	with func select
		func_cntrl <= ALU_ADD when RTYPE_FUNC_ADD,
					  ALU_ADDU when RTYPE_FUNC_ADDU,
					  ALU_AND when RTYPE_FUNC_AND,
					  ALU_ADD when RTYPE_FUNC_JR,
					  ALU_NOR when RTYPE_FUNC_NOR,
					  ALU_OR when RTYPE_FUNC_OR,
					  ALU_SLT when RTYPE_FUNC_SLT,
					  ALU_SLTU when RTYPE_FUNC_SLTU,
					  ALU_SHIFT when RTYPE_FUNC_SLL,
					  ALU_SHIFT when RTYPE_FUNC_SRL,
					  ALU_SUB when RTYPE_FUNC_SUB,
					  ALU_SUBU when RTYPE_FUNC_SUBU,
					  (others => '0') when others;
	
	-- Determine the output controls using "ALUop" and "func"
	with ALUop select
		control <= func_cntrl when ALU_OP_FUNC,
				   ALU_AND when ALU_OP_AND,
				   ALU_SUB when ALU_OP_SUB,
				   ALU_SUBU when ALU_OP_SUBU,
				   ALU_ADD when ALU_OP_ADD,
				   ALU_ADDU when ALU_OP_ADDU,
				   ALU_OR when ALU_OP_OR,
				   ALU_SLTU when ALU_OP_SLTU,
				   ALU_SLT when ALU_OP_SLT,
				   (others => '0') when others;
	
end arch;
