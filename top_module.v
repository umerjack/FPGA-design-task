`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2025 10:39:53 AM
// Design Name: 
// Module Name: top_module
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


module top_module#(parameter N=8, parameter L=3
)( input clk,rst,s,
output done,
//singal for simulation
input Rd,Wrinit,
input [N-1:0]Datain,
input [L-1:0]Radd,
output [N-1:0]DataOut

    );
    
    //output form datapath to input of fsm singsl
    wire zi,zj,AgtB;
    
    //control singal form fsm
    wire Li,Lj,Ei,Ej,EA,EB;
    wire Csel,Bout,Wr;
    // Instantiate the FSM module
    FSM fsm_mdoule (
        .clk(clk),
        .rst(rst),
        .s(s),
        //output of datapath
        .zi(zi),
        .zj(zj),
        .AgtB(AgtB),
        //
        .Li(Li),
        .Lj(Lj),
        .Ei(Ei),
        .Ej(Ej),
        .EA(EA),
        .EB(EB),
        .WR(Wr),
        .Csel(Csel),
        .Bout(Bout),
        .done(done)
    );
    
    
    // Instantiate the Datapath
    Datapath #(8) datapath_module (
        .clk(clk),
        .rst(rst),
        .EA(EA),
        .EB(EB),
        .WR(Wr | Wrinit),
        .Li(Li),
        .Lj(Lj),
        .Ei(Ei),
        .Ej(Ej),
        .Csel(Csel),
        .Bout(Bout),
        .s(s),
        .Rd(Rd),
        .Radd(Radd),
        .Datain(Datain),
        .DataOut(DataOut),
        .AgtB(AgtB),
        .zi(zi),
        .zj(zj)
    );
endmodule
