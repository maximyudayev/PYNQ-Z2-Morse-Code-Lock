----------------------------------------------------------------------------------
-- Company: KU Leuven
-- Engineer: Maxim Yudayev
-- 
-- Create Date: 05/29/2020
-- Design Name: FSM Template
-- Module Name: FSM Template - Behavioral
-- Project Name: Morse Lock
-- Target Devices: PYNQ-Z2
-- Tool Versions: Xilinx 2019.2
-- Description: My Lab4 submission
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: The implementation allows convenient expansion for different initials and LED color settings.
--                      1. For different Morse Lock passcode, replace 32-bit values of c_FIRST_LETTER and c_SECOND_LETTER
--                      2. For different status LED colors, replace 24-bit values of c_LIGHT_SUCCESS and c_LIGHT_FAILURE
--                      with desired 24-bit RGB color value, the program will convert RGB into PWM timings automatically
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity morse_code_lock is
  Port (  
    i_Clk:              in std_logic; -- The Clock 125 MHz
    i_Rst:              in std_logic; -- To reset our Morse code lock
    i_Btn:              in std_logic; -- Our input button
    o_LEDRed:           buffer std_logic;
    o_LEDGreen:         buffer std_logic;
    o_LEDBlue:          buffer std_logic
    
--    o_Btn:              out std_logic; -- This and below outputs are needed only for TB, feel free to remove
--    o_Btn_R:            out std_logic;
--    o_Unlocked:         out std_logic;
--    o_PreviousBtn:      out std_logic;
--    o_Leds:             out std_logic_vector(3 downto 0); -- Just as an example we are going to output a vector of 4 bits
--    o_Timer:            out integer;
--    o_TimerPWMR:        out unsigned(19 downto 0);
--    o_TimerPWMG:        out unsigned(19 downto 0);
--    o_TimerPWMB:        out unsigned(19 downto 0);
--    o_IntraCharacters:  out integer;
--    o_FirstLetter:      out std_logic_vector(31 downto 0);
--    o_SecondLetter:     out std_logic_vector(31 downto 0);
--    o_ONPeriodSuccessR: out unsigned(19 downto 0); 
--    o_ONPeriodSuccessG: out unsigned(19 downto 0);
--    o_ONPeriodSuccessB: out unsigned(19 downto 0);
--    o_ONPeriodFailureR: out unsigned(19 downto 0);
--    o_ONPeriodFailureG: out unsigned(19 downto 0); 
--    o_ONPeriodFailureB: out unsigned(19 downto 0);
--    o_LEDCE:            out std_logic
  );
end morse_code_lock;

