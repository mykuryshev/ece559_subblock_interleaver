library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL;

entity subblock_interleaver_output is 
	port (
		clk,reset                          : in std_logic;
		turbo_ready, conv_ready            : in std_logic;
		turbo_blk1, turbo_blk2, turbo_blk3 : in std_logic_vector(7 downto 0);
		conv_blk1, conv_blk2, conv_blk3    : in std_logic_vector(7 downto 0);
	   turbo_blk_size, conv_blk_size      : in std_logic;
		output    								  : out std_logic;
		done     								  : out std_logic
		);
end entity;

	

architecture out_stage of subblock_interleaver_output is


component output_subblock_controller
	port (
		clk,reset:		 		in std_logic;
		size:					   in std_logic;
		done:                out std_logic;
		column_select:			out std_logic_vector (4 DOWNTO 0);
		row_select:          out std_logic_vector (6 DOWNTO 0); --off by one maybe?
		subblock_select:     out std_logic_vector (1 DOWNTO 0)
		);
end component;

component IL_FSM  
  port (
		clk,reset : in std_logic;
		turbo_ready, conv_ready : in std_logic;
		turbo_blk1, turbo_blk2, turbo_blk3 : in std_logic_vector(7 downto 0);
		conv_blk1, conv_blk2, conv_blk3 : in std_logic_vector(7 downto 0);
		turbo_blk_size, conv_blk_size : in std_logic; -- 0 = 1056, 1 = 6144 
		read_done : in std_logic; --from michael
		rd_addr : in std_logic_vector(12 downto 0); --from ted
		start_read : out std_logic; -- to michael 
		blk_size : out std_logic -- 0 = 1056, 1 = 6144 
		);
end component;

component permute_v3 
	port(
		-- System
		clk       : in std_logic;
		reset     : in std_logic;
		-- Ports for Michael
		row       : in  std_logic_vector(7 downto 0);  -- max unsigned value: 191
		col       : in  std_logic_vector(4 downto 0);  -- max unsinged value: 31
		subblock  : in  std_logic_vector(1 downto 0);  -- max unsinged value: 2
		output    : out std_logic;
		-- Ports for Dhara
		memoryOut : in  std_logic;
		mAddress  : out std_logic_vector(12 downto 0); -- max unsinged value: 6143    Physical address I request from the memory unit.
		ramBlock  : out std_logic_vector (1 downto 0); -- max unsinged value: 2       Which memory unit I request.
		-- Extras (Diagnostic)
		outColPermute : out std_logic_vector(4 downto 0);
		outRowShifted : out std_logic_vector(12 downto 0)
	);
end component;

--necessary connecting signals
	signal row_count:				 std_logic_vector (7 downto 0);
	signal row_count_sel:       std_logic_vector (6 downto 0);
	signal column_count:		 	 std_logic_vector (4 downto 0);
	signal subblock_select:     std_logic_vector (1 DOWNTO 0);
	signal rd_addr: 				 std_logic_vector(12 downto 0); 
	signal start_read:  			 std_logic;
	signal blk_size:  			 std_logic; 
	signal dummy_out:           std_logic;
	signal done_buffer:         std_logic;
	--dead signals, remove from permuter once compiling big time
	signal outColPermute:  		std_logic_vector(4 downto 0);
	signal outRowShifted:  		std_logic_vector(12 downto 0);
	
--map everything so we can connect it all
begin
	main_fsm : IL_FSM PORT MAP (
		clk=>clk,
		reset=>reset,
		turbo_ready=>turbo_ready,
		conv_ready=>conv_ready,
		turbo_blk1=>turbo_blk1,
		turbo_blk2=>turbo_blk2,
		turbo_blk3=>turbo_blk3,
		conv_blk1=>conv_blk1,
		conv_blk2=>conv_blk2,
		conv_blk3=>conv_blk3,
		turbo_blk_size=>turbo_blk_size,
		conv_blk_size=>conv_blk_size,
		read_done=>done_buffer,
		rd_addr=>rd_addr,
		start_read=>start_read,
		blk_size=>blk_size   
	);
	
	counter_control : output_subblock_controller PORT MAP (
		clk=>clk,
		reset=>reset,	
		size=>blk_size,				
		done=>done_buffer,              
		column_select=>column_count,
		row_select=>row_count_sel,  --concatenating an extra 0 until size change determined if needed
		subblock_select=>subblock_select
	);
	
	permuter : permute_v3 PORT MAP (
		clk=>clk,
		reset=>reset,
		row=>row_count,
		col=>column_count,
		subblock=>subblock_select,
		output=>output,
		memoryOut=>dummy_out,         --output in is output out?! need to sync up with dhara/ted as no one is outputting the data
		mAddress=>rd_addr,
		ramBlock=>subblock_select,    --same as subblock? no one uses this output
		outColPermute=>outColPermute, --dead wire
		outRowShifted=>outRowShifted  --dead wire
	);
	
	row_count <= '0' & row_count_sel;
end out_stage;