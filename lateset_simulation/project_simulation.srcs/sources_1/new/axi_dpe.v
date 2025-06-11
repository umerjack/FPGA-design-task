`timescale 1ns / 1ps


module axi_dpe #(
    parameter C_S_AXI_ADDR_WIDTH = 32,
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_M_AXI_ADDR_WIDTH = 32,
    parameter C_M_AXI_DATA_WIDTH = 256,  // Changed from 512 to 256
    parameter C_M_AXI_BURST_LEN  = 128
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
    
    // Dot Product Engine outputs
    output wire [255:0] dpe_wr_ready_out,
    output reg        write_valid,
    output wire        dpe_done
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
    reg [C_M_AXI_ADDR_WIDTH-1:0]  bram_raddr_debug;

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
    
    reg [31:0] bytes_in_current_burst;

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

    // Buffer to hold an incoming 256-bit AXI read beat (32 bytes)
    reg [C_M_AXI_DATA_WIDTH-1:0] rx_data_reg;

    // For partial bursts
    integer i;
    reg [31:0] beats_reg;

    // Track if this is the last beat in the final burst
    reg is_final_burst;
    reg [5:0] final_byte_count;

    // Signals for FSM control
    reg read_grant, write_grant;
    reg read_request, write_request;
    reg read_done, write_done;
    
    //----------------------------------------------------------------------------
    // BRAM for storing 32-bit data (256 depth)
    //----------------------------------------------------------------------------
   (* mark_debug = "true" *) reg         bram_we;
   (* mark_debug = "true" *) reg   bram_waddr;  
   (* mark_debug = "true" *) reg [4095:0]  bram_din;
   			     reg         bram_re;
   			     reg   bram_raddr;  
   			     wire [4095:0]  bram_dout;
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
 /*   bram_w32x256_r512x16 bram_sdp_x_vector (
  .clka(aclk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(bram_we),      // input wire [0 : 0] wea
  .addra(bram_waddr[7:0]),  // input wire [7 : 0] addra
  .dina(bram_din),    // input wire [31 : 0] dina
  .clkb(aclk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .addrb(bram_raddr),  // input wire [3 : 0] addrb
  .doutb(bram_dout)  // output wire [511 : 0] doutb
); */
  
  sdp_w4096x2_r4096x2 bram_sdp_x_vector (
  .clka(aclk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(bram_we),      // input wire [0 : 0] wea
  .addra(1'b0),  // input wire [0 : 0] addra
  .dina(bram_din),    // input wire [4095 : 0] dina
  .clkb(aclk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .addrb(1'b0),  // input wire [0 : 0] addrb
  .doutb(bram_dout)  // output wire [4095 : 0] doutb
);  


   
    //----------------------------------------------------------------------------
    // Dot Product Engine signals
    //----------------------------------------------------------------------------
    (* mark_debug = "true" *) reg         dpe_en;
    (* mark_debug = "true" *) reg         dpe_start;
    wire [31:0] dpe_y_out;
    (* mark_debug = "true" *) reg  [255:0] dpe_dout_debug;
    
    // Extend rx_data_reg to 512 bits for dot product engine
    wire [C_M_AXI_DATA_WIDTH-1:0] dpe_a_row_packed;
    
    
    assign dpe_a_row_packed = rx_data_reg;
    
    // Connect the dot product engine outputs to module outputs
    assign dpe_wr_ready_out = dpe_dout_debug;
    
    // Instantiate the dot product engine
    top_dot_product_engine dot_product_inst (
        .clk          (aclk),
        .rst          (~aresetn),
        .rstn         (aresetn),
       // .en           (dpe_en),
       . data_type    (3'b010),
        .start        (dpe_start), 
        .A_valid      (dpe_en),
    	.A_data	      (dpe_a_row_packed),
    	.x_vector     (bram_dout),
    	   
        .y_out        (dpe_y_out),
        .done         (dpe_done)
    );


reg [4095:0] accum_buffer;
reg [6:0] accum_word_count;
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
        
        //buffer signals
        accum_buffer      <= 4096'b0;
	accum_word_count  <= 7'd0;
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
                    13'h800: dma_source_addr <= s_axi_wdata; // REG_SOURCE_ADDR
                    13'h804: dma_target_addr <= s_axi_wdata; // REG_TARGET_ADDR
                    13'h808: dma_length      <= s_axi_wdata; // REG_LENGTH
                    13'h80C: dma_start       <= s_axi_wdata[0]; // REG_CONTROL
                    13'h810: /* REG_STATUS is read-only */ ;
                    
                    
                    
                    default: begin
                        // Write to BRAM for any address outside the register space
                       
                            // Shift new 32-bit word into the accumulation buffer
    			    accum_buffer <= {accum_buffer[4063:0], s_axi_wdata};
    			    accum_word_count <= accum_word_count + 1;
    			    
    			    // When 128 words (4096 bits) are collected, write to BRAM
    				if (accum_word_count == 7'd127) begin
        				bram_we     <= 1'b1;
        				bram_din    <= accum_buffer; 
        				bram_waddr  <= 2'b00;;

        				accum_word_count <= 0;
        				accum_buffer <= 4096'b0;
   				 end
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
                        if (s_axi_araddr[12:0] >= 13'h300 && s_axi_araddr[12:0] <= 13'h4FC) begin 
                            //bram_raddr <= bram_raddr_debug[3:0]; 
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
                        13'h800: s_axi_rdata_r <= dma_source_addr; // REG_SOURCE_ADDR
                        13'h804: s_axi_rdata_r <= dma_target_addr; // REG_TARGET_ADDR
                        13'h808: s_axi_rdata_r <= dma_length;      // REG_LENGTH
                        13'h80C: s_axi_rdata_r <= {31'h0, dma_start}; // REG_CONTROL
                        13'h810: s_axi_rdata_r <= {30'h0, dma_status}; // REG_STATUS
                        
                        //  4096-bit wide BRAM block read, extract 32-bit slices
                            13'h300: s_axi_rdata_r <= bram_dout[  31:   0];
			    13'h304: s_axi_rdata_r <= bram_dout[  63:  32];
			    13'h308: s_axi_rdata_r <= bram_dout[  95:  64];
			    13'h30C: s_axi_rdata_r <= bram_dout[ 127:  96];
			    13'h310: s_axi_rdata_r <= bram_dout[ 159: 128];
			    13'h314: s_axi_rdata_r <= bram_dout[ 191: 160];
			    13'h318: s_axi_rdata_r <= bram_dout[ 223: 192];
			    13'h31C: s_axi_rdata_r <= bram_dout[ 255: 224];
			    13'h320: s_axi_rdata_r <= bram_dout[ 287: 256];
			    13'h324: s_axi_rdata_r <= bram_dout[ 319: 288];
			    13'h328: s_axi_rdata_r <= bram_dout[ 351: 320];
			    13'h32C: s_axi_rdata_r <= bram_dout[ 383: 352];
			    13'h330: s_axi_rdata_r <= bram_dout[ 415: 384];
			    13'h334: s_axi_rdata_r <= bram_dout[ 447: 416];
			    13'h338: s_axi_rdata_r <= bram_dout[ 479: 448];
			    13'h33C: s_axi_rdata_r <= bram_dout[ 511: 480];
			    13'h340: s_axi_rdata_r <= bram_dout[ 543: 512];
			    13'h344: s_axi_rdata_r <= bram_dout[ 575: 544];
			    13'h348: s_axi_rdata_r <= bram_dout[ 607: 576];
			    13'h34C: s_axi_rdata_r <= bram_dout[ 639: 608];
			    13'h350: s_axi_rdata_r <= bram_dout[ 671: 640];
			    13'h354: s_axi_rdata_r <= bram_dout[ 703: 672];
			    13'h358: s_axi_rdata_r <= bram_dout[ 735: 704];
			    13'h35C: s_axi_rdata_r <= bram_dout[ 767: 736];
			    13'h360: s_axi_rdata_r <= bram_dout[ 799: 768];
			    13'h364: s_axi_rdata_r <= bram_dout[ 831: 800];
			    13'h368: s_axi_rdata_r <= bram_dout[ 863: 832];
			    13'h36C: s_axi_rdata_r <= bram_dout[ 895: 864];
			    13'h370: s_axi_rdata_r <= bram_dout[ 927: 896];
			    13'h374: s_axi_rdata_r <= bram_dout[ 959: 928];
			    13'h378: s_axi_rdata_r <= bram_dout[ 991: 960];
			    13'h37C: s_axi_rdata_r <= bram_dout[1023: 992];
			    13'h380: s_axi_rdata_r <= bram_dout[1055:1024];
			    13'h384: s_axi_rdata_r <= bram_dout[1087:1056];
			    13'h388: s_axi_rdata_r <= bram_dout[1119:1088];
			    13'h38C: s_axi_rdata_r <= bram_dout[1151:1120];
			    13'h390: s_axi_rdata_r <= bram_dout[1183:1152];
			    13'h394: s_axi_rdata_r <= bram_dout[1215:1184];
			    13'h398: s_axi_rdata_r <= bram_dout[1247:1216];
			    13'h39C: s_axi_rdata_r <= bram_dout[1279:1248];
			    13'h3A0: s_axi_rdata_r <= bram_dout[1311:1280];
			    13'h3A4: s_axi_rdata_r <= bram_dout[1343:1312];
			    13'h3A8: s_axi_rdata_r <= bram_dout[1375:1344];
			    13'h3AC: s_axi_rdata_r <= bram_dout[1407:1376];
			    13'h3B0: s_axi_rdata_r <= bram_dout[1439:1408];
			    13'h3B4: s_axi_rdata_r <= bram_dout[1471:1440];
			    13'h3B8: s_axi_rdata_r <= bram_dout[1503:1472];
			    13'h3BC: s_axi_rdata_r <= bram_dout[1535:1504];
			    13'h3C0: s_axi_rdata_r <= bram_dout[1567:1536];
			    13'h3C4: s_axi_rdata_r <= bram_dout[1599:1568];
			    13'h3C8: s_axi_rdata_r <= bram_dout[1631:1600];
			    13'h3CC: s_axi_rdata_r <= bram_dout[1663:1632];
			    13'h3D0: s_axi_rdata_r <= bram_dout[1695:1664];
			    13'h3D4: s_axi_rdata_r <= bram_dout[1727:1696];
			    13'h3D8: s_axi_rdata_r <= bram_dout[1759:1728];
			    13'h3DC: s_axi_rdata_r <= bram_dout[1791:1760];
			    13'h3E0: s_axi_rdata_r <= bram_dout[1823:1792];
			    13'h3E4: s_axi_rdata_r <= bram_dout[1855:1824];
			    13'h3E8: s_axi_rdata_r <= bram_dout[1887:1856];
			    13'h3EC: s_axi_rdata_r <= bram_dout[1919:1888];
			    13'h3F0: s_axi_rdata_r <= bram_dout[1951:1920];
			    13'h3F4: s_axi_rdata_r <= bram_dout[1983:1952];
			    13'h3F8: s_axi_rdata_r <= bram_dout[2015:1984];
			    13'h3FC: s_axi_rdata_r <= bram_dout[2047:2016];
			    13'h400: s_axi_rdata_r <= bram_dout[2079:2048];
			    13'h404: s_axi_rdata_r <= bram_dout[2111:2080];
			    13'h408: s_axi_rdata_r <= bram_dout[2143:2112];
			    13'h40C: s_axi_rdata_r <= bram_dout[2175:2144];
			    13'h410: s_axi_rdata_r <= bram_dout[2207:2176];
			    13'h414: s_axi_rdata_r <= bram_dout[2239:2208];
			    13'h418: s_axi_rdata_r <= bram_dout[2271:2240];
			    13'h41C: s_axi_rdata_r <= bram_dout[2303:2272];
			    13'h420: s_axi_rdata_r <= bram_dout[2335:2304];
			    13'h424: s_axi_rdata_r <= bram_dout[2367:2336];
			    13'h428: s_axi_rdata_r <= bram_dout[2399:2368];
			    13'h42C: s_axi_rdata_r <= bram_dout[2431:2400];
			    13'h430: s_axi_rdata_r <= bram_dout[2463:2432];
			    13'h434: s_axi_rdata_r <= bram_dout[2495:2464];
			    13'h438: s_axi_rdata_r <= bram_dout[2527:2496];
			    13'h43C: s_axi_rdata_r <= bram_dout[2559:2528];
			    13'h440: s_axi_rdata_r <= bram_dout[2591:2560];
			    13'h444: s_axi_rdata_r <= bram_dout[2623:2592];
			    13'h448: s_axi_rdata_r <= bram_dout[2655:2624];
			    13'h44C: s_axi_rdata_r <= bram_dout[2687:2656];
			    13'h450: s_axi_rdata_r <= bram_dout[2719:2688];
			    13'h454: s_axi_rdata_r <= bram_dout[2751:2720];
			    13'h458: s_axi_rdata_r <= bram_dout[2783:2752];
			    13'h45C: s_axi_rdata_r <= bram_dout[2815:2784];
			    13'h460: s_axi_rdata_r <= bram_dout[2847:2816];
			    13'h464: s_axi_rdata_r <= bram_dout[2879:2848];
			    13'h468: s_axi_rdata_r <= bram_dout[2911:2880];
			    13'h46C: s_axi_rdata_r <= bram_dout[2943:2912];
			    13'h470: s_axi_rdata_r <= bram_dout[2975:2944];
			    13'h474: s_axi_rdata_r <= bram_dout[3007:2976];
			    13'h478: s_axi_rdata_r <= bram_dout[3039:3008];
			    13'h47C: s_axi_rdata_r <= bram_dout[3071:3040];
			    13'h480: s_axi_rdata_r <= bram_dout[3103:3072];
			    13'h484: s_axi_rdata_r <= bram_dout[3135:3104];
			    13'h488: s_axi_rdata_r <= bram_dout[3167:3136];
			    13'h48C: s_axi_rdata_r <= bram_dout[3199:3168];
			    13'h490: s_axi_rdata_r <= bram_dout[3231:3200];
			    13'h494: s_axi_rdata_r <= bram_dout[3263:3232];
			    13'h498: s_axi_rdata_r <= bram_dout[3295:3264];
			    13'h49C: s_axi_rdata_r <= bram_dout[3327:3296];
			    13'h4A0: s_axi_rdata_r <= bram_dout[3359:3328];
			    13'h4A4: s_axi_rdata_r <= bram_dout[3391:3360];
			    13'h4A8: s_axi_rdata_r <= bram_dout[3423:3392];
			    13'h4AC: s_axi_rdata_r <= bram_dout[3455:3424];
			    13'h4B0: s_axi_rdata_r <= bram_dout[3487:3456];
			    13'h4B4: s_axi_rdata_r <= bram_dout[3519:3488];
			    13'h4B8: s_axi_rdata_r <= bram_dout[3551:3520];
			    13'h4BC: s_axi_rdata_r <= bram_dout[3583:3552];
			    13'h4C0: s_axi_rdata_r <= bram_dout[3615:3584];
			    13'h4C4: s_axi_rdata_r <= bram_dout[3647:3616];
			    13'h4C8: s_axi_rdata_r <= bram_dout[3679:3648];
			    13'h4CC: s_axi_rdata_r <= bram_dout[3711:3680];
			    13'h4D0: s_axi_rdata_r <= bram_dout[3743:3712];
			    13'h4D4: s_axi_rdata_r <= bram_dout[3775:3744];
			    13'h4D8: s_axi_rdata_r <= bram_dout[3807:3776];
			    13'h4DC: s_axi_rdata_r <= bram_dout[3839:3808];
			    13'h4E0: s_axi_rdata_r <= bram_dout[3871:3840];
			    13'h4E4: s_axi_rdata_r <= bram_dout[3903:3872];
			    13'h4E8: s_axi_rdata_r <= bram_dout[3935:3904];
			    13'h4EC: s_axi_rdata_r <= bram_dout[3967:3936];
			    13'h4F0: s_axi_rdata_r <= bram_dout[3999:3968];
			    13'h4F4: s_axi_rdata_r <= bram_dout[4031:4000];
			    13'h4F8: s_axi_rdata_r <= bram_dout[4063:4032];
			    13'h4FC: s_axi_rdata_r <= bram_dout[4095:4064];
                        
                       	    // DPE output reserved register space
                       	    13'h600: s_axi_rdata_r <= dpe_dout_debug[31:0];
			    13'h604: s_axi_rdata_r <= dpe_dout_debug[63:32];
			    13'h608: s_axi_rdata_r <= dpe_dout_debug[95:64];
			    13'h60C: s_axi_rdata_r <= dpe_dout_debug[127:96];
			    13'h610: s_axi_rdata_r <= dpe_dout_debug[159:128];
			    13'h614: s_axi_rdata_r <= dpe_dout_debug[191:160];
			    13'h618: s_axi_rdata_r <= dpe_dout_debug[223:192];
			    13'h61C: s_axi_rdata_r <= dpe_dout_debug[255:224];
                        
                        
                       
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

// Read FSM States
localparam READ_IDLE      = 3'd0;
localparam READ_SETUP     = 3'd1;
localparam READ_AR        = 3'd2;
localparam READ_DATA      = 3'd3;
localparam READ_DONE      = 3'd4;

// Write FSM States
localparam WRITE_IDLE     = 3'd0;
localparam WRITE_SETUP    = 3'd1;
localparam WRITE_AW       = 3'd2;
localparam WRITE_DATA     = 3'd3;
localparam WRITE_RESP     = 3'd4;
localparam WRITE_DONE     = 3'd5;

// DPE FSM States
localparam DPE_IDLE       = 2'd0;
localparam DPE_ACTIVE     = 2'd1;
localparam DPE_DONE       = 2'd2;

// Main Control FSM States
localparam CTRL_IDLE      = 2'd0;
localparam CTRL_ACTIVE    = 2'd1;
localparam CTRL_COMPLETE  = 2'd2;



// FSM State Registers
reg [2:0] read_state;
reg [2:0] write_state;
reg [1:0] dpe_state;
reg [1:0] ctrl_state;


// Data Transfer Tracking
reg [31:0] read_transfer_count;
reg [31:0] write_transfer_count;
reg read_data_valid;
reg [C_M_AXI_DATA_WIDTH-1:0] read_data_buffer [0:C_M_AXI_BURST_LEN-1];
reg [7:0] read_data_index;
reg [7:0] write_data_index;




// Arbiter logic - prioritize read operations
always @(posedge aclk) begin
    if (!aresetn) begin
        read_grant <= 1'b0;
        write_grant <= 1'b0;
    end
    else begin
        // Default - maintain current grants
        read_grant <= read_grant;
        write_grant <= write_grant;
        
        // Handle new requests and releases
        if (read_request && !read_grant) begin
            // Read has priority - grant immediately if bus available
            if (!write_grant) begin
                read_grant <= 1'b1;
            end
            // If write is active, wait until it completes current transaction
            else if (write_state == WRITE_DONE) begin
                read_grant <= 1'b1;
                write_grant <= 1'b0;
            end
        end
        else if (!read_request && read_grant) begin
            read_grant <= 1'b0;
        end
        
        if (write_request && !write_grant) begin
            // Grant write only if read is not active or requesting
            if (!read_grant && !read_request) begin
                write_grant <= 1'b1;
            end
        end
        else if (!write_request && write_grant) begin
            write_grant <= 1'b0;
        end
    end
end



// Main Control FSM
always @(posedge aclk) begin
    if (!aresetn) begin
        ctrl_state <= CTRL_IDLE;
        dma_busy <= 1'b0;
        dma_status <= 2'b00;  // idle
    end
    else begin
        case (ctrl_state)
            CTRL_IDLE: begin
                if (dma_start && !dma_busy) begin
                    dma_busy <= 1'b1;
                    dma_status <= 2'b01;  // busy
                    
                    if (dma_length > 0) begin
                        ctrl_state <= CTRL_ACTIVE;
                    end
                    else begin
                        // No data to transfer
                        dma_busy <= 1'b0;
                        dma_status <= 2'b10;  // complete
                    end
                end
            end
            
            CTRL_ACTIVE: begin
                // Check if both read and write are complete
                if ((read_transfer_count >= dma_length) && 
                    (write_transfer_count >= dma_length)) begin
                    ctrl_state <= CTRL_COMPLETE;
                end
            end
            
            CTRL_COMPLETE: begin
                dma_busy <= 1'b0;
                dma_status <= 2'b10;  // complete
                ctrl_state <= CTRL_IDLE;
            end
        endcase
    end
end


reg [31:0] burst_count;
// Read FSM
always @(posedge aclk) begin
    if (!aresetn) begin
        read_state <= READ_IDLE;
        read_request <= 1'b0;
        read_transfer_count <= 32'h0;
        read_data_valid <= 1'b0;
        read_data_index <= 8'h0;
        is_final_burst <= 1'b0;
        bytes_in_current_burst <= 32'd0;
        final_byte_count <= 6'd0;
        burst_count <= 32'h0;
        
        // Read channel signals
        m_axi_arvalid_r <= 1'b0;
        m_axi_araddr_r <= {C_M_AXI_ADDR_WIDTH{1'b0}};
        m_axi_arlen_r <= 8'h0;
        m_axi_arsize_r <= 3'b000;
        m_axi_arburst_r <= 2'b01;  // INCR
        m_axi_arprot_r <= 3'b000;
        m_axi_arcache_r <= 4'b0011;
        m_axi_rready_r <= 1'b0;
        rx_data_reg     <= 256'b0;
    end
    else begin
        case (read_state)
            READ_IDLE: begin
                m_axi_arvalid_r <= 1'b0;
                m_axi_rready_r <= 1'b0;
                read_data_valid <= 1'b0;
                burst_count <= 32'h0;
                
                // Start reading if in active state and not finished
                if (ctrl_state == CTRL_ACTIVE && read_transfer_count < dma_length) begin
                    read_state <= READ_SETUP;
                    read_request <= 1'b1;
                end
            end
            
            READ_SETUP: begin
                // Wait for arbiter grant
                if (read_grant) begin
                    // Check if this is the final burst
                    is_final_burst <= ((dma_length - read_transfer_count) <=
                                     (C_M_AXI_BURST_LEN * (C_M_AXI_DATA_WIDTH/8)));
                    
                    // Calculate burst parameters
                    if ((dma_length - read_transfer_count) >=
                       (C_M_AXI_BURST_LEN * (C_M_AXI_DATA_WIDTH/8))) begin
                        m_axi_arlen_r <= C_M_AXI_BURST_LEN - 1;
                        bytes_in_current_burst <= (C_M_AXI_BURST_LEN * (C_M_AXI_DATA_WIDTH/8));
                        final_byte_count <= 6'd31;
                    end
                    else begin
                        // Calculate beats needed for remaining data
                        if ((dma_length - read_transfer_count) % (C_M_AXI_DATA_WIDTH/8) == 0) begin
                            beats_reg = (dma_length - read_transfer_count) / (C_M_AXI_DATA_WIDTH/8);
                        end
                        else begin
                            beats_reg = ((dma_length - read_transfer_count) / (C_M_AXI_DATA_WIDTH/8)) + 1;
                        end
                        
                        // Ensure at least one beat
                        if (beats_reg == 0)
                            beats_reg = 1;
                            
                        m_axi_arlen_r <= beats_reg[7:0] - 1;
                        bytes_in_current_burst <= dma_length - read_transfer_count;
                        
                        // Calculate final byte count
                        final_byte_count <= ((dma_length - read_transfer_count) % (C_M_AXI_DATA_WIDTH/8) == 0) ?
                                          6'd31 : ((dma_length - read_transfer_count) % (C_M_AXI_DATA_WIDTH/8) - 1);
                    end
                    
                    // Setup read address
                    m_axi_araddr_r <= dma_source_addr + read_transfer_count;
                    m_axi_arsize_r <= 3'b101;  // 32 bytes (256 bits)
                    m_axi_arvalid_r <= 1'b1;
                    m_axi_rready_r <= 1'b1;
                    read_data_index <= 8'h0;
                    read_state <= READ_AR;
                end
            end
            
            READ_AR: begin
                if (m_axi_arready && m_axi_arvalid_r) begin
                    m_axi_arvalid_r <= 1'b0;
                    read_state <= READ_DATA;
                end
            end
            
            READ_DATA: begin
                if (m_axi_rvalid && m_axi_rready_r) begin
                    // Store the read data in buffer
                    read_data_buffer[read_data_index] <= m_axi_rdata;
                    rx_data_reg <= m_axi_rdata;
                    read_data_index <= read_data_index + 1;
                    
                    // Signal data is valid for processing
                    read_data_valid <= 1'b1;
                    
                    // If it's the last beat in this burst
                    if (m_axi_rlast) begin
                        // Update transfer count
                        read_transfer_count <= read_transfer_count + bytes_in_current_burst;
                        burst_count <= burst_count + 1;
                        
                        // Check if we've completed all transfers
                        if (read_transfer_count + bytes_in_current_burst >= dma_length) begin
                            // All data has been read, go to DONE state
                            m_axi_rready_r <= 1'b0;
                            read_state <= READ_DONE;
                        end
                        else begin
                            // More data to read, prepare for next burst without going to IDLE
                            read_state <= READ_SETUP;
                        end
                    end
                end else begin
                    // Clear data valid flag when no new data
                    read_data_valid <= 1'b0;
                end
            end
            
            READ_DONE: begin
                // Release bus access
                read_request <= 1'b0;
                
                // Wait for control to transition back to IDLE
                if (ctrl_state == CTRL_IDLE) begin
                    read_state <= READ_IDLE;
                end
            end
        endcase
    end
end
reg [255:0]dpe_acc;
reg [255:0] dpe_accumulator;
reg [2:0] dpe_count;
// DPE (Dot Product Engine) FSM
always @(posedge aclk) begin
    if (!aresetn) begin
        dpe_state <= DPE_IDLE;
        dpe_en <= 1'b0;
        dpe_start <= 1'b0;
        dpe_dout_debug <= 'h0;
        dpe_acc <= 256'd0;
        write_valid <= 1'd0;
        dpe_count <= 3'd0;
        dpe_accumulator <= 256'd0;
    end
    else begin
        case (dpe_state)
            DPE_IDLE: begin
                dpe_start <= 1'b0;
                
                // Start DPE when new read data is available
                if (read_data_valid) begin
                    dpe_en    <= 1'b1;
                    dpe_start <= 1'b1;
                    write_valid<=1'd0;
          	    dpe_count<=3'd0;
                    dpe_state <= DPE_ACTIVE;
                end
            end
            
            DPE_ACTIVE: begin
                dpe_start <= 1'b0;   // Clear start signal after one cycle
                
                // Wait for DPE to complete
                if (dpe_done) begin
                          dpe_accumulator <= {dpe_accumulator[223:0], dpe_y_out};
                          dpe_count <= dpe_count + 1;
                          write_valid<=1'b0;
                      if (dpe_count == 3'd7) begin
                          dpe_count <= 3'd0;
                          dpe_acc <= {dpe_accumulator[223:0], dpe_y_out};  // accumulate + write
                          write_valid <= 1'b1;
                          dpe_accumulator <= 256'd0;
                        end
                    dpe_en <= 1'b0;
                    //dpe_dout_debug <= {224'b0, dpe_y_out};
                    dpe_state <= DPE_DONE;
                end
            end
            
            DPE_DONE: begin
                // Signal that processed data is ready for writing
                if (write_valid) begin
                   dpe_dout_debug <= dpe_acc;
                end
                dpe_state <= DPE_IDLE;
            end
        endcase
    end
end
reg [31:0] bytes_in_write_burst;
reg [31:0] write_beats;
// Write FSM
always @(posedge aclk) begin
    if (!aresetn) begin
        write_state <= WRITE_IDLE;
        write_request <= 1'b0;
        write_transfer_count <= 32'h0;
        write_data_index <= 8'h0;
        
        // Write channel signals
        m_axi_awvalid_r <= 1'b0;
        m_axi_awaddr_r <= {C_M_AXI_ADDR_WIDTH{1'b0}};
        m_axi_awlen_r <= 8'h0;
        m_axi_awsize_r <= 3'b000;
        m_axi_awburst_r <= 2'b01;  // INCR
        m_axi_awprot_r <= 3'b000;
        m_axi_awcache_r <= 4'b0011;
        m_axi_wvalid_r <= 1'b0;
        m_axi_wdata_r <= {C_M_AXI_DATA_WIDTH{1'b0}};
        m_axi_wstrb_r <= {(C_M_AXI_DATA_WIDTH/8){1'b1}};
        m_axi_wlast_r <= 1'b0;
        m_axi_bready_r <= 1'b0;
        
        bytes_in_write_burst <= 32'b0;
        write_beats <= 32'b0;
    end
    else begin
        case (write_state)
            WRITE_IDLE: begin
                m_axi_awvalid_r <= 1'b0;
                m_axi_wvalid_r <= 1'b0;
                m_axi_bready_r <= 1'b0;
                m_axi_wlast_r <= 1'b0;
                
                // Start writing if DPE is done and we have data to write
                if (dpe_state == DPE_DONE && write_transfer_count < read_transfer_count) begin
                    write_state <= WRITE_SETUP;
                    write_request <= 1'b1;
                    write_data_index <= 8'h0;
                end
            end
            
            WRITE_SETUP: begin
                // Wait for arbiter grant
                if (write_grant) begin
                    // Set up write address
                    m_axi_awvalid_r <= 1'b1;
                    m_axi_awaddr_r <= dma_target_addr + write_transfer_count;
                    
                    // Use same burst parameters as the corresponding read operation
                    if ((read_transfer_count - write_transfer_count) >= 
                       (C_M_AXI_BURST_LEN * (C_M_AXI_DATA_WIDTH/8))) begin
                        m_axi_awlen_r <= C_M_AXI_BURST_LEN - 1;
                        bytes_in_write_burst <= (C_M_AXI_BURST_LEN * (C_M_AXI_DATA_WIDTH/8));
                    end
                    else begin
                        // Calculate beats needed
                        if ((read_transfer_count - write_transfer_count) % (C_M_AXI_DATA_WIDTH/8) == 0) begin
                            write_beats = (read_transfer_count - write_transfer_count) / (C_M_AXI_DATA_WIDTH/8);
                        end
                        else begin
                            write_beats = ((read_transfer_count - write_transfer_count) / (C_M_AXI_DATA_WIDTH/8)) + 1;
                        end
                        
                        m_axi_awlen_r <= write_beats[7:0] - 1;
                        bytes_in_write_burst <= read_transfer_count - write_transfer_count;
                    
                    end
                    m_axi_awsize_r <= 3'b101;  // 32 bytes (256 bits)
                    write_state <= WRITE_AW;
                end
            end
            
            WRITE_AW: begin
                if (m_axi_awready && m_axi_awvalid_r) begin
                    m_axi_awvalid_r <= 1'b0;
                    write_state <= WRITE_DATA;
                    
                    // Prepare first data beat
                    m_axi_wdata_r <= read_data_buffer[write_data_index];
                    m_axi_wvalid_r <= 1'b1;
                    
                    // Set wlast for single beat or last beat of burst
                    m_axi_wlast_r <= (m_axi_awlen_r == 0) ? 1'b1 : 1'b0;
                    
                    // Set write strobes
                    if (is_final_burst && write_data_index == m_axi_awlen_r) begin
                        for (i = 0; i < (C_M_AXI_DATA_WIDTH/8); i = i + 1) begin
                            m_axi_wstrb_r[i] <= (i <= final_byte_count) ? 1'b1 : 1'b0;
                        end
                    end
                    else begin
                        m_axi_wstrb_r <= {(C_M_AXI_DATA_WIDTH/8){1'b1}};
                    end
                end
            end
            
            WRITE_DATA: begin
                if (m_axi_wready && m_axi_wvalid_r) begin
                    write_data_index <= write_data_index + 1;
                    
                    // Check if this was the last beat
                    if (m_axi_wlast_r) begin
                        m_axi_wvalid_r <= 1'b0;
                        m_axi_wlast_r <= 1'b0;
                        m_axi_bready_r <= 1'b1;
                        write_state <= WRITE_RESP;
                    end
                    else begin
                        // Prepare next data beat
                        m_axi_wdata_r <= read_data_buffer[write_data_index + 1];
                        
                        // Set wlast for last beat of burst
                        m_axi_wlast_r <= (write_data_index + 1 == m_axi_awlen_r) ? 1'b1 : 1'b0;
                        
                        // Set write strobes for last beat if needed
                        if (is_final_burst && (write_data_index + 1) == m_axi_awlen_r) begin
                            for (i = 0; i < (C_M_AXI_DATA_WIDTH/8); i = i + 1) begin
                                m_axi_wstrb_r[i] <= (i <= final_byte_count) ? 1'b1 : 1'b0;
                            end
                        end
                    end
                end
            end
            
            WRITE_RESP: begin
                if (m_axi_bvalid && m_axi_bready_r) begin
                    m_axi_bready_r <= 1'b0;
                    write_state <= WRITE_DONE;
                end
            end
            
            WRITE_DONE: begin
                // Update transfer count
                write_transfer_count <= write_transfer_count + bytes_in_write_burst;
                
                // Release bus access
                write_request <= 1'b0;
                
                // Go back to idle to prepare for next burst
                write_state <= WRITE_IDLE;
            end
        endcase
    end
end





endmodule
