module axi_dpe #(
    parameter C_S_AXI_ADDR_WIDTH = 32,
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_M_AXI_ADDR_WIDTH = 32,
    parameter C_M_AXI_DATA_WIDTH = 256,  // Changed from 512 to 256
    parameter C_M_AXI_BURST_LEN  = 1
)(
    // Global signals
    input  wire                               aclk,
    input  wire                               aresetn,

    //----------------------------------------------------------------------------
    // AXI-Lite Slave Interface
    //----------------------------------------------------------------------------
    // Write Address Channel
    input  wire                               s_axi_awvalid,
    output wire                               s_axi_awready,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_awaddr,

    input  wire [2:0]                         s_axi_awprot,

    // Write Data Channel
    input  wire                               s_axi_wvalid,
    output wire                               s_axi_wready,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]      s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]  s_axi_wstrb,

    // Write Response Channel
    output wire                               s_axi_bvalid,
    input  wire                               s_axi_bready,
    output wire [1:0]                         s_axi_bresp,

    // Read Address Channel
    input  wire                               s_axi_arvalid,
    output wire                               s_axi_arready,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_araddr,
    input  wire [2:0]                         s_axi_arprot,

    // Read Data Channel
    output wire                               s_axi_rvalid,
    input  wire                               s_axi_rready,
    output wire [C_S_AXI_DATA_WIDTH-1:0]      s_axi_rdata,
    output wire [1:0]                         s_axi_rresp,

    //----------------------------------------------------------------------------
    // AXI Master Interface
    //----------------------------------------------------------------------------
    // READ Address Channel
    output wire                               m_axi_arvalid,
    input  wire                               m_axi_arready,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]      m_axi_araddr,
    output wire [7:0]                         m_axi_arlen,
    output wire [2:0]                         m_axi_arsize,
    output wire [1:0]                         m_axi_arburst,
    output wire [2:0]                         m_axi_arprot,
    output wire [3:0]                         m_axi_arcache,

    // READ Data Channel
    input  wire                               m_axi_rvalid,
    output wire                               m_axi_rready,
    input  wire [C_M_AXI_DATA_WIDTH-1:0]      m_axi_rdata,
    input  wire [1:0]                         m_axi_rresp,
    input  wire                               m_axi_rlast,

    // WRITE Address Channel
    output wire                               m_axi_awvalid,
    input  wire                               m_axi_awready,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]      m_axi_awaddr,
    output wire [7:0]                         m_axi_awlen,
    output wire [2:0]                         m_axi_awsize,
    output wire [1:0]                         m_axi_awburst,
    output wire [2:0]                         m_axi_awprot,
    output wire [3:0]                         m_axi_awcache,

    // Write Data Channel
    output wire                               m_axi_wvalid,
    input  wire                               m_axi_wready,
    output wire [C_M_AXI_DATA_WIDTH-1:0]      m_axi_wdata,
    output wire [(C_M_AXI_DATA_WIDTH/8)-1:0]  m_axi_wstrb,
    output wire                               m_axi_wlast,

    // Write Response Channel
    input  wire                               m_axi_bvalid,
    output wire                               m_axi_bready,
    input  wire [1:0]                         m_axi_bresp,

    // Debug signals
    output wire        dma_start_debug,
    output wire        dma_busy_debug,
    output wire [1:0]  dma_status_debug,
    output wire [3:0]  master_state_debug,
    output wire [31:0] bytes_in_current_burst_debug,
    
    // Dot product engine data type
    input wire [2:0]   dpe_data_type,
    
    // BRAM preload interface
    input  wire [3:0]   x_wr_addr,
    input  wire [31:0]  x_wr_data,
    input  wire [63:0]  x_wr_en,
    
    // Dot Product Engine outputs
    output wire [31:0] dpe_out,
    output wire        dpe_done,
    
    // write valid for testbench
    output wire write_valid_o
);

    //----------------------------------------------------------------------------
    // Internal registers for AXI-Lite
    //----------------------------------------------------------------------------
    reg [C_M_AXI_ADDR_WIDTH-1:0]  dma_source_addr;
    reg [C_M_AXI_ADDR_WIDTH-1:0]  dma_target_addr;
    reg [31:0]                    dma_length;
    reg                           dma_start;
    reg                           dma_busy;
    reg [1:0]                     dma_status;     // e.g. 00=idle, 01=busy, 10=complete

    // AXI-Lite write FSM states
    localparam [1:0] AXIL_WRITE_IDLE = 2'b00,
                     AXIL_WRITE_DATA = 2'b01,
                     AXIL_WRITE_RESP = 2'b10;
    reg [1:0] axil_write_state;  // Renamed from write_state
    reg [C_S_AXI_ADDR_WIDTH-1:0] write_addr;

    // AXI-Lite read FSM states
    localparam [1:0] AXIL_READ_IDLE = 2'b00,
                     AXIL_READ_DATA = 2'b01;
    reg [1:0] axil_read_state;   // Renamed from read_state
    reg [C_S_AXI_ADDR_WIDTH-1:0] read_addr;

    // Register map (offsets in the AXI-Lite address space)
    localparam REG_SOURCE_ADDR = 5'h00;
    localparam REG_TARGET_ADDR = 5'h04;
    localparam REG_LENGTH      = 5'h08;
    localparam REG_CONTROL     = 5'h0C;
    localparam REG_STATUS      = 5'h10;
    
        // Buffer to hold an incoming 256-bit AXI read beat (32 bytes)
    reg [C_M_AXI_DATA_WIDTH-1:0] rx_data_reg;

    // For partial bursts
    integer i;
    reg [31:0] beats_reg;
    reg [31:0] bytes_in_current_burst;

    // Track if this is the last beat in the final burst
    reg is_final_burst;
    reg [5:0] final_byte_count;

    // Signals for FSM control
    reg read_grant, write_grant;
    reg read_request, write_request;
    reg read_done, write_done;
    
    //----------------------------------------------------------------------------
    // AXI Master FSM
    //----------------------------------------------------------------------------
    localparam [3:0]
        MASTER_IDLE       = 4'h0,
        MASTER_START      = 4'h1,
        MASTER_AR         = 4'h2,
        MASTER_RDATA      = 4'h3,
        MASTER_AW         = 4'h8,
        MASTER_WDATA      = 4'h9,
        MASTER_WRESP      = 4'hA;

    reg [3:0] master_state;

    // Debug signals
    assign dma_start_debug      = dma_start;
    assign dma_busy_debug       = dma_busy;
    assign dma_status_debug     = dma_status;
    assign master_state_debug   = master_state;
    assign bytes_in_current_burst_debug = bytes_in_current_burst;

    // Counters and control
    reg [31:0] transfer_count;     // count of total BYTES processed
    reg [7:0]  burst_beat_count;   // count beats within current burst
    reg        is_last_beat;       // flag for last beat in burst

    //----------------------------------------------------------------------------
    // Output registers (AXI-Lite)
    //----------------------------------------------------------------------------
    reg        s_axi_awready_r;
    reg        s_axi_wready_r;
    reg        s_axi_bvalid_r;
    reg [1:0]  s_axi_bresp_r;
    reg        s_axi_arready_r;
    reg        s_axi_rvalid_r;
    reg [31:0] s_axi_rdata_r;
    reg [1:0]  s_axi_rresp_r;

    //----------------------------------------------------------------------------
    // AXI Master read path
    //----------------------------------------------------------------------------
    reg                               m_axi_arvalid_r;
    reg [C_M_AXI_ADDR_WIDTH-1:0]      m_axi_araddr_r;
    reg [7:0]                         m_axi_arlen_r;
    reg [2:0]                         m_axi_arsize_r;
    reg [1:0]                         m_axi_arburst_r;
    reg [2:0]                         m_axi_arprot_r;
    reg [3:0]                         m_axi_arcache_r;
    reg                               m_axi_rready_r;

    //----------------------------------------------------------------------------
    // AXI Master write path
    //----------------------------------------------------------------------------
    reg                               m_axi_awvalid_r;
    reg [C_M_AXI_ADDR_WIDTH-1:0]      m_axi_awaddr_r;
    reg [7:0]                         m_axi_awlen_r;
    reg [2:0]                         m_axi_awsize_r;
    reg [1:0]                         m_axi_awburst_r;
    reg [2:0]                         m_axi_awprot_r;
    reg [3:0]                         m_axi_awcache_r;
    reg                               m_axi_wvalid_r;
    reg [C_M_AXI_DATA_WIDTH-1:0]      m_axi_wdata_r;
    reg [(C_M_AXI_DATA_WIDTH/8)-1:0]  m_axi_wstrb_r;
    reg                               m_axi_wlast_r;
    reg                               m_axi_bready_r;


    //----------------------------------------------------------------------------
    // BRAM for storing 32-bit data (256 depth)
    //----------------------------------------------------------------------------
   (* mark_debug = "true" *) reg         bram_we;
   (* mark_debug = "true" *) reg [12:0]  bram_waddr;  
   (* mark_debug = "true" *) reg [31:0]  bram_din;
   			     reg         bram_re;
   			     reg [3:0]   bram_raddr;  
   			     wire [511:0]  bram_dout;
   			     // reg [511:0]   bram_reg;
    
   /* // BRAM instantiation - 32-bit width, 8K depth
    bram_8kx32_sp bram_inst (
        .clk    (aclk),
        .en     (1'b1),       // Always enabled
        .we     (bram_we),
        .addr   (bram_waddr),
        .din    (bram_din),
        .dout   (bram_dout)
    );
    */
    
    // Not using in this build version
    //    bram_8kx32_sp bram_sdp_x_vector (
    //  .clka(aclk),    // input wire clka
    //  .ena(1'b1),      // input wire ena
    //  .wea(bram_we),      // input wire [0 : 0] wea
    //  .addra(bram_waddr[7:0]),  // input wire [7 : 0] addra
    //  .dina(bram_din),    // input wire [31 : 0] dina
    //  .clkb(aclk),    // input wire clkb
    //  .enb(1'b1),      // input wire enb
    //  .addrb(bram_raddr),  // input wire [3 : 0] addrb
    //  .doutb(bram_dout)  // output wire [511 : 0] doutb
    //);
     
    //----------------------------------------------------------------------------
    // Dot Product Engine signals
    //----------------------------------------------------------------------------
    reg         dpe_en;
    reg         dpe_valid;
    reg         dpe_start;
    wire [31:0] dpe_y_out;
    
    // Extend rx_data_reg to 256 bits for dot product engine
    reg [C_M_AXI_DATA_WIDTH-1:0] dpe_data;
       
    // Connect the dot product engine outputs to module outputs
    assign dpe_out = dpe_y_out;
    
    // Instantiate the dot product engine
   top_dot_product_engine dpe_top_inst (
        .clk         (aclk),
        .rst         (~aresetn),
        .rstn        (aresetn),
        .start       (dpe_start),
        .data_type   (dpe_data_type), 
        .A_valid     (dpe_valid),     
        .A_data      (dpe_data),
        .x_wr_addr   (x_wr_addr),     
        .x_wr_data   (x_wr_data),      
        .x_wr_en     (x_wr_en),         
        .y_out       (dpe_y_out),
        .done        (dpe_done)
    );

    //============================================================================
    // AXI-Lite Write Logic with BRAM write capability
    //============================================================================
    always @(posedge aclk) begin
        if (!aresetn) begin
            axil_write_state  <= AXIL_WRITE_IDLE;
            s_axi_awready_r   <= 1'b0;
            s_axi_wready_r    <= 1'b0;
            s_axi_bvalid_r    <= 1'b0;
            s_axi_bresp_r     <= 2'b00;
            write_addr        <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            dma_start         <= 1'b0;
            
            // Reset BRAM write signals
            bram_we           <= 1'b0;
            bram_din          <= 32'b0;
        end
        else begin
            // Default values
            bram_we <= 1'b0;
            
            // Clear the 'dma_start' once we actually move to MASTER_START
            if (master_state == MASTER_START) begin
                dma_start <= 1'b0;
            end
    
            case (axil_write_state)
                AXIL_WRITE_IDLE: begin
                    s_axi_bvalid_r  <= 1'b0;
    
                    // Accept write address if valid
                    if (!s_axi_awready_r && s_axi_awvalid) begin
                        write_addr      <= s_axi_awaddr;
                        s_axi_awready_r <= 1'b1;
                    end
    
                    // Accept write data if valid
                    if (!s_axi_wready_r && s_axi_wvalid) begin
                        s_axi_wready_r  <= 1'b1;
                    end
    
                    // Move to WRITE_DATA when both address and data phases are captured
                    if (s_axi_awready_r && s_axi_awvalid && s_axi_wready_r && s_axi_wvalid) begin
                        s_axi_awready_r <= 1'b0;
                        s_axi_wready_r  <= 1'b0;
                        axil_write_state <= AXIL_WRITE_DATA;
                    end
                end
    
                AXIL_WRITE_DATA: begin
                    // Check if address is a register address based on the lower 5 bits
                    case (write_addr[12:0])
                        13'h3EC: dma_source_addr <= s_axi_wdata; // REG_SOURCE_ADDR
                        13'h3F0: dma_target_addr <= s_axi_wdata; // REG_TARGET_ADDR
                        13'h3F4: dma_length      <= s_axi_wdata; // REG_LENGTH
                        13'h3F8: dma_start       <= s_axi_wdata[0]; // REG_CONTROL
                        13'h3FC: /* REG_STATUS is read-only */ ;
                        default: begin
                            // Write to BRAM for any address outside the register space
                           // if (write_addr[12:0] < 13'h1000) begin // Check if address is within BRAM range (8K)
                                bram_we   <= 1'b1;             // Enable BRAM write
                                bram_din  <= s_axi_wdata;      // Write the 32-bit data
                                bram_waddr <= (write_addr[12:0] >> 2); 
                          //  end
                        end
                    endcase
    
                    // Write response
                    s_axi_bvalid_r <= 1'b1;
                    s_axi_bresp_r  <= 2'b00;
                    axil_write_state <= AXIL_WRITE_RESP;
                end
    
                AXIL_WRITE_RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid_r <= 1'b0;
                        axil_write_state <= AXIL_WRITE_IDLE;
                    end
                end
            endcase
        end
    end
    
    //============================================================================
    // AXI-Lite Read Logic with BRAM read capability
    //============================================================================
    reg bram_read_in_progress;
    
    always @(posedge aclk) begin
        if (!aresetn) begin
            axil_read_state       <= AXIL_READ_IDLE;
            s_axi_arready_r       <= 1'b0;
            s_axi_rvalid_r        <= 1'b0;
            s_axi_rdata_r         <= 32'h0;
            s_axi_rresp_r         <= 2'b00;
            read_addr             <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            bram_read_in_progress <= 1'b0;   
            bram_re           <= 1'b0;
        end
        else begin    	
            bram_re <= 1'b0;
            case (axil_read_state)
                AXIL_READ_IDLE: begin
                    s_axi_rvalid_r <= 1'b0;
                    bram_read_in_progress <= 1'b0;
                    
                    if (s_axi_arvalid && !s_axi_arready_r) begin
                        read_addr       <= s_axi_araddr;
                        s_axi_arready_r <= 1'b1;
                            if (s_axi_araddr[12:0] >= 13'h300 && s_axi_araddr[12:0] <= 13'h33C) begin 
                                bram_raddr <= 4'b0; 
                                bram_re <= 1'b1;
                                bram_read_in_progress <= 1'b1;
                            end
                        axil_read_state <= AXIL_READ_DATA;
                    end
                end
    
                AXIL_READ_DATA: begin
                    s_axi_arready_r <= 1'b0;
    
                    if (!s_axi_rvalid_r) begin
                        // Check if address is a register address based on the lower 5 bits
                        case (read_addr[13:0])
                            13'h3EC: s_axi_rdata_r <= dma_source_addr; // REG_SOURCE_ADDR
                            13'h3F0: s_axi_rdata_r <= dma_target_addr; // REG_TARGET_ADDR
                            13'h3F4: s_axi_rdata_r <= dma_length;      // REG_LENGTH
                            13'h3F8: s_axi_rdata_r <= {31'h0, dma_start}; // REG_CONTROL
                            13'h3FC: s_axi_rdata_r <= {30'h0, dma_status}; // REG_STATUS
                            
                            // 512-bit wide BRAM block read, extract 32-bit slices
                            13'h300: s_axi_rdata_r <= bram_dout[ 31:  0];
                            13'h304: s_axi_rdata_r <= bram_dout[ 63: 32];
                            13'h308: s_axi_rdata_r <= bram_dout[ 95: 64];
                            13'h30C: s_axi_rdata_r <= bram_dout[127: 96];
                            13'h310: s_axi_rdata_r <= bram_dout[159:128];
                            13'h314: s_axi_rdata_r <= bram_dout[191:160];
                            13'h318: s_axi_rdata_r <= bram_dout[223:192];
                            13'h31C: s_axi_rdata_r <= bram_dout[255:224];
                            13'h320: s_axi_rdata_r <= bram_dout[287:256];
                            13'h324: s_axi_rdata_r <= bram_dout[319:288];
                            13'h328: s_axi_rdata_r <= bram_dout[351:320];
                            13'h32C: s_axi_rdata_r <= bram_dout[383:352];
                            13'h330: s_axi_rdata_r <= bram_dout[415:384];
                            13'h334: s_axi_rdata_r <= bram_dout[447:416];
                            13'h338: s_axi_rdata_r <= bram_dout[479:448];
                            13'h33C: s_axi_rdata_r <= bram_dout[511:480];
                            default: begin
                                // Reading from BRAM
                                if (bram_read_in_progress) begin
                                    
                                end else begin
                                    s_axi_rdata_r <= 32'hDEADBEEF; // Invalid address
                                    bram_re <= 1'b0;
                                end
                            end
                        endcase
                        
                        s_axi_rvalid_r <= 1'b1;
                        s_axi_rresp_r  <= 2'b00;
                    end
                    else if (s_axi_rready) begin
                        s_axi_rvalid_r <= 1'b0;
                        axil_read_state <= AXIL_READ_IDLE;
                    end
                end
            endcase
        end
    end
    
    //----------------------------------------------------------------------------
    // Wire up AXI-Lite outputs
    //----------------------------------------------------------------------------
    assign s_axi_awready = s_axi_awready_r;
    assign s_axi_wready  = s_axi_wready_r;
    assign s_axi_bvalid  = s_axi_bvalid_r;
    assign s_axi_bresp   = s_axi_bresp_r;
    assign s_axi_arready = s_axi_arready_r;
    assign s_axi_rvalid  = s_axi_rvalid_r;
    assign s_axi_rdata   = s_axi_rdata_r;
    assign s_axi_rresp   = s_axi_rresp_r;

    //----------------------------------------------------------------------------
    // Wire up AXI Master outputs (read)
    //----------------------------------------------------------------------------
    assign m_axi_arvalid = m_axi_arvalid_r;
    assign m_axi_araddr  = m_axi_araddr_r;
    assign m_axi_arlen   = m_axi_arlen_r;
    assign m_axi_arsize  = m_axi_arsize_r;
    assign m_axi_arburst = m_axi_arburst_r;
    assign m_axi_arprot  = m_axi_arprot_r;
    assign m_axi_arcache = m_axi_arcache_r;
    assign m_axi_rready  = m_axi_rready_r;

    //----------------------------------------------------------------------------
    // Wire up AXI Master outputs (write)
    //----------------------------------------------------------------------------
    assign m_axi_awvalid = m_axi_awvalid_r;
    assign m_axi_awaddr  = m_axi_awaddr_r;
    assign m_axi_awlen   = m_axi_awlen_r;
    assign m_axi_awsize  = m_axi_awsize_r;
    assign m_axi_awburst = m_axi_awburst_r;
    assign m_axi_awprot  = m_axi_awprot_r;
    assign m_axi_awcache = m_axi_awcache_r;

    assign m_axi_wvalid  = m_axi_wvalid_r;
    assign m_axi_wdata   = m_axi_wdata_r;
    assign m_axi_wstrb   = m_axi_wstrb_r;
    assign m_axi_wlast   = m_axi_wlast_r;
    assign m_axi_bready  = m_axi_bready_r;

    //============================================================================
    // Combined AXI Master DMA FSM
    //============================================================================
    // FSM States
    localparam DMA_IDLE        = 4'd0;
    localparam DMA_READ_SETUP  = 4'd1;
    localparam DMA_READ_AR     = 4'd2;
    localparam DMA_READ_DATA   = 4'd3;
    localparam DMA_READ_DONE   = 4'd4;
    localparam DMA_WAIT_DPE    = 4'd5;

    
    // FSM State Register and Control Signals
    reg [3:0] dma_state;
    
    // Dot product output accumulator
    reg [255:0] dpe_accumulator;
    reg [2:0]   dpe_count;
    
    // Fifo write valid and data signal for DMA write FSM
    reg write_valid;
    reg [255:0] write_fifo;
    
    // Indicates 256-bit (32*8) data is ready for write
    assign write_valid_o = write_valid;
    
    // =============================================================================
    // DMA READ FSM (Read from DDR -> Feed to DPE)
    // =============================================================================
    always @(posedge aclk) begin
        if (!aresetn) begin
            // Reset state
            dma_state           <= DMA_IDLE;
            dma_busy            <= 1'b0;
            dma_status          <= 2'b00;  // idle
            transfer_count      <= 32'h0;
            read_done           <= 1'b0;
            write_done          <= 1'b0;
            read_request        <= 1'b0;
            write_request       <= 1'b0;
            is_final_burst      <= 1'b0;
            final_byte_count    <= 6'd0;
            bytes_in_current_burst <= 32'd0;
            burst_beat_count    <= 8'd0;
            is_last_beat        <= 1'b0;
            
            // Dot Product Engine control
            dpe_en              <= 1'b0;
            dpe_valid           <= 1'b0;
            dpe_start           <= 1'b0;
            
            //dot product output accumulaiton