architecture Behavioral of morse_code_lock is
  -- FSM elements
  type t_state is  (s_Locked, s_FirstLetter, s_SecondLetter, s_Unlocked, s_WrongCode); -- You can (and should) change the names of the states to something more meaningful.
  signal state : t_state := s_Locked; -- Register that holds the current state
  signal r_PreviousState : t_state := s_Locked; -- Register that holds the current state
  
  -- Double-register input
  signal r_Btn_R :          std_logic := '0'; -- when you click a button, it can bounce (go on and off very rapidly while you press it downwards), by double-flopping you can resolve this problem.
  signal r_Btn :            std_logic := '0';
  signal r_PreviousBtn :    std_logic := '0';
  
  -- Counter
  signal r_Timer :              integer := 0;
  signal r_IntraCharacters :    integer := 0;
  
  -- LED Driver elements
  type t_timerarray is array (0 to 2) of unsigned(19 downto 0); -- [2] - Red, [1] - Green, [0] - Blue
  signal r_ONPeriodsLEDSuccess : t_timerarray; -- Array of 3 20-bit ON periods for PWM driver, 1 for each color
  signal r_ONPeriodsLEDFailure : t_timerarray; -- Array of 3 20-bit ON periods for PWM driver, 1 for each color
  signal r_TimerPWMR :  unsigned(19 downto 0) := "00000000000000000000"; -- 20-bit Timers for PWM driver
  signal r_TimerPWMG :  unsigned(19 downto 0) := "00000000000000000000";
  signal r_TimerPWMB :  unsigned(19 downto 0) := "00000000000000000000";
  signal r_LEDCE :      std_logic := '0';
  
  -- Intermediate code registers (purpose: return wrong code only at the end of the attempt)
  signal r_FirstLetter :    std_logic_vector(31 downto 0) := X"00000000";
  signal r_SecondLetter :   std_logic_vector(31 downto 0) := X"00000000";
  
  -- Constants
  constant c_UOL :                  integer := 125000000; -- When flashing PYNQ-Z2, change to 125'000'000 (1 second per symbol) or whatever other value seen fit
  constant c_INTER_CHAR_GAP_TIME :  integer := 3 * c_UOL;
  constant c_INTER_WORD_GAP_TIME :  integer := 7 * c_UOL;
  constant c_INTRA_CHAR_GAP_TIME :  integer := c_UOL;
  constant c_DIT_TIME :             integer := c_UOL;
  constant c_DAH_TIME :             integer := 3 * c_UOL;
  constant c_DELTA :                integer := c_UOL; -- 100% UOL time delta
  constant c_MAX_INACTION_TIME :    integer := 3 * c_UOL  + c_DELTA;
  constant c_UNLOCKED_TIME :        integer := 3 * c_UOL;
  constant c_WRONG_CODE_TIME :      integer := 3 * c_UOL;
  
  -- Code: replace the initials here for a different pass code
  constant c_FIRST_LETTER :     std_logic_vector(31 downto 0) := X"00000077"; -- M
  constant c_SECOND_LETTER :    std_logic_vector(31 downto 0) := X"00001D77"; -- Y
  
  -- LED driver PWM period: replace the value by the number of count to 50% at specified PL frequency for 100Hz PWM
  constant c_CLOCK_FREQUENCY:       integer := 125000000; -- When flashing PYNQ-Z2, change to 125'000'000
  constant c_PWM_FREQUENCY:         integer := 100;
  constant c_PWM_PERIOD:            integer := c_CLOCK_FREQUENCY / c_PWM_FREQUENCY;
  constant c_PWM_PERIOD_DC50 :      integer := c_PWM_PERIOD / 2; -- Half cycle period of PWM at 50% duty cycle at operating frequency (125MHz in this example)
  
  -- Color pick for fail and success lights
  constant c_LIGHT_SUCCESS :    std_logic_vector(23 downto 0) := X"06AB0C"; -- Bright Green
  constant c_LIGHT_FAILURE :    std_logic_vector(23 downto 0) := X"7400B8"; -- Saturated Purple

  -- Purpose: function that can be used to check if a timer (eg button that was released/pressed for an amount of time) 
  --          is near a certain value (coheres to a dit, dah, infra char gap or inter char gap)
  --          if timer is in the range [value - delta, value + delta] then it returns '1', else it returns '0' 
  function isTimerNearValue(timer : in integer;
                            value : in integer;
                            delta : in integer)
    return boolean is
  begin
    return timer >= value - delta and timer <= value + delta;
  end function isTimerNearValue;
  
  -- Purpose: at start, get on/off periods for RGB timers based on a HEX color
  function getColors(color : in std_logic_vector(23 downto 0))
    return t_timerarray is
    variable Red :          integer;
    variable Green :        integer;
    variable Blue :         integer;
    variable Max :          integer;
    variable timerarray :   t_timerarray;
  begin
    Red :=      to_integer(unsigned(color(23 downto 16)));
    Green :=    to_integer(unsigned(color(15 downto 8)));
    Blue :=     to_integer(unsigned(color(7 downto 0)));
    
    if Red > Green then -- Get the maximum value, it will be the one driven at 50% duty cycle
        if Red > Blue then
            Max := Red;
        else 
            Max := Blue;
        end if;
    else
        if Green > Blue then
            Max := Green;
        else
            Max := Blue;
        end if;
    end if;
    
    timerarray(2) := to_unsigned(c_PWM_PERIOD_DC50 * Red / Max, 20);
    timerarray(1) := to_unsigned(c_PWM_PERIOD_DC50 * Green / Max, 20);
    timerarray(0) := to_unsigned(c_PWM_PERIOD_DC50 * Blue / Max, 20);
    return timerarray;
  end function getColors;
begin
 
  -- Purpose: double-register the incoming data from i_Btn
  -- (removes problems caused by metastabiliy)
  p_DOUBLEFLOP_BTN : process (i_Clk)
  begin
    if rising_edge(i_Clk) then
        r_Btn_R <= i_Btn; -- store the button press in an intermediate register
        r_Btn   <= r_Btn_R; -- store this in the register we use, look up the example in the lab text 2.8 propagation delay to understand why this works...
        r_PreviousBtn <= r_Btn; -- Keep track of previous button state
