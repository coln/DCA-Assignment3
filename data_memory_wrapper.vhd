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
	signal read_en : std_logic_vector(3 downto 0);
	signal write_en : std_logic_vector(3 downto 0);
	signal address_temp : std_logic_vector(WIDTH-1 downto 0);
	type byte_addr_array is array(3 downto 0) of std_logic_vector(1 downto 0);
	signal byte_addr_wr : byte_addr_array;
	
	signal byte_mux_wr : std_logic_vector(WIDTH-1 downto 0);
	signal half_mux_wr : std_logic_vector(WIDTH-1 downto 0);
	signal word_mux_wr : std_logic_vector(WIDTH-1 downto 0);
	
	type temp_array is array (3 downto 0) of std_logic_vector(WIDTH-1 downto 0);
	signal byte_mux_wr_temp : temp_array;
	signal half_mux_wr_temp : temp_array;
	signal word_mux_wr_temp : temp_array;
	
	
	signal byte_mux_rd : std_logic_vector(WIDTH-1 downto 0);
	signal half_mux_rd : std_logic_vector(WIDTH-1 downto 0);
	signal half_mux_rd_temp : std_logic_vector((WIDTH/2)-1 downto 0);
	signal word_mux_rd : std_logic_vector(WIDTH-1 downto 0);
	signal word_mux_rd_temp1 : std_logic_vector(WIDTH-1 downto 0);
	signal word_mux_rd_temp2 : std_logic_vector(WIDTH-1 downto 0);
	signal word_mux_rd_temp3 : std_logic_vector(WIDTH-1 downto 0);
	signal mem_data_sel : std_logic_vector(1 downto 0);
	signal mem_data : std_logic_vector(WIDTH-1 downto 0);
	signal mem_output : std_logic_vector(WIDTH-1 downto 0);
