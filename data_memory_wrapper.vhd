library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lib.all;

-- Altsyncram Data Memory Module
-- 4 modules, 8-bit words/module, 256 words/module deep
-- I'm using memory mapping to give the appearance that we can load/store bytes
-- Maps to DATA_BASE_ADDR (0x10000000)
entity data_memory_wrapper is
	generic (
		WIDTH : positive := 32
	);
	port (
		signal clk : in std_logic;
		signal rst : in std_logic;
		signal address : in std_logic_vector(WIDTH-1 downto 0);
		signal data : in std_logic_vector(WIDTH-1 downto 0);
		signal rden : in std_logic;
		signal wren : in std_logic;
		signal byte : in std_logic;
		signal half : in std_logic;
		signal output : out std_logic_vector(WIDTH-1 downto 0)
	);
end entity;

architecture arch of data_memory_wrapper is
	signal notclk : std_logic;
	
	-- Inputs
	type write_sel_array is array (0 to 3) of std_logic_vector(1 downto 0);
	signal write_sel : write_sel_array;
	signal write_output : std_logic_vector(WIDTH-1 downto 0);
	
	signal global_read_en : std_logic;
	signal global_write_en : std_logic;
	signal read_en : std_logic_vector(3 downto 0);
	signal write_en : std_logic_vector(3 downto 0);
	
	type addr_wrap_array is array (0 to 3) of std_logic_vector(WIDTH-1 downto 0);
	signal addr_wrap_around : addr_wrap_array;
	
	-- Output
	signal mem_output : std_logic_vector(WIDTH-1 downto 0);
