`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2025 10:03:10 PM
// Design Name: 
// Module Name: Datapath
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


module Datapath #(parameter N = 8) (
    input wire clk, rst,

    // Control signals
    input wire EA, EB, WR, Li, Lj, Ei, Ej, Csel, Bout, s, Rd,

    // External data interface
    input wire [2:0] Radd,         // External read address
    output wire [N-1:0] DataOut,   // External read data
    input wire [N-1:0] Datain,     // External data input

  
    // Output generated flags
    output wire AgtB,              // A > B flag
    output wire zi, zj             // i , j flags
);

    // Internal wires
    wire [2:0] i_val, j_val;
    wire [2:0] addr_mux_out;
    wire [2:0] final_addr;

    wire [N-1:0] Mij;          // RAM output
    wire [N-1:0] din_mux_out;      // Final data to write into RAM
    wire [N-1:0] A, B;             // A and B register outputs
    wire [N-1:0] ABMux;       // Value selected between A/B for writeback

    //////////////////////////////////////
    // Counters for loop indices i and j
    //////////////////////////////////////

    load_counter counter_i (
        .clk(clk),
        .rst(rst),
        .ld(Li),
        .en(Ei),
        .ld_val(3'd0),
        .count(i_val)
    );

    load_counter counter_j (
        .clk(clk),
        .rst(rst),
        .ld(Lj),
        .en(Ej),
        .ld_val(i_val + 1),
        .count(j_val)
    );

    /////////////////////////////////
    // MUX to select i or j address
    /////////////////////////////////

    mux_para #(3) i_j_mux (
        .sel(Csel),
        .in0(i_val),
        .in1(j_val),
        .out(addr_mux_out)
    );

    ////////////////////////////////////////////////////////
    // MUX to select either external Radd or internal addr
    ////////////////////////////////////////////////////////

    mux_para #(3) radd_mux (
        .sel(s),
        .in0(Radd),
        .in1(addr_mux_out),
        .out(final_addr)
    );

    //////////////////////////
    // Equality checkers
    //////////////////////////

    Equality_checker eq_i (
        .a(i_val),
        .b(3'd6),
        .eq(zi)
    );

    Equality_checker eq_j (
        .a(j_val),
        .b(3'd7),
        .eq(zj)
    );

    //////////////////////////
    // RAM: 8x8 Byte Memory
    //////////////////////////

    RAM ram_block (
        .clk(clk),
        .we(WR),
        .addr(final_addr),
        .din(din_mux_out),
        .dout(Mij)
    );

    ///////////////////////////////////
    // Registers A and B (for compare)
    ///////////////////////////////////

    Register reg_A (
        .clk(clk),
        .rst(rst),
        .en(EA),
        .d_in(Mij),
        .d_out(A)
    );

    Register reg_B (
        .clk(clk),
        .rst(rst),
        .en(EB),
        .d_in(Mij),
        .d_out(B)
    );

    /////////////////////////
    // Comparator A > B
    /////////////////////////

    Comparator comp (
        .A(A),
        .B(B),
        .AgtB(AgtB)
    );

    ////////////////////////////////////
    // MUX to select A or B for write
    ////////////////////////////////////

    mux_para #(N) ab_mux (
        .sel(Bout),
        .in0(A),
        .in1(B),
        .out(ABMux)
    );

    //////////////////////////////////////////
    // Final data input MUX for RAM write
    //////////////////////////////////////////

    mux_para #(N) data_in_mux (
        .sel(s),
        .in0(Datain),
        .in1(ABMux),
        .out(din_mux_out)
    );

    ////////////////////////////////////
    // Data Output (with tri-state Z)
    ////////////////////////////////////

    assign DataOut = Rd ? Mij : {N{1'bz}};

endmodule
