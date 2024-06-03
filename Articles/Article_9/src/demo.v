module demo (
  //--------- Clock & Resets                     --------//
    input          vga_clk         ,  // VGA clock 25 MHz	 
    input          arst_n          ,  // Active low synchronous reset   
    input          BTNU     ,
    input          BTNR     ,
    input          BTND     ,
    input          BTNL     ,
  //--------- Pixcels Coordinates                --------//
    input  [9:0]   col             ,
    input  [8:0]   row             , 
  //--------- Data from memory with logo         --------//
    input  [15:0]  rom_data        , //player's picture
    input  [15:0]  rom_ghost_data  , //enemy's  picture
  //--------- VGA outputs                        --------//
    output [3:0]   red             ,  // 4-bit color output
    output [3:0]   green           ,  // 4-bit color output
    output [3:0]   blue            ,  // 4-bit color output
  //--------- Switches for background colour     --------//
    input  [11:0]   SW              ,
  //--------- Coins counter                      --------//
    output reg [15:0] coin_cnt      ,
  //--------- the coordinates of the characters ---------//
	output reg [9:0] stick_border_hl_c,
    output reg [8:0] stick_border_hl_r,
    output reg [9:0] enemy_1_border_hl_c,
	output reg [8:0] enemy_1_border_hl_r
);
  //------------------------- Variables                    ----------------------------//
    //----------------------- Stick movement               --------------------------//
      parameter    stick_width  = 64; 
      parameter    stick_height = 64; 
      reg          stick_active;
    reg          coin;
    reg you_coin;
		
	reg  enemy_clk;
	reg	 enemy_1_active;
    parameter    enemy_1_width  = 64; 
    parameter    enemy_1_height = 64;
	parameter    enemy_1_path_len = 128;
	parameter    enemy_1_start_position_c = 446;
	parameter    enemy_1_start_position_r = 62;
	reg	[1:0]	 enemy_1_direction;
	reg 	[9:0]	 enemy_1_step_count;
		
    reg			 coin_active;
    parameter    coin_width  = 25; 
    parameter    coin_height = 25;
    parameter    coin_start_position_c = 200;
    parameter    coin_start_position_r = 10;
    reg	[9:0]	 coin_border_hl_c;
    reg	[8:0]	 coin_border_hl_r;
		
    reg  you_lose;
	reg [11:0] out_background;
	 
	 //// 	labirint //////////////////////////////////////////////////////////
	 always @(posedge vga_clk or negedge arst_n) begin
		if ( !arst_n ) begin
			out_background <= 0;
		end
		else begin
			if ((col[7:0] < 190) && (row[6:0] < 62) || (row > 128 * 3 + 61))
				out_background = 12'h0;
			else
				out_background = ~SW[11:0];
		end
	end

	 reg  move_r, move_c;

  //------------------------- Stick movement  ----------------------------//
    always @(posedge enemy_clk or negedge arst_n) begin
      if ( !arst_n ) begin
        stick_border_hl_c <= 8; 
        stick_border_hl_r <= 63;
		move_c <= 0;
		move_r <= 0;
      end 
      else 
		if(!you_lose)
		begin
			if ( ( stick_border_hl_r[6:0] < 67 ) && ( stick_border_hl_r[6:0] >= 60 ) ) begin
				move_c <= 1;
			end else begin
				move_c <= 0;
			end
			if ( ( stick_border_hl_c[7:0] >= 188 ) && ( stick_border_hl_c[7:0] < 195 ) ) begin
				move_r <= 1;
			end else begin
				move_r <= 0;
			end
			
            if ((move_r || move_c)  ) begin
              if ( (BTNL) && (stick_border_hl_c != 0  ) && move_c) begin
                stick_border_hl_c <= stick_border_hl_c - 1; 
              end
              else if ( (BTNR) && (stick_border_hl_c != 639-stick_width) && move_c ) begin
                stick_border_hl_c <= stick_border_hl_c + 1; 
              end
              if      ( (BTND) && (stick_border_hl_r != 479-stick_height) && move_r && (stick_border_hl_r < 128 * 3)) begin
                stick_border_hl_r <= stick_border_hl_r + 1; 
              end
              else if ( (BTNU) && (stick_border_hl_r != 0  ) && move_r ) begin
                stick_border_hl_r <= stick_border_hl_r - 1; 
              end
            end else begin //move err
              stick_border_hl_r <= stick_border_hl_r - 1;
              stick_border_hl_c <= stick_border_hl_c - 1;
          end
          end
       end

	 reg [31:0] enemy_clk_count;
	 //------------------------- Enemy clk          ----------------------------//
    always @ ( posedge vga_clk or negedge arst_n) begin 
      if      ( !arst_n ) begin
        enemy_clk <='b0;
		  enemy_clk_count <= 32'b0;
      end
		else  begin
			if(enemy_clk_count < 32'd100000)
				enemy_clk_count <= enemy_clk_count + 1'b1;
			else begin
				enemy_clk_count <= 0;
				enemy_clk <= ~enemy_clk;
			end
		end
    end 
	 
  reg [9:0] enemy_1_path;
  reg [9:0] step;
  
  //------------------------- Enemy movement           ----------------------------//
    always @ ( posedge enemy_clk or negedge arst_n) begin 
      if ( !arst_n )  begin
        enemy_1_border_hl_c <= enemy_1_start_position_c;
        enemy_1_border_hl_r <= enemy_1_start_position_r;
        enemy_1_step_count  <= 32'b0;
        enemy_1_direction   <= 'h3;
        step <= 'h0;
        enemy_1_path <= enemy_1_path_len;
        coin_border_hl_c <= coin_start_position_c;
        coin_border_hl_r <= coin_start_position_r;
        coin_cnt <= 0;
     end else 
        if (!you_lose) begin 
            if (you_coin) begin
		      coin_border_hl_c <= enemy_1_border_hl_c + 16;
		      coin_border_hl_r <= enemy_1_border_hl_r + 16;
		      coin_cnt <= coin_cnt + 1;
	        end
	        else begin
              if ( enemy_1_step_count < enemy_1_path) begin
                if (enemy_1_border_hl_r > 128 * 3 - 2)
                  enemy_1_border_hl_r <= 0;
                else 
                  case(enemy_1_direction)
                    'h1: begin
                        enemy_1_border_hl_c <= enemy_1_border_hl_c + 1'b1;
                    end
                    'h2: begin
                        enemy_1_border_hl_c <= enemy_1_border_hl_c - 1'b1;
                    end
                    'h3: begin
                        enemy_1_border_hl_r <= enemy_1_border_hl_r + 1'b1;
                    end
                    'h4: begin
                        enemy_1_border_hl_r <= enemy_1_border_hl_r - 1'b1;
                    end
                  endcase
                enemy_1_step_count <= enemy_1_step_count + 1'b1;
            end
            else begin
                case(step)
                'h0: begin
                    step <= 'h1;
                    enemy_1_path <= 'd128;
                    enemy_1_direction   <= 'h3;
                end
                'h1: begin
                    step <= 'h2;
                    enemy_1_path <= 'd256;
                    enemy_1_direction   <= 'h2;
                end
                'h2: begin
                    step <= 'h3;
                    enemy_1_path <= 'd128;
                    enemy_1_direction   <= 'h4;
                end
                'h3: begin
                    step <= 'h4;
                    enemy_1_path <= 'd256;
                    enemy_1_direction   <= 'h1;
                end
                'h4: begin
                    step <= 'h0;
                    enemy_1_path <= 'd128;
                    enemy_1_direction   <= 'h4;
                end
            endcase
            enemy_1_step_count <= 32'b0;
         end
       end
    end 
    end


    always @ (posedge vga_clk or negedge arst_n) begin
      if (!arst_n) begin
        coin            <= 0;
        stick_active    <= 0;
        enemy_1_active	<= 0;
        coin_active	<= 0;
        you_lose		<= 0;
		you_coin        <= 0;
      end
      else begin
        stick_active      <= (col >= stick_border_hl_c) & (col <= (stick_border_hl_c + stick_width)) & 
                             (row >= stick_border_hl_r) & (row <= (stick_border_hl_r + stick_height)) && (rom_data[11:0] != 12'hFFF);

        enemy_1_active 	  <= (col >= enemy_1_border_hl_c) & (col <= (enemy_1_border_hl_c + enemy_1_width)) & 
                             (row >= enemy_1_border_hl_r) & (row <= (enemy_1_border_hl_r + enemy_1_height))& (|rom_ghost_data);
									  
		you_lose  <= (((stick_border_hl_c + stick_width >= enemy_1_border_hl_c) & 
				     (stick_border_hl_c + stick_width <= enemy_1_border_hl_c + enemy_1_width)) |
					 ((stick_border_hl_c <= enemy_1_border_hl_c + enemy_1_width)&
					 (stick_border_hl_c >= enemy_1_border_hl_c)))&(
					 ((stick_border_hl_r + stick_height >= enemy_1_border_hl_r) &
					 (stick_border_hl_r + stick_height <= enemy_1_border_hl_r + enemy_1_height)) |
					 ((stick_border_hl_r >= enemy_1_border_hl_r) &
					 (stick_border_hl_r <= enemy_1_border_hl_r + enemy_1_height))) |
					 ((stick_border_hl_c  + stick_width >= enemy_1_border_hl_c + enemy_1_width) & 
					 (stick_border_hl_c  <= enemy_1_border_hl_c) &
					 (stick_border_hl_r  <= enemy_1_border_hl_r) &
					 (stick_border_hl_r + stick_height >= enemy_1_border_hl_r + enemy_1_height));
			
	     you_coin  <= (((stick_border_hl_c + stick_width >= coin_border_hl_c) & 
					  (stick_border_hl_c + stick_width <= coin_border_hl_c + coin_width)) |
					  ((stick_border_hl_c <= coin_border_hl_c + coin_width)&
					 (stick_border_hl_c >= coin_border_hl_c)))&(
					 ((stick_border_hl_r + stick_height >= coin_border_hl_r) &
					 (stick_border_hl_r + stick_height <= coin_border_hl_r + coin_height)) |
					 ((stick_border_hl_r >= coin_border_hl_r) &
					 (stick_border_hl_r <= coin_border_hl_r + coin_height))) |(
					 (stick_border_hl_c  + stick_width >= coin_border_hl_c + coin_width) & 
					 (stick_border_hl_c  <= coin_border_hl_c) &
					 (stick_border_hl_r  <= coin_border_hl_r) &
					 (stick_border_hl_r + stick_height >= coin_border_hl_r + coin_height));
										 
          coin  <= (col >= coin_border_hl_c) & (col <= (coin_border_hl_c + coin_width)) & 
                        (row >= coin_border_hl_r) & (row <= (coin_border_hl_r + coin_height)); 
      end
    end
	 
  //------------------------ VGA outputs                   ----------------------------// 
	assign    red     = you_lose ? 4'hf : coin ? 4'hf : enemy_1_active ? rom_ghost_data[11:8]:  stick_active ? rom_data[11:8] : out_background[3:0]; 
	assign    green   = you_lose ? 4'h0 : coin ? 4'hf : enemy_1_active ? rom_ghost_data[7:4] :  stick_active ? rom_data[7:4]  : out_background[7:4];
	assign    blue    = you_lose ? 4'h0 : coin ? 4'h0 : enemy_1_active ? rom_ghost_data[3:0] :  stick_active ? rom_data[3:0]  : out_background[11:8];

endmodule
