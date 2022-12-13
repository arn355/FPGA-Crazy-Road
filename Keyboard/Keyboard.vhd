----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    02:22:11 12/13/2022 
-- Design Name: 
-- Module Name:    Keyboard - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Keyboard is
    Port ( CLK : in  STD_LOGIC;
           KEY_IN : in  STD_LOGIC_VECTOR (3 downto 0);
           KEY_OUT : out  STD_LOGIC_VECTOR (3 downto 0));
end Keyboard;

architecture Behavioral of Keyboard is

	signal clk25 : std_logic := '0';
	
begin
	
	clk25 <= CLK;
	
	-- orange -> right
	-- green -> down
	-- black -> left
	-- white -> up
	
	-- KEY_IN (right)(left)(down)(up) (P126)(P131)(P133)(P137)
	-- KEY_OUT (right)(left)(down)(up) (P124)(P127)(P132)(P134)
	
	Keyboard_output:process(clk25, KEY_IN)
	begin
		if(clk25'event and clk25 = '1')then
			if(KEY_IN = "0000")then
				KEY_OUT <= "0000";
			elsif(KEY_IN = "0001")then
				KEY_OUT <= "0001";
			elsif(KEY_IN = "0010")then
				KEY_OUT <= "0010";
			elsif(KEY_IN = "0011")then
				KEY_OUT <= "0011";
			elsif(KEY_IN = "0100")then
				KEY_OUT <= "0100";
			elsif(KEY_IN = "0101")then
				KEY_OUT <= "0101";
			elsif(KEY_IN = "0110")then
				KEY_OUT <= "0110";
			elsif(KEY_IN = "0111")then
				KEY_OUT <= "0111";	
			elsif(KEY_IN = "1000")then
				KEY_OUT <= "1000";
			elsif(KEY_IN = "1001")then
				KEY_OUT <= "1001";
			elsif(KEY_IN = "1010")then
				KEY_OUT <= "1010";
			elsif(KEY_IN = "1011")then
				KEY_OUT <= "1011";
			elsif(KEY_IN = "1100")then
				KEY_OUT <= "1100";
			elsif(KEY_IN = "1101")then
				KEY_OUT <= "1101";
			elsif(KEY_IN = "1110")then
				KEY_OUT <= "1110";
			elsif(KEY_IN = "1111")then
				KEY_OUT <= "1111";
			end if;
		end if;
	end process;

end Behavioral;

