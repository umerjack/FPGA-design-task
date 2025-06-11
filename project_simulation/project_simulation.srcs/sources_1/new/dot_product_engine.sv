`timescale 1ns/1ps

module dot_product_engine #(
    parameter int MAX_N = 128,
    parameter int DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rstn,
    input  logic                  start,
    input  logic [2:0]            data_type,
    input  logic [255:0]          A_data, // fixed DDR width
    input  logic [DATA_WIDTH-1:0] x_vector [0:MAX_N-1],
    output logic [DATA_WIDTH-1:0] y_out,
    output logic                  done
);

    logic [15:0] A_raw [0:MAX_N-1];
    logic [255:0] A_data_reg; 
    
    // Register input only when start is asserted
    assign A_data_reg = start ? A_data : 0;
   
    // Unpack A_data into raw integers depending on data_type
    always_comb begin
        for (int i = 0; i < MAX_N; i++) begin
            case (data_type)
                3'd0: A_raw[i] = (i < 128) ? {{14{A_data_reg[i*2+1]}},  A_data_reg[i*2 +: 2]}  : 16'd0;
                3'd1: A_raw[i] = (i < 64)  ? {{12{A_data_reg[i*4+3]}},  A_data_reg[i*4 +: 4]}  : 16'd0;
                3'd2: A_raw[i] = (i < 32)  ? {{8{A_data_reg[i*8+7]}},   A_data_reg[i*8 +: 8]}  : 16'd0;
                3'd3: A_raw[i] = (i < 32)  ? {8'd0, A_data_reg[i*8 +: 8]}                         : 16'd0;
                3'd4: A_raw[i] = (i < 16)  ? A_data_reg[i*16 +: 16]                              : 16'd0;
                3'd5: A_raw[i] = (i < 16)  ? A_data_reg[i*16 +: 16]                              : 16'd0;
                default: A_raw[i] = 16'd0;
            endcase
        end
    end

    // Convert to FP32, each A_raw[i] to FP32 based on data_type
    logic [DATA_WIDTH-1:0] A_fp32 [0:MAX_N-1];
    logic                  A_valid [0:MAX_N-1];
    generate
        for (genvar i = 0; i < MAX_N; i++) begin : GEN_CONVERT
            intN_to_fp32_wrapper convert (
                .clk         (clk),
                .rstn        (rstn),
                .data_type   (data_type),
                .raw_data_in (A_raw[i]),
                .start       (start),
                .ready       (),
                .result      (A_fp32[i]),
                .valid       (A_valid[i])
            );
        end
    endgenerate

    // Multiply with x_vector
    logic [DATA_WIDTH-1:0] prod_fp32 [0:MAX_N-1];
    logic                  prod_valid [0:MAX_N-1];
    generate
        for (genvar i = 0; i < MAX_N; i++) begin : GEN_MUL
            floating_point_1 fp_mult (
                .aclk(clk),
                .aresetn(rstn),
                .s_axis_a_tvalid(A_valid[i]),
                .s_axis_a_tdata(A_fp32[i]),
                .s_axis_b_tvalid(A_valid[i]),
                .s_axis_b_tdata(x_vector[i]),
                .m_axis_result_tvalid(prod_valid[i]),
                .m_axis_result_tdata(prod_fp32[i]),
                .s_axis_a_tready(),
                .s_axis_b_tready(),
                .m_axis_result_tready(1'b1)
            );
        end
    endgenerate

    // Adder tree stages
    logic [DATA_WIDTH-1:0] sum_stage0 [0:127];
    logic [DATA_WIDTH-1:0] sum_stage1 [0:63];
    logic [DATA_WIDTH-1:0] sum_stage2 [0:31];
    logic [DATA_WIDTH-1:0] sum_stage3 [0:15];
    logic [DATA_WIDTH-1:0] sum_stage4 [0:7];
    logic [DATA_WIDTH-1:0] sum_stage5 [0:3];
    logic [DATA_WIDTH-1:0] sum_stage6 [0:1];

    logic valid_stage0 [0:127];
    logic valid_stage1 [0:63];
    logic valid_stage2 [0:31];
    logic valid_stage3 [0:15];
    logic valid_stage4 [0:7];
    logic valid_stage5 [0:3];
    logic valid_stage6 [0:1];

    // Adder tree: progressively adds multiple inputs in pairs across stages
    generate
        for (genvar i = 0; i < MAX_N; i++) begin
            assign sum_stage0[i]    = prod_valid[i] ? prod_fp32[i] : 32'd0;
            assign valid_stage0[i]  = prod_valid[i];
        end

        for (genvar i = 0; i < 64; i++) begin
            floating_point_2 add1 (
                .aclk(clk), .aresetn(rstn),
                .s_axis_a_tvalid(valid_stage0[2*i]),
                .s_axis_a_tdata(sum_stage0[2*i]),
                .s_axis_b_tvalid(valid_stage0[2*i+1]),
                .s_axis_b_tdata(sum_stage0[2*i+1]),
                .m_axis_result_tvalid(valid_stage1[i]),
                .m_axis_result_tdata(sum_stage1[i]),
                .s_axis_a_tready(), .s_axis_b_tready(), .m_axis_result_tready(1'b1)
            );
        end
        for (genvar i = 0; i < 32; i++) begin
            floating_point_2 add2 (
                .aclk(clk), .aresetn(rstn),
                .s_axis_a_tvalid(valid_stage1[2*i]),
                .s_axis_a_tdata(sum_stage1[2*i]),
                .s_axis_b_tvalid(valid_stage1[2*i+1]),
                .s_axis_b_tdata(sum_stage1[2*i+1]),
                .m_axis_result_tvalid(valid_stage2[i]),
                .m_axis_result_tdata(sum_stage2[i]),
                .s_axis_a_tready(), .s_axis_b_tready(), .m_axis_result_tready(1'b1)
            );
        end
        for (genvar i = 0; i < 16; i++) begin
            floating_point_2 add3 (
                .aclk(clk), .aresetn(rstn),
                .s_axis_a_tvalid(valid_stage2[2*i]),
                .s_axis_a_tdata(sum_stage2[2*i]),
                .s_axis_b_tvalid(valid_stage2[2*i+1]),
                .s_axis_b_tdata(sum_stage2[2*i+1]),
                .m_axis_result_tvalid(valid_stage3[i]),
                .m_axis_result_tdata(sum_stage3[i]),
                .s_axis_a_tready(), .s_axis_b_tready(), .m_axis_result_tready(1'b1)
            );
        end
        for (genvar i = 0; i < 8; i++) begin
            floating_point_2 add4 (
                .aclk(clk), .aresetn(rstn),
                .s_axis_a_tvalid(valid_stage3[2*i]),
                .s_axis_a_tdata(sum_stage3[2*i]),
                .s_axis_b_tvalid(valid_stage3[2*i+1]),
                .s_axis_b_tdata(sum_stage3[2*i+1]),
                .m_axis_result_tvalid(valid_stage4[i]),
                .m_axis_result_tdata(sum_stage4[i]),
                .s_axis_a_tready(), .s_axis_b_tready(), .m_axis_result_tready(1'b1)
            );
        end
        for (genvar i = 0; i < 4; i++) begin
            floating_point_2 add5 (
                .aclk(clk), .aresetn(rstn),
                .s_axis_a_tvalid(valid_stage4[2*i]),
                .s_axis_a_tdata(sum_stage4[2*i]),
                .s_axis_b_tvalid(valid_stage4[2*i+1]),
                .s_axis_b_tdata(sum_stage4[2*i+1]),
                .m_axis_result_tvalid(valid_stage5[i]),
                .m_axis_result_tdata(sum_stage5[i]),
                .s_axis_a_tready(), .s_axis_b_tready(), .m_axis_result_tready(1'b1)
            );
        end
        for (genvar i = 0; i < 2; i++) begin
            floating_point_2 add6 (
                .aclk(clk), .aresetn(rstn),
                .s_axis_a_tvalid(valid_stage5[2*i]),
                .s_axis_a_tdata(sum_stage5[2*i]),
                .s_axis_b_tvalid(valid_stage5[2*i+1]),
                .s_axis_b_tdata(sum_stage5[2*i+1]),
                .m_axis_result_tvalid(valid_stage6[i]),
                .m_axis_result_tdata(sum_stage6[i]),
                .s_axis_a_tready(), .s_axis_b_tready(), .m_axis_result_tready(1'b1)
            );
        end
    endgenerate

    // Final stage: Add last two values to get dot product
    floating_point_2 add7 (
        .aclk(clk), .aresetn(rstn),
        .s_axis_a_tvalid(valid_stage6[0]),
        .s_axis_a_tdata(sum_stage6[0]),
        .s_axis_b_tvalid(valid_stage6[1]),
        .s_axis_b_tdata(sum_stage6[1]),
        .m_axis_result_tvalid(done),
        .m_axis_result_tdata(y_out),
        .s_axis_a_tready(), .s_axis_b_tready(), .m_axis_result_tready(1'b1)
    );

endmodule
