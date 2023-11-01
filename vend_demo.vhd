-- vend_demo.vhd
-- a finite state machine example
-- for instantiation on the DE2 board
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity vend_demo is
port (
     out_seg_1                                                   : out std_logic_vector(6 downto 0);
	 out_seg_0                                                   : out std_logic_vector(6 downto 0);
	 
	 product_out                                                 : out std_logic;
	 quarter_out                                                 : out std_logic;
	 dime_out                                                    : out std_logic;
	 nickel_out                                                  : out std_logic;
	 
	 quarter_in                                                  : in std_logic;
	 dime_in                                                     : in std_logic;
	 nickel_in                                                   : in std_logic;
	 return_money                                                : in std_logic;
	 
	 reset                                                       : in std_logic;
	 clk                                                         : in std_logic);
	 end vend_demo;
	 
	 architecture behavior of vend_demo is
	 
	 component vending_machine
	 port (
	      money                                                 : out unsigned(7 downto 0);
		  product_out                                           : out std_logic;
		  quarter_out                                           : out std_logic;
		  dime_out                                              : out std_logic;
		  nickel_out                                            : out std_logic;
		  
		  quarter_in                                            : in std_logic;
		  dime_in                                               : in std_logic;
		  nickel_in                                           : in std_logic;
		  return_money                                          : in std_logic;
		  
		  reset                                                  : in std_logic;
		  clk                                                    : in std_logic);
	end component;
	
	component hex_to_7_seg
	  port (seven_seg                                            : out std_logic_vector (6 downto 0);
	      hex                                                    : in std_logic_vector (3 downto 0));
		 end component;
         component debounce
		     generic (
			      maxcount                                       : integer := 500000
		);
		port (
		    switch_db                                            : out std_logic;
			switch_in                                            : in std_logic;
			reset                                                : in std_logic;
			clk                                                  : in std_logic
		);
	end component;
	
	constant use_db                                                              : boolean := true;
	constant sec_count                                                          : integer := 50000000;
	
	signal seg_1, seg_0                                                         : std_logic_vector (6 downto 0) ;
	signal money_sig                                                            : unsigned (7 downto 0) ;
	signal q_out_sig, d_out_sig, n_out_sig                                      : std_logic;
	signal p_out_sig                                                            : std_logic;
	signal p_count                                                              : integer range  0 to sec_count := 0;
	signal q_count                                                              : integer range 0 to 3*sec_count :=
	0;
	signal d_count                                                              : integer range 0 to 2*sec_count :=
	0;
	signal n_count                                                              : integer range 0 to sec_count := 0;
	
	signal quarter_lead, quarter_follow, quarter_sig                            : std_logic;
    signal dime_lead, dime_follow, dime_sig                                     : std_logic;
	signal nickel_lead, nickel_follow, nickel_sig                               : std_logic;
	signal return_lead, return_follow, return_sig                               : std_logic;
	
	signal quarter_db, dime_db                                                  : std_logic;
	signal nickel_db, return_db                                                 : std_logic;

begin
      -- assign outputs
      out_seg_1 <= seg_1;
      out_seg_0 <= seg_0;
     
     -- instantiation of components
     vend_map  : vending_machine
         port map (money_sig, p_out_sig, q_out_sig, d_out_sig, n_out_sig,
		       quarter_sig, dime_sig, nickel_sig, return_sig, reset, clk);
     seg_1_map : hex_to_7_seg port map (seg_1, std_logic_vector(money_sig(7 downto 4)));
     seg_0_map : hex_to_7_seg port map (seg_0, std_logic_vector(money_sig(3 downto 0)));

    -- debounce the input signals
    db_circuitry  : if use_db = true generate
       quarter_bounce  : debounce port map (quarter_db, quarter_in, reset, clk);
       dime_bounce : debounce port map( dime_db, dime_in, reset, clk);
       nickel_bounce : debounce port map (nickel_db, nickel_in, reset, clk);
       return_bounce :  debounce port map (return_db, return_money, reset, clk);
    end generate;
    nodb_circuitry  : if use_db = false generate
         quarter_db <= quarter_in;
		 dime_db  <= dime_in;
		 nickel_db <= nickel_in;
		 return_db <= return_money;
	end generate;
	
	-- edge triggering for inputs
	quarter_sig <= quarter_lead and not quarter_follow;
	dime_sig <= dime_lead and not dime_follow;
	nickel_sig <= nickel_lead and not nickel_follow;
	return_sig <= not return_lead and return_follow;
	edge_proc : process (clk)
	begin
	    if(rising_edge(clk)) then
		    if(reset = '0') then
		     quarter_lead <= '0';
			 quarter_follow <= '0';
			 dime_lead <= '0';
			 dime_follow <= '0';
			 nickel_lead <= '0';
			 nickel_follow <= '0';
			 return_lead <= '0';
			 return_follow <= '0';
		else
		    quarter_lead <= quarter_db;
			quarter_follow <= quarter_lead;
			dime_lead <= dime_db;
			dime_follow <= dime_lead;
			nickel_lead <= nickel_db;
			nickel_follow <= nickel_lead;
			return_lead <= return_db;
			return_follow <= return_lead;
		end if;
	end if;
	end process edge_proc;
	
	-- counters for outputs
	q_count_proc  : process (clk)
	begin 
	     if(rising_edge(clk)) then
		     quarter_out <= '0';
			 if(reset = '0') then
			    q_count <= 0;
			elsif(q_out_sig = '1') then
			     q_count <= q_count + sec_count;
			elsif(q_count > 0) then
			     q_count <= q_count -1;
				 quarter_out <= '1';
		    end if;
		end if;
	end process q_count_proc;
	d_count_proc : process(clk)
	begin
	    if(rising_edge(clk)) then
		    dime_out <= '0';
			if(reset = '0') then
			    d_count <= 0;
			elsif(d_out_sig = '1') then
			      d_count <= d_count + sec_count;
			elsif(d_count > 0) then
			    d_count <= d_count - 1;
				dime_out <= '1';
		end if;
	end if;
	end process d_count_proc;
	n_count_proc  : process(clk)
	begin
	    if(rising_edge(clk)) then
		   nickel_out <= '0';
		   if(reset = '0') then
		        n_count <= 0;
		   elsif(n_out_sig = '1') then
		      n_count <= n_count + sec_count;
		   elsif(n_count > 0)  then
		       n_count <= n_count - 1;
			   nickel_out <= '1';
			end if;
		end if;
	end process  n_count_proc;
	p_count_proc : process (clk)
	begin
	     if(rising_edge (clk)) then
		    product_out <= '0';
			if (reset = '0') then
			     p_count <= 0;
			elsif(p_out_sig = '1') then
			    p_count <= p_count + sec_count;
			elsif(p_count > 0) then
			     p_count<= p_count - 1;
				 product_out <= '1';
			end if;
		end if;
		end process p_count_proc;
		
		end behavior;
	