--        o_Btn_R <= i_Btn;
--        o_Btn   <= r_Btn_R;
--        o_PreviousBtn <= r_Btn;
    end if;
  end process p_DOUBLEFLOP_BTN;
  
  -- Purpose: keep track of how long button is pressed
  p_COUNTER : process (i_Clk)
  begin
    if i_Rst = '1' then
        r_Timer <= 1;
--        o_Timer <= 1;
    else
        if rising_edge(i_Clk) then -- Synchronous counter
            if r_PreviousBtn /= r_Btn
            or r_PreviousState /= state then    -- Synchronous counter reset, activates when button state changes, 
                                                -- when waiting for user interaction in s_Locked or when transitioning between states
                r_Timer <= 1;
--                o_Timer <= 1;
            else
                r_Timer <= r_Timer + 1;
--                o_Timer <= r_Timer + 1;
            end if;
        end if;
    end if;
  end process p_COUNTER;

  -- Purpose: State machine
  p_STATE_FLOW : process (i_Clk)
  begin
    if i_Rst = '1' then -- Asynchronous state machine reset
        state <= s_Locked;
        r_PreviousState <= s_Locked;
    else
        if rising_edge(i_Clk) then -- Synchronous state transitions (Moore machine)
            r_PreviousState <= state;
            case state is
                when s_Locked =>
                    if r_Btn = '0' then
                        state <= s_Locked;
                    else
                        state <= s_FirstLetter; -- User starts entering code
                    end if;
              
                when s_FirstLetter =>
                    if r_Btn /= r_PreviousBtn and r_Btn = '0' then -- Digit state change to 0
                        if isTimerNearValue(r_Timer, c_DAH_TIME, c_DELTA) nor isTimerNearValue(r_Timer, c_DIT_TIME, c_DELTA) then
                            state <= s_WrongCode; -- Timing is not met
                        end if;
                     
                    elsif r_Btn /= r_PreviousBtn and r_Btn = '1' then -- Digit state change to 1
                        if isTimerNearValue(r_Timer, c_INTER_CHAR_GAP_TIME, c_DELTA) then -- Inter character gap
                            state <= s_SecondLetter;
                        elsif isTimerNearValue(r_Timer, c_INTER_CHAR_GAP_TIME, c_DELTA) nor isTimerNearValue(r_Timer, c_INTRA_CHAR_GAP_TIME, c_DELTA) then
                            state <= s_WrongCode; -- Timing is not met
                        end if;
                        
                    elsif r_Timer > c_MAX_INACTION_TIME then -- User inacts longer than 3 UOL + Delta
                        state <= s_WrongCode;
                    end if;
                    
                    if r_IntraCharacters > 5 then -- User tries to exceed length spec of a Morse Code character
                        state <= s_WrongCode;
                    end if;
                
                when s_SecondLetter =>
                    if r_Btn /= r_PreviousBtn and r_Btn = '0' then -- Digit state change to 0
                        if isTimerNearValue(r_Timer, c_DAH_TIME, c_DELTA) nor isTimerNearValue(r_Timer, c_DIT_TIME, c_DELTA) then
                            state <= s_WrongCode; -- Timing is not met
                        end if;
                    
                    elsif r_Btn /= r_PreviousBtn and r_Btn = '1' then -- Digit state change to 1
                        if true xor isTimerNearValue(r_Timer, c_INTRA_CHAR_GAP_TIME, c_DELTA) then -- XOR with '1' is just an inverter
                            state <= s_WrongCode; -- Timing is not met
                        end if;
                    
                    elsif r_PreviousBtn = '1' and r_Timer > 3 * c_UOL + c_DELTA then -- User inacts longer than 3 UOL + Delta while pressing button
                        state <= s_WrongCode;
                    
                    elsif isTimerNearValue(r_Timer, c_INTER_WORD_GAP_TIME, c_DELTA) and r_PreviousBtn = '0' then -- Inter word gap
                        if r_FirstLetter = c_FIRST_LETTER and r_SecondLetter = c_SECOND_LETTER then -- Verify code combination
                            state <= s_Unlocked;
                        else
                            state <= s_WrongCode;
                        end if;
                    end if;
                
                    if r_IntraCharacters > 5 then -- User tries to exceed length spec of a Morse Code character
                        state <= s_WrongCode;
                    end if;
             
                when s_Unlocked =>
                    if isTimerNearValue(r_Timer, c_UNLOCKED_TIME, c_DELTA) then -- After being unlocked for specified time
                        state <= s_Locked;
                    end if;
                
                when s_WrongCode =>
                    if isTimerNearValue(r_Timer, c_WRONG_CODE_TIME, c_DELTA) then -- After flashing failed LED for specified time
                        state <= s_Locked;
                    end if;
                         
                when others =>
                    state <= s_Locked;
            end case;
        end if;
    end if;
  end process p_STATE_FLOW;
  
  -- Purpose: State tasks, what needs to happen in a state at each clock edge
  p_STATE_PROCESS : process(i_Clk)
  begin
    if i_Rst = '1' then
        r_FirstLetter <= X"00000000";
        r_SecondLetter <= X"00000000";
        r_IntraCharacters <= 0;
