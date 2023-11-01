-- vending machine.vhd
-- a finte state machine example
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity vending_machine is
port (
     money             : out unsigned (7 downto 0);
	 product_out       : out std_logic;
	 quarter_out       : out std_logic;
	 dime_out          : out std_logic; 
	 nickel_out        : out std_logic;
	 
	 quarter_in        : in std_logic;
	 dime_in           : in std_logic;
	 nickel_in         : in std_logic;
	 return_money      : in std_logic;
	 
	 reset             : in std_logic;
	 clk               : in std_logic);
	 end vending_machine;
	 
	 architecture behavior of vending_machine is
	 -- state machine
	 type state_type is(rec_coin, disp_prod, disp_quarter, disp_dime, disp_nickel);
	 signal state, nxt_state                : state_type;
	 -- control signals
	 signal quarter_state                    : std_logic  := '0';
	 signal dime_state                       : std_logic  := '0';
	 signal nickel_state                     : std_logic  := '0';
	 signal product_state                    : std_logic  := '0';
	 -- data signals
	 constant target                         : integer := 100;
	 signal money_in                         : integer range 0 to 120 := 0;
	 signal new_money                        : integer range -100 to 145 := 0;
	 -- array of money binary signals
	 signal money_signals                    : std_logic_vector (6 downto 0);
	 
	 begin
	 -- assign outputs
	 money <= to_unsigned (money_in, money'length);
	 quarter_out <= quarter_state;
	 dime_out <= dime_state;
	 nickel_out <= nickel_state;
	 product_out <= product_state;
	 
	 -- 2 process state machine
	 state_proc: process (clk)
	 begin
	 if rising_edge(clk) then
	     if (reset = '0') then
		      state <= rec_coin;
			 else
			 state <= nxt_state;
			 end if;
		end if;
	end process state_proc;
	state_machine: process (state, return_money, money_in)
	begin
	--- intialize nxt_state, control, and output signals
	nxt_state <= state;
	product_state <= '0';   quarter_state <= '0';
	dime_state <= '0';      nickel_state <= '0';
	case state is
	  when rec_coin =>
	     if(return_money = '1') then
		     nxt_state <= disp_quarter;
			 elsif(money_in >= target) then
			 nxt_state <= disp_prod;
			 end if;
			when disp_prod =>
			 product_state <= '1';
			 nxt_state <= disp_dime;
			when disp_quarter =>
			   if(money_in >= 25) then
			        quarter_state <= '1';
				else
				  nxt_state <= disp_dime;
			end if;
			when disp_dime =>
			     if(money_in >= 10) then
				     dime_state <= '1';
				else
					 nxt_state <= disp_nickel;
					 end if;
			when disp_nickel =>
			      if(money_in >= 5) then
				       nickel_state <= '1';
				else
				     nxt_state <= rec_coin;
				end if;
			when others =>
			     nxt_state <= rec_coin;
				 end case;
		end process state_machine;
		
		-- put all signals that change "money_in" into an vector
		money_signals <= product_state & quarter_state & dime_state &
		    nickel_state & quarter_in & dime_in & nickel_in;
		-- process to determine the next amount of money in the system
		new_money_proc: process(money_in, money_signals)
		  begin
		  case money_signals is
		      when "1000000" => -- product_state
			     new_money <= money_in - target;
			  when "0100000" => -- quarter_state
			      new_money <= money_in - 25;
			  when "0010000" => -- dime_state
			      new_money <= money_in - 10;
			  when "0001000" => --nickel_state
			      new_money <= money_in - 5;
			  when "0000100" => -- quarter_in
			       new_money <= money_in + 25;
			  when "0000010" => -- dime_in
			       new_money <= money_in + 10;
			  when "0000001" => -- nickel_in
			       new_money <= money_in + 5;
			  when others =>
			       new_money <= money_in;
	 end case;
	end process new_money_proc;
	
	-- create a register to keep track of the money in the system
	money_proc: process(clk)
	  begin
	  if(rising_edge(clk)) then
	       if (reset = '0') then
		       money_in <= 0;
			   else
		            money_in <= new_money;
			   end if;
			end if;
		end process money_proc;
	end behavior;
				