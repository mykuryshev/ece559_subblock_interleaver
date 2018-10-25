library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL;

entity output_subblock_controller is 
	port (
		clk,reset:		 		in std_logic;
		size:					   in std_logic;
		done:                out std_logic;
		column_select:			out std_logic_vector (4 DOWNTO 0);
		row_select:          out std_logic_vector (6 DOWNTO 0);
		subblock_select:     out std_logic_vector (1 DOWNTO 0)
		);
end entity;

	
--always counting columns to 32
--count rows to 64 (size=1) or 11 (size=0), 3 blocks too 
architecture subblock_select_control of output_subblock_controller is

component counter_7bit
	PORT
	(
		clk_en		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (6 DOWNTO 0)
	);
end component;

component counter_5bit
	PORT
	(
		clk_en		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (4 DOWNTO 0)
	);
end component;

	--assuming reset stays high for us, but can make a counter enable bit instead as well
	signal row_count:				 std_logic_vector (6 downto 0);
	signal column_count:		 	 std_logic_vector (4 downto 0);
	signal count_row_reset, count_col_reset, count_col_enable, count_row_enable, count_enable: std_logic;
	signal row:    unsigned(6 downto 0);
	signal column: unsigned(4 downto 0); 
	
--subblock controller
type state_type is 
		(idle, select1, select2, select3);
	signal state_reg, state_next: state_type;	
begin 
	process (clk, reset)
	begin
		if(reset='1') then state_reg<=idle;
		elsif(clk'event and clk='1') then 
			state_reg<=state_next;
		end if;
	end process;
	
	process (state_reg, clk, reset)  --state logic for subblock selection
	begin
		block_state: case state_reg is
			when idle=> --idle, stay idle until turned on
				count_enable <= '0';
				if (reset='0') then 
					state_next <= select1;
				else 	
					state_next <= idle;
				end if;
			when select1=> --idle, stay idle until turned on
				count_enable <= '0';
				if (reset='0') then 
					state_next <= select2;
				else 	
					state_next <= idle;
				end if;
			when select2=> --idle, stay idle until turned on
				count_enable <= '0';
				if (reset='0') then 
					state_next <= select3;
				else 	
					state_next <= idle;
				end if;
			when select3=> --idle, stay idle until turned on
				if (reset='0') then 
					state_next <= select1;
					count_enable <= '1'; --increase count for the cycle
				else 	
					state_next <= idle;
					count_enable <= '0';
				end if;
		end case block_state;
	end process; 
	
	
	process (state_reg)   --output logic for subblock selection
	begin
		subblock_control_out: case state_reg is
			when idle=>
				subblock_select <= b"00"; --no subblock selected when idle (... fsm won't output)
			when select1=> 
				subblock_select <= b"00"; --select block 1 and on
			when select2=> 
				subblock_select <= b"01";
			when select3=> 
				subblock_select <= b"10";
		end case subblock_control_out;
	end process;
	
	
--counter controller
process (clk, size, count_enable, row_count, column_count, reset, row, column)
	--variable row, column : integer;
	
	begin
		row    <= unsigned(row_count);
		column <= unsigned(column_count);
		
		if (reset='1') then --reset counter states
			count_col_reset<='1';
			count_row_reset<='1';
			count_col_enable <= '1';
			count_row_enable <= '1';
			done<='0';
		elsif (count_enable='1') then
			--logic for counting column counter and checking done

			if ( ((row=63 and size='1') or (row=10 and size='0')) and column=31) then --done, can reset all if want to be safe
				done<='1';
				count_col_reset<='1';
				count_row_reset<='1';
				count_col_enable <= '1';
				count_row_enable <= '1';
			--logic for counting row counter
			elsif ( (row=63 and size='1') or (row=10 and size='0') ) then --reset row and go next column
				count_col_enable <= '1';
				count_row_reset  <= '1';
				count_row_enable <= '1';
				count_col_reset<='0';
				done<='0';
			else --count enable but not at row&column or column's end	
				count_row_enable <= '1';
				count_col_reset<='0';
				count_row_reset<='0';
				count_col_enable<='0';
				done<='0';
			end if;
		else
			--if we aren't counting and not resetting, then nothing can happen to either counter...
			count_col_reset<='0';
			count_row_reset<='0';
			count_col_enable<='0';
			count_row_enable<='0';
			done<='0';
		end if;
end process;		
	
	row_select    <= row_count; --write memory reads out... will be used for count controls as well
	column_select <= column_count;
	
	
--row counter
	row_counter : counter_7bit PORT MAP (
		clk_en => count_row_enable,
		clock => clk,
		sclr => count_row_reset,
		q => row_count
	);

--column counter
	column_counter : counter_5bit PORT MAP (
		clk_en => count_col_enable,
		clock => clk,
		sclr => count_col_reset,
		q => column_count
	);	
--need to have out controls go to memory and then pass that value out...
end subblock_select_control;