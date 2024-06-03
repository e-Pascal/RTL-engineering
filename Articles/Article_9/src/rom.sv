`timescale 1ns / 1ps

module rom #(parameter NUM = 0
)
(
    input clk,
    input [11:0] addr,
    output logic [15:0] data
    );
    logic [15:0] ROM [0:4095];
    
generate
  if (NUM == 0) //player
    initial begin
        $readmemh("miet.mem", ROM); 
    end
  else //ghost
    initial begin
        $readmemh("ghost.mem", ROM); 
    end
endgenerate
    
    always_ff @(posedge clk) begin
        data <= ROM[addr];
    end
    
endmodule
