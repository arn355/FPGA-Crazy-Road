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
use ieee.math_real.all;

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
			  SW0 : in STD_LOGIC 
			  );
			  
end vga_driver;

architecture Behavioral of vga_driver is

	-- VGA
	signal clk25 : std_logic := '0';
	constant HD : natural := 509;  	-- Horizontal Display 
	constant HFP : natural := 13;    -- Right border (front porch)
	constant HSP : natural := 76;    -- Sync pulse (Retrace)
	constant HBP : natural := 38;    -- Left boarder (back porch)
	
	constant VD : natural := 349;   	-- Vertical Display 
	constant VFP : natural := 37;    -- Right border (front porch)
	constant VSP : natural := 2;	   -- Sync pulse (Retrace)
	constant VBP : natural := 60;    -- Left boarder (back porch)
	
	signal hPos : natural := 0;
	signal vPos : natural := 0;

	signal videoOn : std_logic := '1';
	
	-- Game static value
	constant player_w : natural := 10;
	constant	player_h : natural := 10;
	constant player_speed : natural := 5;
	constant	car_w : natural := 40;
	constant	car_h : natural := 20;
	
	-- Game Over
	signal game_over : std_logic := '0';
	
	-- Car
	signal car_debounce : natural := 0;

	type car_position_array is array (1 to 6) of natural;
	signal car_x : car_position_array := (10, 460, 10, 460, 10, 460);
	signal car_y : car_position_array := (60, 100, 150, 200, 250, 300);

	type car_speed_array is array (1 to 6) of natural;
	signal car_speed : car_speed_array := (20, 10, 5, 30, 10, 15);
	
	-- Player
	type player_position is record
		x : natural;
		y : natural;
	end record;
	signal player : player_position := (x => 225, y => 335);

	-- Player debounce time
	signal player_debounce : natural := 0;
	
	-- Player Score
	signal player_score : natural := 0;
	
	-- Score Position
	constant score_x : natural := 30;
	constant score_x_ten : natural := 10;
	constant score_y : natural := 10;
	
	-- Time Position
	constant time_x : natural := 240;
	constant time_x_ten : natural := 220;
	constant time_y : natural := 10;
	
	-- Time countdown
	signal countdown : natural := 60;
	signal counter : natural := 0;
	
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
			if(game_over = '0')then
				if(SW0 = '1')then
					if(counter >= 20000000)then
						counter <= 0;
						if(countdown > 1)then
							countdown <= countdown - 1;
						else
							game_over <= '1';
						end if;
					else
						counter <= counter + 1;
					end if;
				end if;
				
				if(car_debounce >= 1500000)then
					car_debounce <= 0;
					
					for i in 1 to 6 loop
						if (i = 1 or i = 3 or i = 5)then
							car_x(i) <= car_x(i) + car_speed(i);
							if (car_x(i) >= HD - 40) then
								car_x(i) <= 10;
								if(i = 1)then
									car_speed(1) <= 15;
									car_speed(2) <= 25;
									car_speed(3) <= 30;
									car_speed(4) <= 10;
									car_speed(5) <= 5;
									car_speed(6) <= 20;
								elsif(i = 3)then
									car_speed(1) <= 30;
									car_speed(2) <= 10;
									car_speed(3) <= 15;
									car_speed(4) <= 25;
									car_speed(5) <= 20;
									car_speed(6) <= 5;
								else
									car_speed(1) <= 25;
									car_speed(2) <= 30;
									car_speed(3) <= 10;
									car_speed(4) <= 5;
									car_speed(5) <= 15;
									car_speed(6) <= 20;
								end if;
							end if ;
						else
							car_x(i) <= car_x(i) - car_speed(i);
							if (car_x(i) <= 40) then
								car_x(i) <= 460;
								if(i = 2)then
									car_speed(1) <= 10;
									car_speed(2) <= 5;
									car_speed(3) <= 20;
									car_speed(4) <= 15;
									car_speed(5) <= 25;
									car_speed(6) <= 30;
								elsif(i = 4)then
									car_speed(1) <= 30;
									car_speed(2) <= 10;
									car_speed(3) <= 5;
									car_speed(4) <= 25;
									car_speed(5) <= 20;
									car_speed(6) <= 15;
								else
									car_speed(1) <= 5;
									car_speed(2) <= 20;
									car_speed(3) <= 30;
									car_speed(4) <= 25;
									car_speed(5) <= 15;
									car_speed(6) <= 10;
								end if;
							end if ;
						end if;
					end loop;
				else
					car_debounce <= car_debounce + 1;
				end if;
				
				if(player_debounce >= 1000000)then
					player_debounce <= 0;
					
					if(KEY_IN = "0001" and player.x <= HD - 20)then -- right
						player.x <= player.x + player_speed;
					elsif(KEY_IN = "0010" and player.x >= 20)then -- left
						player.x <= player.x - player_speed;
					elsif(KEY_IN = "1000" and player.y >= 40)then -- down
						player.y <= player.y - player_speed;
					elsif(KEY_IN = "0100" and player.y <= VD - 10)then -- up
						player.y <= player.y + player_speed;
					end if;
					
					-- Collision
					if(player.y <= 55)then
						if(SW0 = '1')then
							player_score <= player_score + 1;
						end if;
						player.x <= 225;
						player.y <= 335;
					
					elsif(player.x + 5 >= car_x(1) and player.x + 5 <= car_x(1) + car_w and player.y + 5 >= car_y(1) and player.y + 5 <= car_y(1) + car_h)then
						player.x <= 225;
						player.y <= 335;
					elsif(player.x + 5 >= car_x(2) and player.x + 5 <= car_x(2) + car_w and player.y + 5 >= car_y(2) and player.y + 5 <= car_y(2) + car_h)then
						player.x <= 225;
						player.y <= 335;
					elsif(player.x + 5 >= car_x(3) and player.x + 5 <= car_x(3) + car_w and player.y + 5 >= car_y(3) and player.y + 5 <= car_y(3) + car_h)then
						player.x <= 225;
						player.y <= 335;
					elsif(player.x + 5 >= car_x(4) and player.x + 5 <= car_x(4) + car_w and player.y + 5 >= car_y(4) and player.y + 5 <= car_y(4) + car_h)then
						player.x <= 225;
						player.y <= 335;
					elsif(player.x + 5 >= car_x(5) and player.x + 5 <= car_x(5) + car_w and player.y + 5 >= car_y(5) and player.y + 5 <= car_y(5) + car_h)then
						player.x <= 225;
						player.y <= 335;
					elsif(player.x + 5 >= car_x(6) and player.x + 5 <= car_x(6) + car_w and player.y + 5 >= car_y(6) and player.y + 5 <= car_y(6) + car_h)then
						player.x <= 225;
					 	player.y <= 335;
					end if;
				else
					player_debounce <= player_debounce + 1;
				end if;
			else	
				if(KEY_IN = "0000" and SW0 = '0')then -- restart game
						player.x <= 225;
						player.y <= 335;
						player_score <= 0;
						countdown <= 60;

						game_over <= '0';
				end if;
			end if;
		end if;
	end process;
	
	draw:process(clk25, RST, hPos, vPos, videoOn) --hpos 0 - 383 vpos 0 - 450
	begin
		
		if(RST = '1')then
			RGB <= "000"; -- "000"
		elsif(clk25'event and clk25 = '1')then
			if(videoOn='1') then
	
				-- 500 (right corner) (509)
				-- 349 (down corner)
				if(game_over = '0') then

					if((hPos >= 5 and hPos <= 500) AND (vPos >= 50 and vPos <= 55))then -- Finish line
						RGB <= "111";
					elsif((hPos >= 5 and hPos <= 500) AND (vPos >=325 and vPos <= 330))then -- Start line 
						RGB <= "111";
					
					-- Cars
					elsif((hPos >= car_x(1) and hPos <= car_x(1) + car_w) AND (vPos >= car_y(1) and vPos <= car_y(1) + car_h))then
						RGB <= "101";
					elsif((hPos >= car_x(2) and hPos <= car_x(2) + car_w) AND (vPos >= car_y(2) and vPos <= car_y(2) + car_h))then
						RGB <= "101";
					elsif((hPos >= car_x(3) and hPos <= car_x(3) + car_w) AND (vPos >= car_y(3) and vPos <= car_y(3) + car_h))then
						RGB <= "101";
					elsif((hPos >= car_x(4) and hPos <= car_x(4) + car_w) AND (vPos >= car_y(4) and vPos <= car_y(4) + car_h))then
						RGB <= "101";
					elsif((hPos >= car_x(5) and hPos <= car_x(5) + car_w) AND (vPos >= car_y(5) and vPos <= car_y(5) + car_h))then
						RGB <= "101";
					elsif((hPos >= car_x(6) and hPos <= car_x(6) + car_w) AND (vPos >= car_y(6) and vPos <= car_y(6) + car_h))then
						RGB <= "101";
					
					-- Player
					elsif((hPos >= player.x and hPos <= player.x + player_w) AND (vPos >= player.y and vPos <= player.y + player_h))then
						RGB <= "110";
					
					else
						RGB <= "000"; --"000"
					end if;
						
					
					-- Time
					-- Ten
					if(countdown / 10 = 0)then
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x_ten + 20 + 5 and hPos <= time_x_ten + 20 + 10) AND (vPos >= time_y + 5 and vPos <= time_y + 20))then
							RGB <= "000";
						end if;
						
					elsif(countdown / 10 = 1)then
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y and vPos <= score_y + 25))then
							RGB <= "000";
						end if;
						
					elsif(countdown / 10 = 2)then
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x_ten + 20 + 5 and hPos <= time_x_ten + 20 + 15) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
							RGB <= "000";
						end if;
					
					elsif(countdown / 10 = 3)then
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
							RGB <= "000";
						end if;
						
					elsif(countdown / 10 = 4)then
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x_ten + 20 + 5 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 25))then
							RGB <= "000";
						end if;
						
					elsif(countdown / 10 = 5)then
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x_ten + 20 + 5 and hPos <= time_x_ten + 20 + 15) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
							RGB <= "000";
						end if;
						
					elsif(countdown / 10 = 6)then
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x_ten + 20 + 5 and hPos <= time_x_ten + 20 + 15) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x_ten + 20 + 5 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
							RGB <= "000";
						end if;
						
					elsif(countdown / 10 = 7)then
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 25))then
							RGB <= "000";
						end if;
						
					elsif(countdown / 10 = 8)then
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x_ten + 20 + 5 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x_ten + 20 + 5 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
							RGB <= "000";
						end if;
						
					elsif(countdown / 10 = 9)then
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x_ten + 20 + 5 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x_ten + 20 and hPos <= time_x_ten + 20 + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
							RGB <= "000";
						end if;
					end if;

					-- Unit
					if(countdown mod 10 = 0)then
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x + 20 + 5 and hPos <= time_x + 20 + 10) AND (vPos >= time_y + 5 and vPos <= time_y + 20))then
							RGB <= "000";
						end if;
						
					elsif(countdown mod 10 = 1)then
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 10) AND (vPos >= score_y and vPos <= score_y + 25))then
							RGB <= "000";
						end if;
						
					elsif(countdown mod 10 = 2)then
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x + 20 + 5 and hPos <= time_x + 20 + 15) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
							RGB <= "000";
						end if;
					
					elsif(countdown mod 10 = 3)then
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
							RGB <= "000";
						end if;
						
					elsif(countdown mod 10 = 4)then
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x + 20 + 5 and hPos <= time_x + 20 + 10) AND (vPos >= score_y and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 25))then
							RGB <= "000";
						end if;
						
					elsif(countdown mod 10 = 5)then
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x + 20 + 5 and hPos <= time_x + 20 + 15) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
							RGB <= "000";
						end if;
						
					elsif(countdown mod 10 = 6)then
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x + 20 + 5 and hPos <= time_x + 20 + 15) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x + 20 + 5 and hPos <= time_x + 20 + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
							RGB <= "000";
						end if;
						
					elsif(countdown mod 10 = 7)then
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 25))then
							RGB <= "000";
						end if;
						
					elsif(countdown mod 10 = 8)then
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x + 20 + 5 and hPos <= time_x + 20 + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x + 20 + 5 and hPos <= time_x + 20 + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
							RGB <= "000";
						end if;
						
					elsif(countdown mod 10 = 9)then
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 15) AND (vPos >= time_y and vPos <= time_y + 25))then
							RGB <= "111";
						end if;
						if((hPos >= time_x + 20 + 5 and hPos <= time_x + 20 + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
							RGB <= "000";
						end if;
						if((hPos >= time_x + 20 and hPos <= time_x + 20 + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
							RGB <= "000";
						end if;
					end if;

				else
					if((hPos >= 0 and hPos <= HD) AND (vPos >= 0 and vPos <= VD))then
						RGB <= "000";
					end if;

					-- E
					if((hPos >= 200 and hPos <= 200 + 30) AND (vPos >= 150 and vPos <= 150 + 50))then
						RGB <= "111";
					end if;
					if((hPos >= 200 + 10 and hPos <= 200 + 30) AND (vPos >= 150 + 10 and vPos <= 150 + 20))then
						RGB <= "000";
					end if;
					if((hPos >= 200 + 10 and hPos <= 200 + 30) AND (vPos >= 150 + 30 and vPos <= 150 + 40))then
						RGB <= "000";
					end if;
					
					-- N
					if((hPos >= 240 and hPos <= 240 + 30) AND (vPos >= 150 and vPos <= 150 + 50))then
						RGB <= "111";
					end if;
					if((hPos >= 240 + 10 and hPos <= 240 + 20) AND (vPos >= 150 + 10 and vPos <= 150 + 50))then
						RGB <= "000";
					end if;
					
					-- D
					if((hPos >= 280 and hPos <= 280 + 30) AND (vPos >= 150 and vPos <= 150 + 50))then
						RGB <= "111";
					end if;
					if((hPos >= 280 + 20 and hPos <= 280 + 30) AND (vPos >= 150 and vPos <= 150 + 10))then
						RGB <= "000";
					end if;
					if((hPos >= 280 + 10 and hPos <= 280 + 20) AND (vPos >= 150 + 10 and vPos <= 150 + 40))then
						RGB <= "000";
					end if;
					if((hPos >= 280 + 20 and hPos <= 280 + 30) AND (vPos >= 150 + 40 and vPos <= 150 + 50))then
						RGB <= "000";
					end if;
					
				end if;

				-- Score
				-- Ten
				if(player_score / 10 = 0)then
					if((hPos >= score_x_ten and hPos <= score_x_ten + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x_ten + 5 and hPos <= score_x_ten + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
				
				elsif(player_score / 10 = 1)then
					if((hPos >= score_x_ten and hPos <= score_x_ten + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x_ten and hPos <= score_x_ten + 10) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "000";
					end if;
					
				elsif(player_score / 10 = 2)then
					if((hPos >= score_x_ten and hPos <= score_x_ten + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x_ten and hPos <= score_x_ten + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x_ten + 5 and hPos <= score_x_ten + 15) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
					
				elsif(player_score / 10 = 3)then
					if((hPos >= score_x_ten and hPos <= score_x_ten + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x_ten and hPos <= score_x_ten + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x_ten and hPos <= score_x_ten + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
					
				elsif(player_score / 10 = 4)then
					if((hPos >= score_x_ten and hPos <= score_x_ten + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x_ten + 5 and hPos <= score_x_ten + 10) AND (vPos >= score_y and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x_ten and hPos <= score_x_ten+ 10) AND (vPos >= score_y + 15 and vPos <= score_y + 25))then
						RGB <= "000";
					end if;
					
				elsif(player_score / 10 = 5)then
					if((hPos >= score_x_ten and hPos <= score_x_ten + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x_ten + 5 and hPos <= score_x_ten + 15) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x_ten and hPos <= score_x_ten + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
					
				elsif(player_score / 10 = 6)then
					if((hPos >= score_x_ten and hPos <= score_x_ten + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x_ten + 5 and hPos <= score_x_ten + 15) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x_ten + 5 and hPos <= score_x_ten + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
					
				elsif(player_score / 10 = 7)then
					if((hPos >= score_x_ten and hPos <= score_x_ten + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x_ten and hPos <= score_x_ten + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 25))then
						RGB <= "000";
					end if;
					
				elsif(player_score / 10 = 8)then
					if((hPos >= score_x_ten and hPos <= score_x_ten + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x_ten + 5 and hPos <= score_x_ten + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x_ten + 5 and hPos <= score_x_ten + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
					
				elsif(player_score / 10 = 9)then
					if((hPos >= score_x_ten and hPos <= score_x_ten + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x_ten + 5 and hPos <= score_x_ten + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;	
					if((hPos >= score_x_ten and hPos <= score_x_ten + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
				end if;
				
				-- Unit
				if(player_score mod 10 = 0)then
					if((hPos >= score_x and hPos <= score_x + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x + 5 and hPos <= score_x + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
					
				elsif(player_score mod 10 = 1)then
					if((hPos >= score_x and hPos <= score_x + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x and hPos <= score_x + 10) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "000";
					end if;
					
				elsif(player_score mod 10 = 2)then
					if((hPos >= score_x and hPos <= score_x + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x and hPos <= score_x + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x + 5 and hPos <= score_x + 15) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
					
				elsif(player_score mod 10 = 3)then
					if((hPos >= score_x and hPos <= score_x + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x and hPos <= score_x + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x and hPos <= score_x + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
					
				elsif(player_score mod 10 = 4)then
					if((hPos >= score_x and hPos <= score_x + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x + 5 and hPos <= score_x + 10) AND (vPos >= score_y and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x and hPos <= score_x+ 10) AND (vPos >= score_y + 15 and vPos <= score_y + 25))then
						RGB <= "000";
					end if;
					
				elsif(player_score mod 10 = 5)then
					if((hPos >= score_x and hPos <= score_x + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x + 5 and hPos <= score_x + 15) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x and hPos <= score_x + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
					
				elsif(player_score mod 10 = 6)then
					if((hPos >= score_x and hPos <= score_x + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x + 5 and hPos <= score_x + 15) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x + 5 and hPos <= score_x + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
					
				elsif(player_score mod 10 = 7)then
					if((hPos >= score_x and hPos <= score_x + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x and hPos <= score_x + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 25))then
						RGB <= "000";
					end if;
					
				elsif(player_score mod 10 = 8)then
					if((hPos >= score_x and hPos <= score_x + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x + 5 and hPos <= score_x + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x + 5 and hPos <= score_x + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
					
				elsif(player_score mod 10 = 9)then
					if((hPos >= score_x and hPos <= score_x + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x + 5 and hPos <= score_x + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x and hPos <= score_x + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
				end if;

				-- player score exceed 99
				if(player_score > 99)then
					if((hPos >= score_x_ten and hPos <= score_x_ten + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x_ten + 5 and hPos <= score_x_ten + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;	
					if((hPos >= score_x_ten and hPos <= score_x_ten + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;	

					if((hPos >= score_x and hPos <= score_x + 15) AND (vPos >= score_y and vPos <= score_y + 25))then
						RGB <= "111";
					end if;
					if((hPos >= score_x + 5 and hPos <= score_x + 10) AND (vPos >= score_y + 5 and vPos <= score_y + 10))then
						RGB <= "000";
					end if;
					if((hPos >= score_x and hPos <= score_x + 10) AND (vPos >= score_y + 15 and vPos <= score_y + 20))then
						RGB <= "000";
					end if;
				end if;

			else
				RGB <= "000"; --"000"
			end if; -- if video	
		end if; -- if RST
	end process;

end Behavioral;