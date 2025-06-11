module intN_to_fp32_wrapper (
    input  logic        clk,
    input  logic        rstn,
    input  logic [2:0]  data_type,     // 0=int2, 1=int4, 2=int8, 3=uint8, 4=fp16, 5=bf16
    input  logic [15:0] raw_data_in,   // Raw input (lower bits used based on type)
    input  logic        start,
    output logic        ready,
    output logic [31:0] result,
    output logic        valid
);

    typedef enum logic [2:0] {
        INT2  = 3'd0,
        INT4  = 3'd1,
        INT8  = 3'd2,
        UINT8 = 3'd3,
        FP16  = 3'd4,
        BF16  = 3'd5
    } data_t;

    // Common wires
    logic [31:0] fixed_data;
    logic [15:0] fp16_data;
    logic [15:0] bf16_data;

    logic [31:0] int_result;
    logic [31:0] fp16_result;
    logic [31:0] bf16_result;

    logic        int_valid, fp16_valid, bf16_valid;
    logic        int_ready, fp16_ready, bf16_ready;

    // ========================================================
    // Input pre-processing
    // ========================================================
    always_comb begin
        case (data_type)
            INT2:   fixed_data = {{30{raw_data_in[1]}}, raw_data_in[1:0]};
            INT4:   fixed_data = {{28{raw_data_in[3]}}, raw_data_in[3:0]};
            INT8:   fixed_data = {{24{raw_data_in[7]}}, raw_data_in[7:0]};
            UINT8:  fixed_data = {24'b0, raw_data_in[7:0]};
            default: fixed_data = 32'd0;
        endcase
        fp16_data = raw_data_in[15:0];
        bf16_data = raw_data_in[15:0];
    end

    // ========================================================
    // IP Instance: Fixed-point to FP32 (for INTx/UINT8)
    // ========================================================
    floating_point_0 fixed2float_inst (
        .aclk                 (clk),
        .aresetn              (rstn),
        .s_axis_a_tvalid      (start && (data_type <= UINT8)),
        .s_axis_a_tready      (int_ready),
        .s_axis_a_tdata       (fixed_data),
        .m_axis_result_tvalid (int_valid),
        .m_axis_result_tready (1'b1),
        .m_axis_result_tdata  (int_result)
    );

    // ========================================================
    // IP Instance: FP16 to FP32
    // ========================================================
    floating_point_3 fp16_to_fp32_inst (
        .aclk                 (clk),
        .aresetn              (rstn),
        .s_axis_a_tvalid      (start && (data_type == FP16)),
        .s_axis_a_tready      (fp16_ready),
        .s_axis_a_tdata       (fp16_data),
        .m_axis_result_tvalid (fp16_valid),
        .m_axis_result_tready (1'b1),
        .m_axis_result_tdata  (fp16_result)
    );

    // ========================================================
    // IP Instance: BF16 to FP32
    // ========================================================
    floating_point_3 bf16_to_fp32_inst (
        .aclk                 (clk),
        .aresetn              (rstn),
        .s_axis_a_tvalid      (start && (data_type == BF16)),
        .s_axis_a_tready      (bf16_ready),
        .s_axis_a_tdata       (bf16_data),
        .m_axis_result_tvalid (bf16_valid),
        .m_axis_result_tready (1'b1),
        .m_axis_result_tdata  (bf16_result)
    );

    // ========================================================
    // Output Selection Logic
    // ========================================================
    always_comb begin
        case (data_type)
            INT2, INT4, INT8, UINT8: begin
                result = int_result;
                valid  = int_valid;
                ready  = int_ready;
            end
            FP16: begin
                result = fp16_result;
                valid  = fp16_valid;
                ready  = fp16_ready;
            end
            BF16: begin
                result = bf16_result;
                valid  = bf16_valid;
                ready  = bf16_ready;
            end
            default: begin
                result = 32'd0;
                valid  = 1'b0;
                ready  = 1'b1;
            end
        endcase
    end

endmodule
