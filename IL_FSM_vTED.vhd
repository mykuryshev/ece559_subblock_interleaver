library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IL_FSM is 
	port (
		clk,reset                           : in  std_logic;
		turbo_ready, conv_ready             : in  std_logic;
		turbo_blk1, turbo_blk2, turbo_blk3  : in  std_logic_vector(7 downto 0);
		conv_blk1, conv_blk2, conv_blk3     : in  std_logic_vector(7 downto 0);
		turbo_blk_size, conv_blk_size       : in  std_logic; -- 0 = 1056, 1 = 6144 
		read_done                           : in  std_logic; -- from read block
		rd_addr                             : in  std_logic_vector(12 downto 0); --from permutate block
		start_read                          : out std_logic; -- to read block 
		blk_size                            : out std_logic -- 0 = 1056, 1 = 6144 
	);
end IL_FSM;

architecture arch of IL_FSM is 
	component RAM
		PORT (
			clock      : IN  STD_LOGIC  := '1';
			data       : IN  STD_LOGIC_VECTOR (0 DOWNTO 0);
			rdaddress  : IN  STD_LOGIC_VECTOR (12 DOWNTO 0);
			wraddress  : IN  STD_LOGIC_VECTOR (12 DOWNTO 0);
			wren		  : IN  STD_LOGIC  := '0';
			q          : OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
		);
	end component;

	--possible states
	type   state_type is (mux_s,collect_s,read_s);
	signal state_curr, state_next: state_type;
	signal next_state_sig : std_logic := '0'; --move from mux -> collect -> read --> mux ...  
	
	--data
	
	signal curr_coder     : std_logic_vector(1 downto 0); -- 00 neither are ready, 01 = conv ready, 10 = turbo ready
	signal curr_blk_size  : std_logic; -- 0 = 1056, 1 = 6144 
	signal data_in_blk1   : std_logic_vector(0 downto 0);
	signal data_in_blk2   : std_logic_vector(0 downto 0);
	signal data_in_blk3   : std_logic_vector(0 downto 0);
	signal data_out_blk1  : std_logic_vector(0 downto 0);
	signal data_out_blk2  : std_logic_vector(0 downto 0);
	signal data_out_blk3  : std_logic_vector(0 downto 0);
	signal output_ind     : integer range 0 to 2;
	
	signal bit_ind        : integer range 0 to 7;
	signal wr_addr        : std_logic_vector(12 downto 0);
	signal wr_en          : std_logic;
	
	begin
 		mem_blk1 : RAM PORT MAP (
			clock      => clk,
			data       => data_in_blk1,
			rdaddress  => rd_addr,
			wraddress  => wr_addr,
			wren       => wr_en,
			q          => data_out_blk1
		);
			
		
 		mem_blk2 : RAM PORT MAP (
			clock      => clk,
			data       => data_in_blk2,
			rdaddress  => rd_addr,
			wraddress  => wr_addr,
			wren       => wr_en,
			q          => data_out_blk2
		);
		
 		mem_blk3 : RAM PORT MAP (
			clock      => clk,
			data       => data_in_blk3,
			rdaddress  => rd_addr,
			wraddress  => wr_addr,
			wren       => wr_en,
			q          => data_out_blk3
		);
		
		process (clk,reset,state_curr,state_next)
		begin
			if(reset = '1') then 
				state_curr <=mux_s;
			elsif(rising_edge(clk)) then
				state_curr <= state_next;
			end if;
		end process;
		
		process (state_curr,reset,next_state_sig)
		begin
			case state_curr is
				when mux_s =>
					if(next_state_sig = '1') then
						state_next <=collect_s;
					else
						state_next <= mux_s;
					end if;
				when collect_s => 
					if(next_state_sig = '1') then
						state_next <= read_s;
					else
						state_next <= collect_s;
					end if;
				when read_s =>
					if(next_state_sig = '1') then
						state_next <= mux_s;
					else 
						state_next <= read_s;
					end if;
			end case;
		end process;
		
		process(state_curr,clk,conv_blk_size,turbo_ready,turbo_blk_size,curr_coder,conv_ready,output_ind)
		begin
			if(state_curr = mux_s and reset = '0') then 
					if(conv_ready = '1') then            -- if conv coder is ready,
						curr_coder <= "01";               -- set current coder to conv coder 
 						curr_blk_size <= conv_blk_size;	 -- set current block size to conv blk size			 
						
						bit_ind <= 0;                     -- set init values that collect state uses 
						wr_addr <= "0000000000000";
						next_state_sig <='1';             -- move to collect state
					elsif(turbo_ready = '1') then
						curr_coder<= "10";
						curr_blk_size <= turbo_blk_siz;
						bit_ind <= 0;                     -- set init values that collect state uses 
						wr_addr <= "0000000000000";
						next_state_sig <='1';             -- move to collect state
					else 
						curr_coder <= "00";               -- if neither coder is ready
						next_state_sig <='0';             -- stay in mux_s until one of them is ready
					end if;
			
			elsif(state_curr = collect_s) then
					if(curr_coder = "01") then                -- collect bits from conv coder every clk
						
						data_in_blk1(0) <= conv_blk1(bit_ind); -- write data_in to mem blks 1,2,3
						data_in_blk2(0) <= conv_blk2(bit_ind); -- iterate bit_ind from 0 to 7 to write 
						data_in_blk3(0) <= conv_blk3(bit_ind); -- 8 bits into memory
						
						wr_en <= '1'; 
						
						if(bit_ind = 7) then
							bit_ind <= 0;
						else
							bit_ind <= bit_ind + 1;
						end if;
						
						if((curr_blk_size = '0' and wr_addr = "0010000011111") or        -- write until wd_addr is   
							(curr_blk_size = '1' and wr_addr = "1100100001010")) then     -- 1055 or 6410
							next_state_sig <= '1';                                        -- move out of collect_s to read_s
						else
							wr_addr <= std_logic_vector(unsigned(wr_addr) + "0000000000001"); -- increment wr_Addr
							next_state_sig <= '0';	                                          -- stay in collect state
						end if;
					end if;
			elsif(state_curr = read_s) then    
				start_read <= '1';            --signal to michael to read memory 
				blk_size <= curr_blk_size;
				if(read_done = '1') then  -- if reading is done
					next_state_sig <= '1'; -- move to mux state 
				else                      -- else 
					next_state_sig <= '0'; -- stay in read state 
				end if;
			end if;
		end process;
	end arch;
