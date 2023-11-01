library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity debounce is
	generic (
		maxcount				: integer := 500000
	);
	Port (
		switch_db				: out std_logic;
		switch_in     			: in std_logic;
		reset					: in std_logic;
		clk						: in std_logic
	);
end debounce;

architecture behavior of debounce is
	-- we are assuming a max switching time of 10 ms, and a system clock
	-- of 50MHz.  Therefore, we need to count to 500000 to reach 5ms
	signal count				: integer range 0 to maxcount := 0;
	signal in_lead, in_follow 	: std_logic := '0';
	signal input_change 		: std_logic := '0';
	signal change_reg			: std_logic := '0';	
	signal db_reg				: std_logic := '0';

	begin
	-- change in input detector
	input_change <= in_lead xor in_follow;
	in_change_proc: process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset = '0') then
				in_follow <= '0';
				in_lead <= '0';
			else
				in_follow <= in_lead;
				in_lead <= switch_in;
			end if;
		end if;
	end process in_change_proc;
		
	-- count process
	count_proc:  process(clk)
	begin
		if(rising_edge(clk)) then
			if((reset = '0') or (input_change = '1') or (count = maxcount)) then
				count <= 0;
			else
				count <= count + 1;
			end if;
		end if;		
	end process count_proc;
	
	-- debounce process
	switch_db <= db_reg;
	db_proc: process(clk)
		begin
		if(rising_edge(clk)) then
			if(reset = '0') then
				db_reg <= '0';
			elsif(count = maxcount) then
				db_reg <= switch_in;
			end if;
		end if;
	end process db_proc;
end behavior;