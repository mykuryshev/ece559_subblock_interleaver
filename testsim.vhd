library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testsim is

	port(
		clk, reset :  in std_logic;
		output     : out std_logic_vector(7 downto 0)
	);

end testsim;


architecture arch of testsim is

	type STATE_TYPE is (STATE_0, STATE_1);

	signal counter : integer := 0;
	signal counter_next : integer := 0;
	
	signal state : STATE_TYPE;
	signal state_next : STATE_TYPE;
	
begin


	process (clk, reset)
	
	begin
	
		if (reset = '1') then
		
			counter <= 0;
			state   <= STATE_0;
		
		elsif (clk'event and clk='1') then
		
			counter <= counter_next;
			state   <= state_next;
		
		end if;
	
	
	end process;
	
	
	process (state)
	
	begin
	
		counter_next <= counter + 1;
		
	
		case state is
		
			when STATE_0 =>
				state_next <= STATE_1;
			
			when STATE_1 =>
				state_next <= STATE_0;
				
			
		
		end case;
	
	end process;
	
	process (counter)
	begin
		output <= std_logic_vector(to_unsigned(counter, output'length));
	
	end process;
	



end architecture;

