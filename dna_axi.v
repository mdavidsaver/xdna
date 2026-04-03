`timescale  1 ns / 1 ns
module dna_axi #(
    parameter [56:0] SIM_DNA_VALUE = 57'h0
) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ACLK CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET ARESETn, ASSOCIATED_BUSIF S_AXI" *)
    input ACLK,

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ARESETn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input ARESETn,

    // read address channel
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    (* X_INTERFACE_PARAMETER = "PROTOCOL AXI4LITE" *)
    input [11:0] ARADDR, // Read address (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
    input [2:0] ARPROT, // Protection type (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
    input ARVALID, // Read address valid (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
    output reg ARREADY = 0, // Read address ready (optional)

    // read data channel
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
    output reg [31:0] RDATA = 0, // Read data (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
    output reg [1:0] RRESP = 0, // Read response (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
    output reg RVALID = 0, // Read valid (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
    input RREADY, // Read ready (optional)

    // write address channel
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    input [11:0] AWADDR, // Write address (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
    input AWVALID, // Write address valid (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
    output AWREADY, // Write address ready (optional)

    // write data channel
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input [31:0] WDATA, // Write data (optional)
    //(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
    //input [31:0] WSTRB, // Write strobes (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
    input WVALID, // Write valid (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
    output reg WREADY = 0, // Write ready (optional)

    // write response channel
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
    output reg [1:0] BRESP = 2'b10, // Write response (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
    output reg BVALID = 0, // Write response valid (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
    input BREADY // Write response ready (optional)
);

wire [56:0] DNA;
wire DNA_READY;

reg [31:0] mbox = 32'hdeadbeef;

// read address/data channels

always @(posedge ACLK) begin
    if(~ARESETn) begin
        ARREADY <= 0;
        RVALID <= 0;
    end else if(ARVALID && DNA_READY) begin
        ARREADY <= 1;
        RVALID <= 1;
    end else if(RREADY) begin
        ARREADY <= 0;
        RVALID <= 0;
    end
end

always @(posedge ACLK) begin
    RRESP <= 2'b10;
    if(~ARESETn) begin
        RDATA <= 0;

    end else if(ARVALID && ARREADY && DNA_READY) begin
        RRESP <= 0;
        case (ARADDR)
        0: RDATA <= {7'h00, DNA[56:32]};
        4: RDATA <= DNA[31:0];
        8: RDATA <= mbox;
        default: RRESP <= 2'b10;
        endcase
    end
end

// write address/data/response channels

reg lvalid = 2'b10;
assign AWREADY = WREADY;

always @(posedge ACLK) begin
    if(~ARESETn) begin
        WREADY <= 0;
    end else begin
        WREADY <= ~WREADY && AWVALID && WVALID && (!BVALID || BREADY);
    end

    if(~ARESETn) begin
        BVALID <= 0;
        BRESP <= 2'b10;
    end else if(WVALID && WREADY) begin
        BVALID <= 1;
        BRESP <= lvalid;
    end else if(BVALID && BREADY) begin
        BVALID <= 0;
        BRESP <= 2'b10;
    end
end

always @(posedge ACLK) begin
    lvalid <= 2'b10;

    if(~ARESETn) begin
        mbox <= 32'hdeadbeef;

    end else if(AWVALID && WVALID && WREADY) begin
        lvalid <= 0;
        case (AWADDR)
        8: mbox <= WDATA;
        default: lvalid <= 2'b10;
        endcase
    end
end

dna_reader #(
    .SIM_DNA_VALUE(SIM_DNA_VALUE)
) dna (
    .clk(ACLK),
    .rst_n(ARESETn),
    .DNA(DNA),
    .DNA_READY(DNA_READY)
);

endmodule