--        o_FirstLetter <= X"00000000";
--        o_SecondLetter <= X"00000000";
--        o_IntraCharacters <= 0;
    else
        if rising_edge(i_Clk) then -- Synchronous state processes (Moore machine)
            case state is
                when s_Locked =>
                    r_FirstLetter <= X"00000000";
                    r_SecondLetter <= X"00000000";
                    r_IntraCharacters <= 0;
--                    o_FirstLetter <= X"00000000";
--                    o_SecondLetter <= X"00000000";
--                    o_IntraCharacters <= 0;
                
                when s_FirstLetter =>
                    if r_Btn /= r_PreviousBtn and r_Btn = '0' then -- Digit state change to 0
                        if isTimerNearValue(r_Timer, c_DAH_TIME, c_DELTA) then -- User entered one DAH
                            r_FirstLetter <= r_FirstLetter(28 downto 0) & "111"; -- Right pad with ones
--                            o_FirstLetter <= r_FirstLetter(28 downto 0) & "111"; -- Right pad with ones
                            r_IntraCharacters <= r_IntraCharacters + 1;
--                            o_IntraCharacters <= r_IntraCharacters + 1;
                        elsif isTimerNearValue(r_Timer, c_DIT_TIME, c_DELTA) then -- User entered one DIT
                            r_FirstLetter <= r_FirstLetter(30 downto 0) & "1"; -- Right pad with one
--                            o_FirstLetter <= r_FirstLetter(30 downto 0) & "1"; -- Right pad with one
                            r_IntraCharacters <= r_IntraCharacters + 1;
--                            o_IntraCharacters <= r_IntraCharacters + 1;
                        end if;
                     
                    elsif r_Btn /= r_PreviousBtn and r_Btn = '1' then -- Digit state change to 1
                        if isTimerNearValue(r_Timer, c_INTER_CHAR_GAP_TIME, c_DELTA) then -- Inter character gap
                            r_IntraCharacters <= 0;
--                            o_IntraCharacters <= 0;
                        elsif isTimerNearValue(r_Timer, c_INTRA_CHAR_GAP_TIME, c_DELTA) then -- Intra character gap
                            r_FirstLetter <= r_FirstLetter(30 downto 0) & "0"; -- Right pad with zero
--                            o_FirstLetter <= r_FirstLetter(30 downto 0) & "0"; -- Right pad with zero
                        end if;
                     end if;
                     
                when s_SecondLetter =>
                    if r_Btn /= r_PreviousBtn and r_Btn = '0' then -- Digit state change to 0
                        if isTimerNearValue(r_Timer, c_DAH_TIME, c_DELTA) then -- User entered one DAH
                            r_SecondLetter <= r_SecondLetter(28 downto 0) & "111"; -- Right pad with ones
--                            o_SecondLetter <= r_SecondLetter(28 downto 0) & "111"; -- Right pad with ones
                            r_IntraCharacters <= r_IntraCharacters + 1;
--                            o_IntraCharacters <= r_IntraCharacters + 1;
                        elsif isTimerNearValue(r_Timer, c_DIT_TIME, c_DELTA) then -- User entered one DIT
                            r_SecondLetter <= r_SecondLetter(30 downto 0) & "1"; -- Right pad with one