begin
	
	-- Write on falling edge
	notclk <= not clk;
	
	-- The memory blocks are ordered sequentially by address 0, 1, 2, 3, 4....
	-- While the data is order by MSB->LSB (3, 2, 1, 0) (Big Endian)
	process(address, data, rden, wren, byte, half)
		variable sel : std_logic_vector(3 downto 0);
	begin
		write_output <= (others => '0');
		sel := byte & half & address(1 downto 0);
		case sel is
			-- Byte = 1
			when "1000" =>
				write_output(31 downto 24) <= data(7 downto 0);
			when "1001" =>
				write_output(23 downto 16) <= data(7 downto 0);
			when "1010" =>
				write_output(15 downto 8) <= data(7 downto 0);
			when "1011" =>
				write_output(7 downto 0) <= data(7 downto 0);
			
			-- Half word = 1
			when "0100" =>
				write_output(31 downto 16) <= data(15 downto 0);
			when "0101" =>
				write_output(23 downto 8) <= data(15 downto 0);
			when "0110" =>
				write_output(15 downto 0) <= data(15 downto 0);
			when "0111" =>
				write_output(7 downto 0) <= data(15 downto 8);
				write_output(31 downto 24) <= data(7 downto 0);
			
			-- Full word
			when "0000" =>
				write_output <= data;
			when "0001" =>
				write_output(23 downto 0) <= data(31 downto 8);
				write_output(31 downto 24) <= data(7 downto 0);
			when "0010" =>
				write_output(15 downto 0) <= data(31 downto 16);
				write_output(31 downto 16) <= data(15 downto 0);
			when "0011" =>
				write_output(7 downto 0) <= data(31 downto 24);
				write_output(31 downto 8) <= data(23 downto 0);
				
			when others => null;
		end case;
	end process;
	
	-- Only enable memories when in address range of DATA_BASE_ADDR
	global_read_en <= not rst
				and rden
				and bool2logic(address(31 downto 10) = DATA_BASE_ADDR(31 downto 10));
	global_write_en <= not rst
				and wren
				and bool2logic(address(31 downto 10) = DATA_BASE_ADDR(31 downto 10));
	read_en(0) <= global_read_en
				  and (bool2logic(address(1 downto 0) = "00")
				  or bool2logic(address(1 downto 0) = "01" and byte = '0' and half = '0')
				  or bool2logic(address(1 downto 0) = "10" and byte = '0' and half = '0')
				  or bool2logic(address(1 downto 0) = "11" and byte = '0'));
	write_en(0) <= global_write_en
				  and (bool2logic(address(1 downto 0) = "00")
				  or bool2logic(address(1 downto 0) = "01" and byte = '0' and half = '0')
				  or bool2logic(address(1 downto 0) = "10" and byte = '0' and half = '0')
				  or bool2logic(address(1 downto 0) = "11" and byte = '0'));
	read_en(1) <= global_read_en
				  and (bool2logic(address(1 downto 0) = "00" and byte = '0')
				  or bool2logic(address(1 downto 0) = "01")
				  or bool2logic(address(1 downto 0) = "10" and byte = '0' and half = '0')
				  or bool2logic(address(1 downto 0) = "11" and byte = '0' and half = '0'));
	write_en(1) <= global_write_en
				  and (bool2logic(address(1 downto 0) = "00" and byte = '0')
				  or bool2logic(address(1 downto 0) = "01")
				  or bool2logic(address(1 downto 0) = "10" and byte = '0' and half = '0')
				  or bool2logic(address(1 downto 0) = "11" and byte = '0' and half = '0'));
	read_en(2) <= global_read_en
				  and (bool2logic(address(1 downto 0) = "00" and byte = '0' and half = '0')
				  or bool2logic(address(1 downto 0) = "01" and byte = '0')
				  or bool2logic(address(1 downto 0) = "10")
				  or bool2logic(address(1 downto 0) = "11" and byte = '0' and half = '0'));
	write_en(2) <= global_write_en
				  and (bool2logic(address(1 downto 0) = "00" and byte = '0' and half = '0')
				  or bool2logic(address(1 downto 0) = "01" and byte = '0')
				  or bool2logic(address(1 downto 0) = "10")
				  or bool2logic(address(1 downto 0) = "11" and byte = '0' and half = '0'));
	read_en(3) <= global_read_en
				  and (bool2logic(address(1 downto 0) = "00" and byte = '0' and half = '0')
				  or bool2logic(address(1 downto 0) = "01" and byte = '0' and half = '0')
				  or bool2logic(address(1 downto 0) = "10" and byte = '0')
				  or bool2logic(address(1 downto 0) = "11"));
	write_en(3) <= global_write_en
				  and (bool2logic(address(1 downto 0) = "00" and byte = '0' and half = '0')
				  or bool2logic(address(1 downto 0) = "01" and byte = '0' and half = '0')
				  or bool2logic(address(1 downto 0) = "10" and byte = '0')
				  or bool2logic(address(1 downto 0) = "11"));
	
	
	-- Main memory module
	-- Increment each module address that is before address(1 downto 0)
	addr_wrap_around(0) <= std_logic_vector(
						unsigned(address)
						+ SHIFT_LEFT(unsigned(
							bool2slv(unsigned(address(1 downto 0)) > to_unsigned(0, 2), 32)
						  ), 2)
					);
	addr_wrap_around(1) <= std_logic_vector(
						unsigned(address)
						+ SHIFT_LEFT(unsigned(
							bool2slv(unsigned(address(1 downto 0)) > to_unsigned(1, 2), 32)
						  ), 2)
					);
	addr_wrap_around(2) <= std_logic_vector(
						unsigned(address)
						+ SHIFT_LEFT(unsigned(
							bool2slv(unsigned(address(1 downto 0)) > to_unsigned(2, 2), 32)
						  ), 2)
					);
	addr_wrap_around(3) <= address;
	U_DATA_MEM : for i in 0 to 3 generate
		U_DATA_MODULE: entity work.data_memory
			port map (
				rdaddress => addr_wrap_around(i)(9 downto 2),
				wraddress => addr_wrap_around(i)(9 downto 2),
				rdclock => clk,
				wrclock => notclk,
				data => write_output((31 - i*8) downto (24 - i*8)),
				rden => read_en(i),
				wren => write_en(i),
				q => mem_output((31 - i*8) downto (24 - i*8))
			);
	end generate;
	
	
	-- Now do the same thing for reads
	process(address, data, rden, wren, byte, half, mem_output)
		variable sel : std_logic_vector(3 downto 0);
	begin
		output <= (others => '0');
		-- Only output if reading (the altsyncram doesn't clear mem_output
		-- for some reason)
		if(rden = '1') then
			sel := byte & half & address(1 downto 0);
			case sel is
				-- Byte = 1
				when "1000" =>
					output(7 downto 0) <= mem_output(31 downto 24);
				when "1001" =>
					output(7 downto 0) <= mem_output(23 downto 16);
				when "1010" =>
					output(7 downto 0) <= mem_output(15 downto 8);
				when "1011" =>
					output(7 downto 0) <= mem_output(7 downto 0);
				
				-- Half word = 1
				when "0100" =>
					output(15 downto 0) <= mem_output(31 downto 16);
				when "0101" =>
					output(15 downto 0) <= mem_output(23 downto 8);
				when "0110" =>
					output(15 downto 0) <= mem_output(15 downto 0);
				when "0111" =>
					output(15 downto 0) <= mem_output(7 downto 0) & mem_output(31 downto 24);
			
			
				-- Full word
				when "0000" =>
					output(31 downto 0) <= mem_output(31 downto 0);
				when "0001" =>
					output(31 downto 0) <= mem_output(23 downto 0) & mem_output(31 downto 24);
				when "0010" =>
					output(31 downto 0) <= mem_output(15 downto 0) & mem_output(31 downto 16);
				when "0011" =>
					output(31 downto 0) <= mem_output(7 downto 0) & mem_output(31 downto 8);
					
				when others => null;
			end case;
			
		end if;
	end process;

end architecture;