//            write_fifo          <= 256'd0;
//            write_valid         <= 1'd0;
//            dpe_count           <= 3'd0;
//            dpe_accumulator     <= 256'd0;
            
            // Read channel
            m_axi_arvalid_r     <= 1'b0;
            m_axi_araddr_r      <= {C_M_AXI_ADDR_WIDTH{1'b0}};
            m_axi_arlen_r       <= 8'h0;
            m_axi_arsize_r      <= 3'b000;
            m_axi_arburst_r     <= 2'b01;  // INCR
            m_axi_arprot_r      <= 3'b000;
            m_axi_arcache_r     <= 4'b0011;
            m_axi_rready_r      <= 1'b0;
    
            // Write channel
            m_axi_awvalid_r     <= 1'b0;
            m_axi_awaddr_r      <= {C_M_AXI_ADDR_WIDTH{1'b0}};
            m_axi_awlen_r       <= 8'h0;
            m_axi_awsize_r      <= 3'b000;
            m_axi_awburst_r     <= 2'b01;  // INCR
            m_axi_awprot_r      <= 3'b000;
            m_axi_awcache_r     <= 4'b0011;
            m_axi_wvalid_r      <= 1'b0;
            m_axi_wdata_r       <= {C_M_AXI_DATA_WIDTH{1'b0}};
            m_axi_wstrb_r       <= {(C_M_AXI_DATA_WIDTH/8){1'b1}};
            m_axi_wlast_r       <= 1'b0;
            m_axi_bready_r      <= 1'b0;
    
            rx_data_reg         <= {C_M_AXI_DATA_WIDTH{1'b0}};
        end
        else begin
            // FSM state transitions
            case (dma_state)
                DMA_IDLE: begin
                    // Reset signals
                    m_axi_arvalid_r <= 1'b0;
                    m_axi_rready_r  <= 1'b0;
                    m_axi_awvalid_r <= 1'b0;
                    m_axi_wvalid_r  <= 1'b0;
                    m_axi_bready_r  <= 1'b0;
                    m_axi_wlast_r   <= 1'b0;
                    read_done       <= 1'b0;
                    write_done      <= 1'b0;
                    dpe_en          <= 1'b0;
                    dpe_valid       <= 1'b0;
                    dpe_start       <= 1'b0;
                    dpe_data        <= 1'b0;  
                   // write_fifo         <=256'd0;
                   // write_valid     <=1'b0;
                    if (dma_start && !dma_busy) begin
                        dma_busy    <= 1'b1;
                        dma_status  <= 2'b01;  // busy
    
                        // Check if there's data to transfer
                        if (transfer_count < dma_length) begin
                            // Start with read operation
                            dma_state <= DMA_READ_SETUP;
                        end
                        else begin
                            // No data to process
                            dma_busy     <= 1'b0;
                            dma_status   <= 2'b10; // complete
                            dma_state    <= DMA_IDLE;
                        end
                    end
                end
    
                //============================================================================
                // Read Operation States
                //============================================================================
                DMA_READ_SETUP: begin
                    // Check if this is the final burst
                    is_final_burst <= ((dma_length - transfer_count) <=
                                      (C_M_AXI_BURST_LEN * (C_M_AXI_DATA_WIDTH/8)));
    
                    // Decide how many bytes to read in this burst:
                    if ((dma_length - transfer_count) >=
                       (C_M_AXI_BURST_LEN * (C_M_AXI_DATA_WIDTH/8))) begin
                        m_axi_arlen_r  <= C_M_AXI_BURST_LEN - 1;
                        bytes_in_current_burst <= (C_M_AXI_BURST_LEN * (C_M_AXI_DATA_WIDTH/8));
                        final_byte_count <= 6'd31; // Use all bytes in the final beat
                    end
                    else begin
                        // Calculate the number of full beats needed (round up)
                        if ((dma_length - transfer_count) % (C_M_AXI_DATA_WIDTH/8) == 0) begin
                            beats_reg = (dma_length - transfer_count) / (C_M_AXI_DATA_WIDTH/8);
                        end
                        else begin
                            beats_reg = ((dma_length - transfer_count) / (C_M_AXI_DATA_WIDTH/8)) + 1;
                        end
    
                        // Ensure at least one beat
                        if (beats_reg == 0)
                            beats_reg = 1;
    
                        m_axi_arlen_r <= beats_reg[7:0] - 1;
                        bytes_in_current_burst <= dma_length - transfer_count;
    
                        // Calculate how many bytes we'll use in the final beat
                        final_byte_count <= ((dma_length - transfer_count) % (C_M_AXI_DATA_WIDTH/8) == 0) ?
                                            6'd31 : // Use all bytes if perfectly aligned
                                            ((dma_length - transfer_count) % (C_M_AXI_DATA_WIDTH/8) - 1); // Otherwise partial
                    end
    
                    // Setup read address
                    m_axi_araddr_r  <= dma_source_addr + transfer_count;
                    m_axi_arsize_r  <= 3'b101;  // 32 bytes (256 bits)
                    m_axi_arvalid_r <= 1'b1;
                    m_axi_rready_r  <= 1'b1;
                    dma_state       <= DMA_READ_AR;
                end
    
                DMA_READ_AR: begin
                    if (m_axi_arready && m_axi_arvalid_r) begin
                        m_axi_arvalid_r <= 1'b0;
                        dma_state       <= DMA_READ_DATA;
                    end
                end
    
                DMA_READ_DATA: begin
                    // Receive data from DDR and process via DPE
                    if (m_axi_rvalid && m_axi_rready_r) begin
                        // Latch incoming AXI read data
                        rx_data_reg <= m_axi_rdata;
                        dpe_data    <= m_axi_rdata;
                    
                        // Start dot product engine
                        dpe_valid   <= 1'b1;
                        dpe_start   <= 1'b1;   
                        
                    // DPE output accumulation   
//                    if (dpe_done) begin
//                          dpe_accumulator <= {dpe_accumulator[223:0], dpe_y_out};
//                          dpe_count <= dpe_count + 1;
//                          write_valid<=1'b0;
//                      // Once 8 outputs collected (256 bits), store for write
//                      if (dpe_count == 3'd7) begin
//                          dpe_count <= 3'd0;
//                          write_fifo <= {dpe_accumulator[223:0], dpe_y_out};  
//                          write_valid <= 1'b1;
//                          dpe_accumulator <= 256'd0;
//                        end
//                    end
                                 
                    // Update transfer count on *every beat*
                    transfer_count <= transfer_count + (C_M_AXI_DATA_WIDTH / 8);  // +32 for 256-bit
                    
                    // Handling last AXI beat 
                    if (m_axi_rlast && dpe_count != 3'd7) begin //
                        m_axi_rready_r <= 1'b0;
                
                        if ((transfer_count + (C_M_AXI_DATA_WIDTH / 8)) < dma_length) begin
                            dma_state <= DMA_READ_SETUP;
                        end else begin
                            dma_busy   <= 1'b0;
                            dma_status <= 2'b10;
                            dma_state  <= DMA_IDLE;
                        end
                    end
                end
             end         
           endcase
        end 
    end 
    
    
    //output accumlation of dpe logic
    always @(posedge aclk) begin
              if (!aresetn) begin
                       write_fifo          <= 256'd0;
                       write_valid         <= 1'd0;
                       dpe_count           <= 3'd0;
                       dpe_accumulator     <= 256'd0;
              end 
              else begin
    
                  if (dpe_done) begin
                          dpe_accumulator <= {dpe_accumulator[223:0], dpe_y_out};
                          dpe_count <= dpe_count + 1;
                          write_valid<=1'b0;
                      // Once 8 outputs collected (256 bits), store for write
                      if (dpe_count == 3'd7) begin
                          dpe_count <= 3'd0;
                          write_fifo <= {dpe_accumulator[223:0], dpe_y_out};  
                          write_valid <= 1'b1;
                          dpe_accumulator <= 256'd0;
                        end
                    end   
             end 
      end 
    
    // FSM for dma write operation to DDR memory
    reg [3:0] dma_write_state;
        
    // FSM state encoding
    localparam DMA_WRITE_IDLE  = 4'd0;  // Wait for write_valid
    localparam DMA_WRITE_AW    = 4'd1;  // Address write phase
    localparam DMA_WRITE_DATA  = 4'd2;  // Data write phase
    localparam DMA_WRITE_RESP  = 4'd3;  // Write response phase

    // Offset for calculating next DDR write address
    reg [31:0] write_offset;
    
    // =============================================================================
    // DMA WRITE FSM (Write 256-bit result → DDR memory)
    // =============================================================================  
    always @(posedge aclk) begin
    if (!aresetn) begin
        dma_write_state <= DMA_WRITE_IDLE;
        write_valid  <= 1'b0;
        write_offset <= 32'b0;
    end else begin
        case (dma_write_state)
            DMA_WRITE_IDLE: begin
                if (write_valid) begin
                    // Setup AXI write address
                    m_axi_awaddr_r  <= dma_target_addr + write_offset;
                    m_axi_awlen_r   <= 8'd0;
                    m_axi_awsize_r  <= 3'b101;  // 32 bytes = 256 bits
                    m_axi_awvalid_r <= 1'b1;
                    dma_write_state <= DMA_WRITE_AW;
                end
            end

            DMA_WRITE_AW: begin
                if (m_axi_awready && m_axi_awvalid_r) begin
                    // Send write data
                    m_axi_awvalid_r <= 1'b0;
                    m_axi_wdata_r   <= write_fifo;
                    m_axi_wvalid_r  <= 1'b1;
                    m_axi_wlast_r   <= 1'b1;
                    dma_write_state <= DMA_WRITE_DATA;
                end
            end

            DMA_WRITE_DATA: begin
                if (m_axi_wready && m_axi_wvalid_r) begin
                    m_axi_wvalid_r  <= 1'b0;
                    m_axi_wlast_r   <= 1'b0;
                    m_axi_bready_r  <= 1'b1;
                    dma_write_state <= DMA_WRITE_RESP;
                end
            end

            DMA_WRITE_RESP: begin
                if (m_axi_bvalid && m_axi_bready_r) begin
                    m_axi_bready_r <= 1'b0;
                    write_valid<= 1'b0;
                    write_offset   <= write_offset + 32;  // next address -> next 256-bit write
                    dma_write_state <= DMA_WRITE_IDLE;
                end
            end
        endcase
    end
end

    
endmodule