--                            o_SecondLetter <= r_SecondLetter(30 downto 0) & "1"; -- Right pad with one
                            r_IntraCharacters <= r_IntraCharacters + 1;
--                            o_IntraCharacters <= r_IntraCharacters + 1;
                        end if;
                
                    elsif r_Btn /= r_PreviousBtn and r_Btn = '1' then -- Digit state change to 1
                        if isTimerNearValue(r_Timer, c_INTRA_CHAR_GAP_TIME, c_DELTA) then -- Intra character gap
                            r_SecondLetter <= r_SecondLetter(30 downto 0) & "0"; -- Right pad with zero
--                            o_SecondLetter <= r_SecondLetter(30 downto 0) & "0"; -- Right pad with zero
                        end if;
                    end if;
                    
                when others =>                    
            end case;
        end if;
    end if;
  end process p_STATE_PROCESS;
  
  -- Purpose: Transition state, what needs to happen when the state of the FSM changes
  p_STATE_TRANSITION : process(state)
  begin
    if i_Rst = '1' then
--        o_Unlocked <= '0';
        r_LEDCE <= '0';
--        o_LEDCE <= '0';
    else
        case state is
          when s_Locked =>
--            o_Leds <= "0000";
--            o_Unlocked <= '0';
            r_LEDCE <= '0';
--            o_LEDCE <= '0';
          when s_FirstLetter =>
--            o_Leds <= "0001";
          when s_SecondLetter =>
--            o_Leds <= "0010";
          when s_Unlocked =>
--            o_Leds <= "0100";
--            o_Unlocked <= '1'; -- Unlock
            r_LEDCE <= '1';
--            o_LEDCE <= '1';
          when s_WrongCode =>
--            o_Leds <= "1000";
            r_LEDCE <= '1';
--            o_LEDCE <= '1';
        end case;
    end if;
  end process p_STATE_TRANSITION;
  
  -- Purpose: Drive RGB LED to indicate lock state
  p_RGB_LED_DRIVER : process(i_Clk)
  begin
    if i_Rst = '1' then
        r_ONPeriodsLEDSuccess <= getColors(c_LIGHT_SUCCESS);
        r_ONPeriodsLEDFailure <= getColors(c_LIGHT_FAILURE);
        
--        o_ONPeriodSuccessR <= r_ONPeriodsLEDSuccess(2);
--        o_ONPeriodFailureR <= r_ONPeriodsLEDFailure(2);
--        o_ONPeriodSuccessG <= r_ONPeriodsLEDSuccess(1);
--        o_ONPeriodFailureG <= r_ONPeriodsLEDFailure(1);
--        o_ONPeriodSuccessB <= r_ONPeriodsLEDSuccess(0);
--        o_ONPeriodFailureB <= r_ONPeriodsLEDFailure(0);
        
        r_TimerPWMR <= "00000000000000000001";
        r_TimerPWMG <= "00000000000000000001";
        r_TimerPWMB <= "00000000000000000001";
--        o_TimerPWMR <= "00000000000000000001";
--        o_TimerPWMG <= "00000000000000000001";
--        o_TimerPWMB <= "00000000000000000001";
        
        o_LEDRed <= '0';
        o_LEDGreen <= '0';
        o_LEDBlue <= '0';
    else
        if rising_edge(i_Clk) then -- Synchronous counting for all 3 timers
            if r_LEDCE = '1' then
                r_TimerPWMR <= to_unsigned(to_integer(r_TimerPWMR) + 1,20);
                r_TimerPWMG <= to_unsigned(to_integer(r_TimerPWMG) + 1,20);
                r_TimerPWMB <= to_unsigned(to_integer(r_TimerPWMB) + 1,20);
--                o_TimerPWMR <= to_unsigned(to_integer(r_TimerPWMR) + 1,20);
--                o_TimerPWMG <= to_unsigned(to_integer(r_TimerPWMG) + 1,20);
--                o_TimerPWMB <= to_unsigned(to_integer(r_TimerPWMB) + 1,20);
            else
                r_TimerPWMR <= "00000000000000000001";
                r_TimerPWMG <= "00000000000000000001";
                r_TimerPWMB <= "00000000000000000001";
