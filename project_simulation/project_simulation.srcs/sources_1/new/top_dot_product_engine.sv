`timescale 1ns/1ps
module top_dot_product_engine (
    input  logic         clk,
    input  logic         rst,
    input  logic         rstn,
    input  logic         start,
    input  logic [2:0]   data_type,
    input  logic         A_valid,
    input  logic [255:0] A_data,
    
    input  logic [3:0]   x_wr_addr,
    input  logic [31:0]  x_wr_data,
    input  logic [63:0]  x_wr_en,

    output logic [31:0]  y_out,
    output logic         done
);

    localparam MAX_N = 128;

    // BRAMs for x_vector
    logic [31:0] x_vector [0:MAX_N-1];
    genvar i;
    generate
        for (i = 0; i < MAX_N; i++) begin : GEN_X_BRAMS
            block_ram #(
                .ADDR_WIDTH(4),
                .DATA_WIDTH(32)
            ) bram_inst (
                .clk   (clk),
                .addr  (x_wr_addr),
                .wr_en (x_wr_en[i]),
                .din   (x_wr_data),
                .dout  (x_vector[i])
            );
        end
    endgenerate

   
    // Dot Product Engine
    dot_product_engine #(
        .MAX_N(MAX_N),
        .DATA_WIDTH(32)
    ) dpe_inst (
        .clk         (clk),
        .rstn        (rstn),
        .start       (start),
        .data_type   (data_type),
        .A_data      (A_data),
        .x_vector    (x_vector),
        .y_out       (y_out),
        .done        (done)
    );

endmodule
