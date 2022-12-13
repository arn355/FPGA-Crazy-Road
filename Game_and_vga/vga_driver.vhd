----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:14:33 12/12/2022 
-- Design Name: 
-- Module Name:    vga_driver - Behavioral 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_driver is
    Port ( CLK : in  STD_LOGIC;  -- OSC P123
           RST : in  STD_LOGIC;  -- Reset
           HSYNC : out  STD_LOGIC;
           VSYNC : out  STD_LOGIC;
           RGB : out  STD_LOGIC_VECTOR (2 downto 0);
			  KEY_IN : in STD_LOGIC_VECTOR (3 downto 0);
			  
			  LED0 : out STD_LOGIC;
			  LED1 : out STD_LOGIC;
			  LED2 : out STD_LOGIC;
			  LED3 : out STD_LOGIC);
			  
end vga_driver;

architecture Behavioral of vga_driver is

	-- VGA
	signal clk25 : std_logic := '0';
	constant HD : integer := 509;  	-- Horizontal Display 
	constant HFP : integer := 13;    -- Right border (front porch)
	constant HSP : integer := 76;    -- Sync pulse (Retrace)
	constant HBP : integer := 38;    -- Left boarder (back porch)
	
	constant VD : integer := 349;   	-- Vertical Display 
	constant VFP : integer := 37;    -- Right border (front porch)
	constant VSP : integer := 2;	   -- Sync pulse (Retrace)
	constant VBP : integer := 60;    -- Left boarder (back porch)
	
	signal hPos : integer := 0;
	signal vPos : integer := 0;

	signal videoOn : std_logic := '1';
	
	-- Game static value
	constant player_w : integer := 10;
	constant	player_h : integer := 10;
	constant player_speed : integer := 5;
	constant	car_w : integer := 40;
	constant	car_h : integer := 20;
	
	-- signal car_x : integer := 20;
	-- signal car_y : integer := 300;
	-- signal car_debounce : integer := 0;
	-- signal car_speed : integer := 10;
	
	-- Car
	signal car_debounce : integer := 0;
	signal car_1_x : integer := 10;
	signal car_2_x : integer := 460;
	signal car_3_x : integer := 10;
	signal car_4_x : integer := 460;
	signal car_5_x : integer := 10;
	signal car_6_x : integer := 460;
	
	signal car_1_y : integer := 60;
	signal car_2_y : integer := 100;
	signal car_3_y : integer := 150;
	signal car_4_y : integer := 200;
	signal car_5_y : integer := 250;
	signal car_6_y : integer := 300;
	
	signal car_1_speed : integer := 20;
	signal car_2_speed : integer := 10;
	signal car_3_speed : integer := 5;
	signal car_4_speed : integer := 30;
	signal car_5_speed : integer := 10;
	signal car_6_speed : integer := 15;
	
	-- Player
	signal player_debounce : integer := 0;
	signal player_x : integer := 225;
	signal player_y : integer := 335;
	
	signal player_score : integer := 0;
	
