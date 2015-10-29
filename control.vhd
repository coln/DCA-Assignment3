library ieee;
use ieee.std_logic_1164.all;
use work.lib.all;

-- MIPS Control for the datapath
--
-- reg_dest: selects the write address (RD or RT)
-- extender: controls signed or zero extension ('1' and '0' respectively)
-- alu_src: selects register output B or extender output for ALU input B
-- alu_op: selects the ALU operation performed
-- mem2reg: determines if the data memory output will be written to registers
entity control is
	port (
		opcode : in std_logic_vector(OPCODE_RANGE);
		branch : out std_logic;
		jump : out std_logic;
		reg_dest : out std_logic;
		reg_wr : out std_logic;
		extender : out std_logic;
		alu_src : out std_logic;
		alu_op : out std_logic_vector(ALU_OP_WIDTH-1 downto 0);
		mem_rd : out std_logic;
		mem_wr : out std_logic;
		mem2reg : out std_logic
	);
end entity;

architecture arch of control is
begin
	
	process(opcode)
	begin
		branch <= '0';
		jump <= '0';
		reg_dest <= '0';
		reg_wr <= '0';
		extender <= '1'; -- Sign extend is default
		alu_src <= '0';
		alu_op <= (others => '0');
		mem_rd <= '0';
		mem_wr <= '0';
		mem2reg <= '0';
		
		case opcode is
			when OPCODE_RTYPE =>
				reg_dest <= '1';
				reg_wr <= '1';
				alu_op <= ALU_OP_FUNC;
			
			when OPCODE_ADDI =>
				reg_wr <= '1';
				alu_src <= '1';
				alu_op <= ALU_OP_ADD;
			
			when OPCODE_ADDIU =>
				reg_wr <= '1';
				alu_src <= '1';
				alu_op <= ALU_OP_ADDU;
			
			when OPCODE_ANDI =>
				reg_wr <= '1';
				extender <= '0';
				alu_src <= '1';
				alu_op <= ALU_OP_AND;
			
			when OPCODE_ORI =>
				reg_wr <= '1';
				alu_src <= '1';
				alu_op <= ALU_OP_OR;
			
			when OPCODE_SW =>
				alu_src <= '1';
				alu_op <= ALU_OP_ADD;
				mem_wr <= '1';
			
			when OPCODE_LW =>
				reg_wr <= '1';
				alu_src <= '1';
				alu_op <= ALU_OP_ADD;
				mem_rd <= '1';
				mem2reg <= '1';
			
				
				
			when others => null;
		end case;
			
		
	end process;
	
end arch;