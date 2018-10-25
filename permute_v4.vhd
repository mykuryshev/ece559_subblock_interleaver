library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity permute_v4 is

	port(
	
		-- System
		clk       : in std_logic;
		reset     : in std_logic;
	
		-- Ports for Michael
		row       : in  std_logic_vector(7 downto 0);  -- max unsigned value: 191
		col       : in  std_logic_vector(4 downto 0);  -- max unsinged value: 31
		
		-- Ports for Dhara
		mAddress  : out std_logic_vector(12 downto 0)  -- max unsinged value: 6143    Physical address I request from the memory unit.
		
	);

end entity;



architecture permute_v4_arch of permute_v4 is

	type columnArray is array (0 to 31) of integer range 0 to 31;

begin

	process(clk, reset) is
		
		constant columnPermutation : columnArray := ( 0, 16, 8, 24, 4, 20, 12, 28, 2, 18, 10, 26, 6, 22, 14, 30, 1, 17, 9, 25, 5, 21, 13, 29, 3, 19, 11, 27, 7, 23, 15, 31 );
		
		variable rowShifted  : std_logic_vector(12 downto 0);
		variable colPermuted  : std_logic_vector (4 downto 0);
		
		
	begin
		
		if (reset = '1') then
		
			-- This unit does not hold state. Nothing to reset.
			
		
		elsif (clk'event and clk = '1') then
		
			-- Perform:  32 * ROW + PERMUTE( COL )
			
			rowShifted   := std_logic_vector(shift_left(resize(unsigned(row), rowShifted'length), 5));
			
			colPermuted  := std_logic_vector(to_unsigned(columnPermutation(to_integer(unsigned(col))), colPermuted'length));
			mAddress     <= std_logic_vector(unsigned(rowShifted) + unsigned(colPermuted));
		
		
		end if;
		
		
	end process;
	

end architecture;