begin
	--ALL Process Section
	
	clk25 <= CLK;
	
	--VGA Montitor border section
	Horizontal_position_counter:process(clk25, RST)
	begin
		if(RST = '1')then
			hpos <= 0;
		elsif(clk25'event and clk25 = '1')then
			if (hPos = (HD + HFP + HSP + HBP)) then
				hPos <= 0;
			else
				hPos <= hPos + 1;
			end if;
		end if;
	end process;

	Vertical_position_counter:process(clk25, RST, hPos)
	begin
		if(RST = '1')then
			vPos <= 0;
		elsif(clk25'event and clk25 = '1')then
			if(hPos = (HD + HFP + HSP + HBP))then
				if (vPos = (VD + VFP + VSP + VBP)) then
					vPos <= 0;
				else
					vPos <= vPos + 1;
				end if;
			end if;
		end if;
	end process;

	Horizontal_Synchronisation:process(clk25, RST, hPos)
	begin
		if(RST = '1')then
			HSYNC <= '0';
		elsif(clk25'event and clk25 = '1')then
			if((hPos <= (HD + HFP)) OR (hPos > HD + HFP + HSP))then
				HSYNC <= '1';
			else
				HSYNC <= '0';
			end if;
		end if;
	end process;

	Vertical_Synchronisation:process(clk25, RST, vPos)
	begin
		if(RST = '1')then
			VSYNC <= '0';
		elsif(clk25'event and clk25 = '1')then
			if((vPos <= (VD + VFP)) OR (vPos > VD + VFP + VSP))then
				VSYNC <= '1';
			else
				VSYNC <= '0';
			end if;
		end if;
	end process;	

	-- Video on process
	video_on:process(clk25, RST, hPos, vPos)
	begin
		if(RST = '1')then
			videoOn <= '0';
		elsif(clk25'event and clk25 = '1')then
			if(hPos <= HD and vPos <= VD)then
				videoOn <= '1';
			else
				videoOn <= '0';
			end if;
		end if;
	end process;
	
	-- KEY_IN (right)(left)(down)(up) (P126)(P131)(P133)(P137)
	game_logic:process(clk25, KEY_IN)
	begin
		if(clk25'event and clk25 = '1')then
			if(car_debounce >= 1500000)then
				car_debounce <= 0;				
				if(car_1_x <= HD - 20)then
					car_1_x <= car_1_x + car_1_speed;
				else
					car_1_x <= 10;
				end if;
				
				if(car_2_x >= 40)then
					car_2_x <= car_2_x - car_2_speed;
				else
					car_2_x <= 460;
				end if;
				
				if(car_3_x <= HD - 20)then
					car_3_x <= car_3_x + car_3_speed;
				else
					car_3_x <= 10;
				end if;
				
				if(car_4_x >= 40)then
					car_4_x <= car_4_x - car_4_speed;
				else
					car_4_x <= 460;
				end if;
				
				if(car_5_x <= HD - 20)then
					car_5_x <= car_5_x + car_5_speed;
				else
					car_5_x <= 10;
				end if;
				
				if(car_6_x >= 40)then
					car_6_x <= car_6_x - car_6_speed;
				else
					car_6_x <= 460;
				end if;
			else
				car_debounce <= car_debounce + 1;
			end if;
			
			if(player_debounce >= 1000000)then
				player_debounce <= 0;
				if(KEY_IN = "0001" and player_x <= HD - 20)then -- right
					player_x <= player_x + player_speed;
					LED0 <= '1';
				elsif(KEY_IN = "0010" and player_x >= 20)then -- left
					player_x <= player_x - player_speed;
					LED1 <= '1';
				elsif(KEY_IN = "1000" and player_y >= 40)then -- down
					player_y <= player_y - player_speed;
					LED2 <= '1';
				elsif(KEY_IN = "0100" and player_y <= VD - 10)then -- up
					player_y <= player_y + player_speed;
					LED3 <= '1';
				else
					LED0 <= '0';
					LED1 <= '0';
					LED2 <= '0';
					LED3 <= '0';
				end if;
				
				-- Collision
				if(player_y <= 55)then
					player_score <= player_score + 1;
					player_x <= 225;
					player_y <= 335;
				
				elsif(player_x >= car_1_x and player_x <= car_1_x + car_w and ( (player_y >= car_1_y and player_y <= car_1_y + car_h) or (player_y + player_h <= car_1_y + car_h and player_y + player_h >= car_1_y) ))then
					player_x <= 225;
					player_y <= 335;
				--elsif(player_x >= car_1_x and player_x + player_w <= car_1_x + car_w and player_y >= car_1_y and player_y + player_h <= car_1_y + car_h)then
					--player_x <= 225;
					--player_y <= 335;
				elsif(player_x >= car_2_x and player_x <= car_2_x + car_w and ( (player_y >= car_2_y and player_y <= car_2_y + car_h) or (player_y + player_h <= car_2_y + car_h and player_y + player_h >= car_2_y) ))then
					player_x <= 225;
					player_y <= 335;
				--elsif(player_x >= car_2_x and player_x + player_w <= car_2_x + car_w and player_y >= car_2_y and player_y + player_h <= car_2_y + car_h)then
					--player_x <= 225;
					--player_y <= 335;
				elsif(player_x >= car_3_x and player_x <= car_3_x + car_w and ( (player_y >= car_3_y and player_y <= car_3_y + car_h) or (player_y + player_h <= car_3_y + car_h and player_y + player_h >= car_3_y) ))then
					player_x <= 225;
					player_y <= 335;
				--elsif(player_x >= car_3_x and player_x + player_w <= car_3_x + car_w and player_y >= car_3_y and player_y + player_h <= car_3_y + car_h)then
					--player_x <= 225;
					--player_y <= 335;
				elsif(player_x >= car_4_x and player_x <= car_4_x + car_w and ( (player_y >= car_4_y and player_y <= car_4_y + car_h) or (player_y + player_h <= car_4_y + car_h and player_y + player_h >= car_4_y) ))then
					player_x <= 225;
					player_y <= 335;
				--elsif(player_x >= car_4_x and player_x + player_w <= car_4_x + car_w and player_y >= car_4_y and player_y + player_h <= car_4_y + car_h)then
					--player_x <= 225;
					--player_y <= 335;
				elsif(player_x >= car_5_x and player_x <= car_5_x + car_w and ( (player_y >= car_5_y and player_y <= car_5_y + car_h) or (player_y + player_h <= car_5_y + car_h and player_y + player_h >= car_5_y) ))then
					player_x <= 225;
					player_y <= 335;
				--elsif(player_x >= car_5_x and player_x + player_w <= car_5_x + car_w and player_y >= car_5_y and player_y + player_h <= car_5_y + car_h)then
					--player_x <= 225;
					--player_y <= 335;
				elsif(player_x >= car_6_x and player_x <= car_6_x + car_w and ( (player_y >= car_6_y and player_y <= car_6_y + car_h) or (player_y + player_h <= car_6_y + car_h and player_y + player_h >= car_6_y) ))then
					player_x <= 225;
					player_y <= 335;
				--elsif(player_x >= car_6_x and player_x + player_w <= car_6_x + car_w and player_y >= car_6_y and player_y + player_h <= car_6_y + car_h)then
					--player_x <= 225;
					--player_y <= 335;
				
					
				end if;
			else
				player_debounce <= player_debounce + 1;
			end if;
		end if;
	end process;
	
	draw:process(clk25, RST, hPos, vPos, videoOn) --hpos 0 - 383 vpos 0 - 450
	begin
		
		if(RST = '1')then
			RGB <= "000"; -- "000"
		elsif(clk25'event and clk25 = '1')then
			if(videoOn='1') then
	
				-- (hPos >= 10 and hPos <= 60) AND (vPos >= 10 and vPos <= 60)
				-- 500 (right corner) (509)
				-- 5 (left corner) (0)
				-- 349 (down corner)
				
				if((hPos >= 5 and hPos <= 500) AND (vPos >= 50 and vPos <= 55))then -- Finish line
					RGB <= "111";
				elsif((hPos >= 5 and hPos <= 500) AND (vPos >=325 and vPos <= 330))then -- Start line 
					RGB <= "111";
					
				elsif((hPos >= car_1_x and hPos <= car_1_x + car_w) AND (vPos >= car_1_y and vPos <= car_1_y + car_h))then
					RGB <= "101";
				elsif((hPos >= car_2_x and hPos <= car_2_x + car_w) AND (vPos >= car_2_y and vPos <= car_2_y + car_h))then
					RGB <= "101";
				elsif((hPos >= car_3_x and hPos <= car_3_x + car_w) AND (vPos >= car_3_y and vPos <= car_3_y + car_h))then
					RGB <= "101";
				elsif((hPos >= car_4_x and hPos <= car_4_x + car_w) AND (vPos >= car_4_y and vPos <= car_4_y + car_h))then
					RGB <= "101";
				elsif((hPos >= car_5_x and hPos <= car_5_x + car_w) AND (vPos >= car_5_y and vPos <= car_5_y + car_h))then
					RGB <= "101";
				elsif((hPos >= car_6_x and hPos <= car_6_x + car_w) AND (vPos >= car_6_y and vPos <= car_6_y + car_h))then
					RGB <= "101";
					
				elsif((hPos >= player_x and hPos <= player_x + player_w) AND (vPos >= player_y and vPos <= player_y + player_h))then
					RGB <= "110";	
				else
					RGB <= "000"; --"000"
				end if;
	
			else
				RGB <= "000"; --"000"
			end if;
		end if;
	end process;

end Behavioral;