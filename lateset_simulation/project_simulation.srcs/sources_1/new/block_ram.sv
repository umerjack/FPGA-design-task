module block_ram #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  logic                     clk,
    input  logic [ADDR_WIDTH-1:0]    addr,
    input  logic                     wr_en,
    input  logic [DATA_WIDTH-1:0]    din,
    output logic [DATA_WIDTH-1:0]    dout
);

    logic [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always_ff @(posedge clk) begin
        if (wr_en)
            mem[addr] <= din;
        dout <= mem[addr];  // Simple read-after-write, can register if needed
    end

endmodule
