------------------------------------------------------------
-- Company:			KU Leuven
-- Engineer:		
--
-- Project Name:	
-- Design Name:		
--
-- Create Date:		30/05/2020
-- Module Name:		morse_code_lock_TB - Testbench
-- Revision:		
-- Description:		
--
-- Target Devices:	
--
-- Comments: 		
--
-- Notes: 
-- 		This testbench has been automatically generated using types STD_LOGIC and
-- 		STD_LOGIC_VECTOR for the ports of the unit under test.  Xilinx recommends
-- 		that these types always be used for the top-level I/O of a design in order
-- 		to guarantee that the testbench will bind correctly to the post-implementation 
-- 		simulation model.
------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity morse_code_lock_TB is
end morse_code_lock_TB;

architecture behavior of morse_code_lock_TB is

	-- Component declaration for the Unit Under Test (UUT)
	component morse_code_lock
		port (	
				i_Btn : in STD_LOGIC;
				i_Clk : in STD_LOGIC;
				i_Rst : in STD_LOGIC;
				o_Unlocked : out STD_LOGIC;
				o_Leds : out STD_LOGIC_VECTOR(3 downto 0);
                o_Btn : out STD_LOGIC; -- This and below outputs are needed only for TB
				o_Btn_R : out STD_LOGIC;
				o_PreviousBtn: out std_logic;
				o_FirstLetter : out std_logic_vector(31 downto 0);
				o_SecondLetter : out std_logic_vector(31 downto 0);
				o_Timer : out integer;
				o_IntraCharacters : out integer
			);
    end component;
    

	--Inputs
	signal i_Btn : STD_LOGIC := '0';
	signal i_Clk : STD_LOGIC := '0';
	signal i_Rst : STD_LOGIC := '0';

	--Outputs
	signal o_Btn : STD_LOGIC;
	signal o_Btn_R : STD_LOGIC;
	signal o_PreviousBtn: std_logic;
	signal o_Unlocked : STD_LOGIC;
	signal o_IntraCharacters : integer;
	signal o_Leds : STD_LOGIC_VECTOR(3 downto 0);
	signal o_FirstLetter : std_logic_vector(31 downto 0);
	signal o_SecondLetter : std_logic_vector(31 downto 0);
	signal o_Timer : integer;

	-- Clock period definition
	constant i_Clk_PERIOD : time := 10 ns;
 
begin
 
	-- Instantiate the Unit Under Test (UUT)
	uut : morse_code_lock
	port map (
				i_Btn => i_Btn,
				i_Clk => i_Clk,
				i_Rst => i_Rst,
				o_Btn => o_Btn,
				o_Btn_R => o_Btn_R,
				o_PreviousBtn => o_PreviousBtn,
				o_Unlocked => o_Unlocked,
				o_FirstLetter => o_FirstLetter,
				o_SecondLetter => o_SecondLetter,
				o_IntraCharacters => o_IntraCharacters,
				o_Leds => o_Leds,
				o_Timer => o_Timer
			);

	-- Clock process definitions
	i_Clk_process : process
	begin
		i_Clk <= '0';
		wait for i_Clk_PERIOD/2;
		i_Clk <= '1';
		wait for i_Clk_PERIOD/2;
	end process;
 

	-- Stimulus process
	stim_process: process
	begin		
		-- Activate reset here
		i_Rst <= '1';
		-- Define all inputs here
		i_Btn <= '0';
		wait for i_Clk_PERIOD*2;
		-- Release reset here
		i_Rst <= '0';
        
        wait for i_Clk_PERIOD*2;
		-- Correct passcode
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD*7;

		wait for i_Clk_PERIOD*5; -- Some delay while the door is unlocked - does not interfere with closing mechanism, only for TB to avoid bad passcode
		
		-- Another correct passcode
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD*7;
		
		wait for i_Clk_PERIOD*5; -- Some delay while the door is unlocked - does not interfere with closing mechanism, only for TB to avoid bad passcode
		
		-- Incorrect passcode
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD;
		i_Btn <= '1';
		
		wait for i_Clk_PERIOD*3;
		i_Btn <= '0';
		
		wait for i_Clk_PERIOD*7;
		
		wait;
	end process;

end;
