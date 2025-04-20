`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2025 09:52:53 PM
// Design Name: 
// Module Name: mux_para
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mux_para #(parameter N = 8) (
    input wire sel,
    input wire [N-1:0] in0,
    input wire [N-1:0] in1,
    output wire [N-1:0] out
);
    assign out = sel ? in1 : in0;
endmodule
