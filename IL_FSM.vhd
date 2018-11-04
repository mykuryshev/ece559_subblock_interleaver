library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FSM_v2 is 
  port (
		clk,reset : in std_logic;
		
		conv_ready,turbo_ready : in std_logic; -- from encoders
		
		collect_done : in std_logic;  --from collector entity 
		read_done : in std_logic;     --from the read entity
		
		start_collect : out std_logic; --start collection
		start_read : out std_logic;    --start reading
		
		curr_coder_out: out std_logic_vector(1 downto 0); --working on conv or turbo or neither (01 or 10 or 00)
		
		--tells current state
		in_mux_s : out std_logic;
		in_collect_s : out std_logic;
		in_read_s : out std_logic
		);
end FSM_v2;

architecture arch of FSM_v2 is 

	
	signal rd_addr : std_logic_vector(12 downto 0);
	signal wr_addr : std_logic_vector(12 downto 0);
	signal wr_en : std_logic;
	signal curr_coder_next : std_logic_vector(1 downto 0);
	signal curr_coder : std_logic_vector(1 downto 0);
	
	type state_type is 
		(mux_s,collect_s,read_s);
	signal state_curr, state_next: state_type;
	
	begin
		
		process (clk,reset)
		begin
			if(reset = '1') then 
				state_curr <=mux_s;
			elsif(clk'event and clk ='1') then
				state_curr <= state_next;
				curr_coder<= curr_coder_next;
				curr_coder_out <= curr_coder_next;
			end if;
		end process;
		
		process (state_curr,reset,conv_ready,turbo_ready,collect_done,read_done)
		begin
			case state_curr is
				when mux_s =>
					if(reset = '0' and (conv_ready ='1' or turbo_ready ='1')) then
						state_next <=collect_s;
					else
						state_next <= mux_s;
					end if;
				when collect_s => 
					if(collect_done = '1') then
						state_next <= read_s;
					else
						state_next <= collect_s;
					end if;
				when read_s =>
					if(read_done = '1') then
						state_next <= mux_s;
					else 
						state_next <= read_s;
					end if;
			end case;
		end process;
		
		process(state_curr) 
		begin
			if(state_curr = mux_s) then
				in_mux_s <= '1';
	 			in_collect_s <= '0';
				in_read_s <= '0';
			elsif(state_curr = collect_s) then
				in_mux_s <= '0';
				in_collect_s <= '1';
				in_read_s <= '0';
			elsif(state_curr = read_s) then
				in_mux_s <= '0';
				in_collect_s <= '0';
				in_read_s <= '1';
			else 
				in_mux_s <= '0';
			   in_collect_s <= '0';
			   in_read_s <= '0';
			end if;
		end process;
		
		process(state_curr,reset,conv_ready,turbo_ready,curr_coder) 
		begin
			if(state_curr = mux_s and reset = '0' and conv_ready = '1') then
				curr_coder_next <= "01";
			elsif(state_curr = mux_s and reset = '0' and turbo_ready = '1') then
				curr_coder_next <= "10";
			elsif(state_curr = mux_s) then
				curr_coder_next <= "00";
			else
				curr_coder_next <= curr_coder;
			end if;
			
			if(state_curr = collect_s) then
				start_collect<='1';
			else
				start_collect<='0';
			end if;
			
			if(state_curr = read_s) then
				start_read<='1';
			else
				start_read<='0';
			end if;
		end process;
		
end arch;
