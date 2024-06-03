`timescale 1ns / 1ps

module game_unit(
  input  logic        clk_i,
  input  logic        resetn_i,
  input  logic [15:0] sw_i,
  output logic [15:0] led_o,
  input BTNU,
  input BTNL,
  input BTNR,
  input BTND,
  output logic [3:0]  vga_r_o,
  output logic [3:0]  vga_g_o,
  output logic [3:0]  vga_b_o,
  output logic        vga_hs_o,
  output logic        vga_vs_o
);

//------------------------- Signals declaration          ----------------------------//
//----------------------- Clocks                       --------------------------//
  logic            vga_clk     ;     // 25 MHz
//----------------------- VGA Controller               --------------------------//
  logic [31:0]     col, row;         // Pixcels Coordinates 
  logic [3:0]      red, green, blue; // Pixcels Colors
  // Timing signals
    logic          h_sync, v_sync;   // Horizontal & Vertical synchronization
    logic          disp_ena;         // Image output is allowed
logic rst;
sys_clk_rst_gen divider(.ex_clk_i(clk_i),.ex_areset_n_i(resetn_i),.div_i(2),.sys_clk_o(vga_clk), .sys_reset_o(rst));

logic  disp_ena; // Image output is allowed
vga_controller control (
    .pixel_clk  ( vga_clk       ), // Pixel clock 25MHz
    .reset_n    ( !rst          ), // Active low synchronous reset
    .h_sync     ( h_sync        ), // horizontal sync signal
    .v_sync     ( v_sync        ), // vertical sync signal
    .disp_ena   ( disp_ena      ), // display enable (0 = all colors must be blank)
    .column     ( col           ), // horizontal pixel coordinate
    .row        ( row           )  // vertical pixel coordinate
);

	logic [9:0] stick_border_hl_c;
    logic [8:0] stick_border_hl_r;
    logic [15:0] player_data;
    logic [9:0] enemy_1_border_hl_c;
    logic [8:0] enemy_1_border_hl_r;
    logic [15:0] ghost_data;
//--------------------- VGA IOs                      -------------------------//
  always_ff @(posedge vga_clk) begin
    if (disp_ena == 1'b1) begin
      vga_r_o <= red  ;
      vga_g_o <= green;
      vga_b_o <= blue ;
    end 
    else begin
      vga_r_o <= 4'd0;
      vga_g_o <= 4'd0;
      vga_b_o <= 4'd0;
    end
      vga_hs_o <= h_sync;
      vga_vs_o <= v_sync;
  end
  
  demo game_module (
    .vga_clk  (vga_clk), 
    .arst_n   (!rst),
    .BTNU     (BTNU),
    .BTNR     (BTNR),
    .BTND     (BTND),
    .BTNL     (BTNL),
    .col             (col[9:0]),
    .row             (row[8:0]), 
    .rom_data        (player_data),
    .rom_ghost_data  (ghost_data ),
    .red             (red  ),  // 4-bit color output
    .green           (green),  // 4-bit color output
    .blue            (blue ),  // 4-bit color output
    .SW              (sw_i[11:0]),
	.coin_cnt        (led_o     ),
	.stick_border_hl_c  (stick_border_hl_c),
    .stick_border_hl_r  (stick_border_hl_r),
    .enemy_1_border_hl_c(enemy_1_border_hl_c),
	.enemy_1_border_hl_r(enemy_1_border_hl_r)
);

rom #(0)
player(
  .clk(vga_clk),
  .addr((col - stick_border_hl_c) + ((row - stick_border_hl_r))*64),
  .data(player_data)
);

rom #(1)
ghost
(
  .clk(vga_clk),
  .addr((col - enemy_1_border_hl_c) + ((row - enemy_1_border_hl_r))*64),
  .data(ghost_data)
);

endmodule