--                o_TimerPWMR <= "00000000000000000001";
--                o_TimerPWMG <= "00000000000000000001";
--                o_TimerPWMB <= "00000000000000000001";
                o_LEDRed <= '0';
                o_LEDGreen <= '0';
                o_LEDBlue <= '0';
            end if;
            
            case state is
                when s_WrongCode =>
                    if o_LEDRed = '1' and to_integer(r_TimerPWMR) >= to_integer(r_ONPeriodsLEDFailure(2)) then
                        o_LedRed <= '0';
                        r_TimerPWMR <= "00000000000000000001";
--                        o_TimerPWMR <= "00000000000000000001";
                    elsif o_LEDRed = '0' and to_integer(r_TimerPWMR) >= c_PWM_PERIOD - to_integer(r_ONPeriodsLEDFailure(2)) then
                        o_LedRed <= '1';
                        r_TimerPWMR <= "00000000000000000001";
--                        o_TimerPWMR <= "00000000000000000001";
                    end if;
                    
                    if o_LEDGreen = '1' and to_integer(r_TimerPWMG) >= to_integer(r_ONPeriodsLEDFailure(1)) then
                        o_LedGreen <= '0';
                        r_TimerPWMG <= "00000000000000000001";
--                        o_TimerPWMG <= "00000000000000000001";
                    elsif o_LEDGreen = '0' and to_integer(r_TimerPWMG) >= c_PWM_PERIOD - to_integer(r_ONPeriodsLEDFailure(1)) then
                        o_LedGreen <= '1';
                        r_TimerPWMG <= "00000000000000000001";
--                        o_TimerPWMG <= "00000000000000000001";
                    end if;
                    
                    if o_LEDBlue = '1' and to_integer(r_TimerPWMB) >= to_integer(r_ONPeriodsLEDFailure(0)) then
                        o_LedBlue <= '0';
                        r_TimerPWMB <= "00000000000000000001";
--                        o_TimerPWMB <= "00000000000000000001";
                    elsif o_LEDBlue = '0' and to_integer(r_TimerPWMB) >= c_PWM_PERIOD - to_integer(r_ONPeriodsLEDFailure(0)) then
                        o_LedBlue <= '1';
                        r_TimerPWMB <= "00000000000000000001";
--                        o_TimerPWMB <= "00000000000000000001";
                    end if;
                
                when s_Unlocked =>
                    if o_LEDRed = '1' and to_integer(r_TimerPWMR) >= to_integer(r_ONPeriodsLEDSuccess(2)) then
                        o_LedRed <= '0';
                        r_TimerPWMR <= "00000000000000000001";
--                        o_TimerPWMR <= "00000000000000000001";
                    elsif o_LEDRed = '0' and to_integer(r_TimerPWMR) >= c_PWM_PERIOD - to_integer(r_ONPeriodsLEDSuccess(2)) then
                        o_LedRed <= '1';
                        r_TimerPWMR <= "00000000000000000001";
--                        o_TimerPWMR <= "00000000000000000001";
                    end if;
                    
                    if o_LEDGreen = '1' and to_integer(r_TimerPWMG) >= to_integer(r_ONPeriodsLEDSuccess(1)) then
                        o_LedGreen <= '0';
                        r_TimerPWMG <= "00000000000000000001";
--                        o_TimerPWMG <= "00000000000000000001";
                    elsif o_LEDGreen = '0' and to_integer(r_TimerPWMG) >= c_PWM_PERIOD - to_integer(r_ONPeriodsLEDSuccess(1)) then
                        o_LedGreen <= '1';
                        r_TimerPWMG <= "00000000000000000001";
--                        o_TimerPWMG <= "00000000000000000001";
                    end if;
                    
                    if o_LEDBlue = '1' and to_integer(r_TimerPWMB) >= to_integer(r_ONPeriodsLEDSuccess(0)) then
                        o_LedBlue <= '0';
                        r_TimerPWMB <= "00000000000000000001";
--                        o_TimerPWMB <= "00000000000000000001";
                    elsif o_LEDBlue = '0' and to_integer(r_TimerPWMB) >= c_PWM_PERIOD - to_integer(r_ONPeriodsLEDSuccess(0)) then
                        o_LedBlue <= '1';
                        r_TimerPWMB <= "00000000000000000001";
--                        o_TimerPWMB <= "00000000000000000001";
                    end if;
                
                when others => 
            end case;
        end if;
    end if;
  end process p_RGB_LED_DRIVER;
end Behavioral;