begin

	-- The following muxes simply rotate the data, so that it can be byte addressable
	byte_addr_wr(3)(1) <= not address(1);
	byte_addr_wr(3)(0) <= not address(0);
	byte_addr_wr(2)(1) <= not (address(1) xor address(0));
	byte_addr_wr(2)(0) <= address(0);
	byte_addr_wr(1)(1) <= address(1);
	byte_addr_wr(1)(0) <= not address(0);
	byte_addr_wr(0)(1) <= address(1) xor address(0);
	byte_addr_wr(0)(0) <= address(0);
	
	-- We are byte addressing, only allow a single byte through (the LSB)
	byte_mux_wr_temp(0)(31 downto 24) <= data(7 downto 0);
	byte_mux_wr_temp(0)(23 downto 0) <= (others => '0');
	byte_mux_wr_temp(1)(31 downto 24) <= (others => '0');
	byte_mux_wr_temp(1)(23 downto 16) <= data(7 downto 0);
	byte_mux_wr_temp(1)(15 downto 0) <= (others => '0');
	byte_mux_wr_temp(2)(31 downto 16) <= (others => '0');
	byte_mux_wr_temp(2)(15 downto 8) <= data(7 downto 0);
	byte_mux_wr_temp(2)(7 downto 0) <= (others => '0');
	byte_mux_wr_temp(3)(31 downto 8) <= (others => '0');
	byte_mux_wr_temp(3)(7 downto 0) <= data(7 downto 0);
	U_BYTE_MUX : entity work.mux4
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => address(1 downto 0),
			in0 => byte_mux_wr_temp(0),
			in1 => byte_mux_wr_temp(1),
			in2 => byte_mux_wr_temp(2),
			in3 => byte_mux_wr_temp(3),
			output => byte_mux_wr
		);
	
	half_mux_wr_temp(0)(31 downto 16) <= data(15 downto 0);
	half_mux_wr_temp(0)(15 downto 0) <= (others => '0');
	half_mux_wr_temp(1)(31 downto 24) <= (others => '0');
	half_mux_wr_temp(1)(23 downto 8) <= data(15 downto 0);
	half_mux_wr_temp(1)(7 downto 0) <= (others => '0');
	half_mux_wr_temp(2)(31 downto 16) <= (others => '0');
	half_mux_wr_temp(2)(15 downto 0) <= data(15 downto 0);
	half_mux_wr_temp(3)(31 downto 24) <= data(7 downto 0);
	half_mux_wr_temp(3)(23 downto 8) <= (others => '0');
	half_mux_wr_temp(3)(7 downto 0) <= data(15 downto 8);
	U_HALF_MUX : entity work.mux4
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => address(1 downto 0),
			in0 => half_mux_wr_temp(0),
			in1 => half_mux_wr_temp(1),
			in2 => half_mux_wr_temp(2),
			in3 => half_mux_wr_temp(3),
			output => half_mux_wr
		);
	
	word_mux_wr_temp(0)(31 downto 0) <= data(31 downto 0);
	word_mux_wr_temp(1)(23 downto 0) <= data(31 downto 8);
	word_mux_wr_temp(1)(31 downto 24) <= data(7 downto 0);
	word_mux_wr_temp(2)(15 downto 0) <= data(31 downto 16);
	word_mux_wr_temp(2)(31 downto 16) <= data(15 downto 0);
	word_mux_wr_temp(3)(7 downto 0) <= data(31 downto 24);
	word_mux_wr_temp(3)(31 downto 8) <= data(23 downto 0);
	U_WORD_MUX : entity work.mux4
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => address(1 downto 0),
			in0 => word_mux_wr_temp(0),
			in1 => word_mux_wr_temp(1),
			in2 => word_mux_wr_temp(2),
			in3 => word_mux_wr_temp(3),
			output => word_mux_wr
		);
	
	-- Select between byte, half word, and word store
	mem_data_sel(1) <= byte;
	mem_data_sel(0) <= half;
	U_DATA_MUX : entity work.mux4
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => mem_data_sel,
			in0 => word_mux_wr,
			in1 => half_mux_wr,
			in2 => byte_mux_wr,
			in3 => (others => '0'),
			output => mem_data
		);
	
	
	
	
	
	
	-- Main memory module
	read_en(0) <= not rst
				  and rden
				  and bool2logic(address(31 downto 10) = DATA_BASE_ADDR(31 downto 10))
				  and bool2logic((address(1 downto 0) = "00")
				  		or (address(1 downto 0) = "01" and (byte = '0' and half = '0'))
				  		or (address(1 downto 0) = "10" and (byte = '0' and half = '0'))
				  		or (address(1 downto 0) = "11" and byte = '0')
				  );
	write_en(0) <= not rst
				   and wren
				   and bool2logic(address(31 downto 10) = DATA_BASE_ADDR(31 downto 10))
				   and bool2logic((address(1 downto 0) = "00")
				  		or (address(1 downto 0) = "01" and (byte = '0' and half = '0'))
				  		or (address(1 downto 0) = "10" and (byte = '0' and half = '0'))
				  		or (address(1 downto 0) = "11" and byte = '0')
				  );
	U_DATA_MEMORY0: entity work.data_memory
		port map (
			address => address(9 downto 2),
			clock => clk,
			data => mem_data(31 downto 24),
			rden => read_en(0),
			wren => write_en(1),
			q => mem_output(31 downto 24)
		);
	read_en(1) <= not rst
				  and rden
				  and bool2logic(address(31 downto 10) = DATA_BASE_ADDR(31 downto 10))
				  and bool2logic((address(1 downto 0) = "00" and byte = '0')
				  		or (address(1 downto 0) = "01")
				  		or (address(1 downto 0) = "10" and (byte = '0' and half = '0'))
				  		or (address(1 downto 0) = "11" and (byte = '0' and half = '0'))
				  );
	write_en(1) <= not rst
				   and wren
				   and bool2logic(address(31 downto 10) = DATA_BASE_ADDR(31 downto 10))
				   and bool2logic((address(1 downto 0) = "00" and byte = '0')
				  		or (address(1 downto 0) = "01")
				  		or (address(1 downto 0) = "10" and byte = '0' and half = '0')
				  		or (address(1 downto 0) = "11" and byte = '0' and half = '0')
				  );
	U_DATA_MEMORY1: entity work.data_memory
		port map (
			address => address(9 downto 2),
			clock => clk,
			data => mem_data(23 downto 16),
			rden => read_en(1),
			wren => write_en(1),
			q => mem_output(23 downto 16)
		);
	read_en(2) <= not rst
				  and rden
				  and bool2logic(address(31 downto 10) = DATA_BASE_ADDR(31 downto 10))
				  and bool2logic((address(1 downto 0) = "00" and (byte = '0' and half = '0'))
				  		or (address(1 downto 0) = "01" and not byte = '0')
				  		or (address(1 downto 0) = "10")
				  		or (address(1 downto 0) = "11" and (byte = '0' and half = '0'))
				  );
	write_en(2) <= not rst
				   and wren
				   and bool2logic(address(31 downto 10) = DATA_BASE_ADDR(31 downto 10))
				   and bool2logic((address(1 downto 0) = "00" and (byte = '0' and half = '0'))
				  		or (address(1 downto 0) = "01" and not byte = '0')
				  		or (address(1 downto 0) = "10")
				  		or (address(1 downto 0) = "11" and (byte = '0' and half = '0'))
				  );
	U_DATA_MEMORY2: entity work.data_memory
		port map (
			address => address(9 downto 2),
			clock => clk,
			data => mem_data(15 downto 8),
			rden => read_en(2),
			wren => write_en(2),
			q => mem_output(15 downto 8)
		);
	read_en(3) <= not rst
				  and rden
				  and bool2logic(address(31 downto 10) = DATA_BASE_ADDR(31 downto 10))
				  and bool2logic((address(1 downto 0) = "00" and (byte = '0' and half = '0'))
				  		or (address(1 downto 0) = "01" and (byte = '0' and half = '0'))
				  		or (address(1 downto 0) = "10" and not byte = '0')
				  		or (address(1 downto 0) = "11")
				  );
	write_en(3) <= not rst
				   and wren
				   and bool2logic(address(31 downto 10) = DATA_BASE_ADDR(31 downto 10))
				   and bool2logic((address(1 downto 0) = "00" and (byte = '0' and half = '0'))
				  		or (address(1 downto 0) = "01" and (byte = '0' and half = '0'))
				  		or (address(1 downto 0) = "10" and not byte = '0')
				  		or (address(1 downto 0) = "11")
				  );
	address_temp <= std_logic_vector(
						unsigned(address)
						+ SHIFT_LEFT(unsigned(bool2slv((half = '1'), 32)), 2)
					);
	U_DATA_MEMORY3: entity work.data_memory
		port map (
			address => address_temp(9 downto 2),
			clock => clk,
			data => mem_data(7 downto 0),
			rden => read_en(3),
			wren => write_en(3),
			q => mem_output(7 downto 0)
		);
	
	
	
	
	
	
	-- Now do the same thing for reads
	U_BYTE_MUX_RD : entity work.mux4
		generic map (
			WIDTH => WIDTH / 4
		)
		port map (
			sel => address(1 downto 0),
			in0 => mem_output(31 downto 24),
			in1 => mem_output(23 downto 16),
			in2 => mem_output(15 downto 8),
			in3 => mem_output(7 downto 0),
			output => byte_mux_rd(7 downto 0)
		);
	byte_mux_rd(WIDTH-1 downto 8) <= (others => '0');
	
	half_mux_rd_temp <= mem_output(7 downto 0) & mem_output(31 downto 24);
	U_HALF_MUX_RD : entity work.mux4
		generic map (
			WIDTH => WIDTH / 2
		)
		port map (
			sel => address(1 downto 0),
			in0 => half_mux_rd_temp,
			in1 => mem_output(31 downto 16),
			in2 => mem_output(23 downto 8),
			in3 => mem_output(15 downto 0),
			output => half_mux_rd(15 downto 0)
		);
	half_mux_rd(WIDTH-1 downto 16) <= (others => '0');
	
	
	word_mux_rd_temp1 <= mem_output(23 downto 0) & mem_output(31 downto 24);
	word_mux_rd_temp2 <= mem_output(15 downto 0) & mem_output(31 downto 16);
	word_mux_rd_temp3 <= mem_output(7 downto 0) & mem_output(31 downto 8);
	U_WORD_MUX_RD : entity work.mux4
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => address(1 downto 0),
			in0 => word_mux_rd_temp3,
			in1 => word_mux_rd_temp2,
			in2 => word_mux_rd_temp1,
			in3 => mem_output(31 downto 0),
			output => word_mux_rd
		);
	
	-- Send final chunk to output
	U_DATA_MUX_RD : entity work.mux4
		generic map (
			WIDTH => WIDTH
		)
		port map (
			sel => mem_data_sel,
			in0 => word_mux_rd,
			in1 => half_mux_rd,
			in2 => byte_mux_rd,
			in3 => (others => '0'),
			output => output
		);
	

end architecture;