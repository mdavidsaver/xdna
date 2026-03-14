`timescale  1 ns / 1 ps
module dna_axi #(
    parameter [56:0] SIM_DNA_VALUE = 57'h0,
    parameter PCLK_DIV = 1
) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ACLK CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET ARESETn, ASSOCIATED_BUSIF S_AXI" *)
    input ACLK,

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ARESETn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input ARESETn,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    (* X_INTERFACE_PARAMETER = "PROTOCOL AXI4LITE, READ_WRITE_MODE READ_ONLY" *)
    input [31:0] ARADDR, // Read address (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
    input [2:0] ARPROT, // Protection type (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
    input ARVALID, // Read address valid (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
    output reg ARREADY = 0, // Read address ready (optional)

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
    output reg [31:0] RDATA = 0, // Read data (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
    output reg [1:0] RRESP = 0, // Read response (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
    output reg RVALID = 0, // Read valid (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
    input RREADY // Read ready (optional)
);

wire [56:0] DNA;
wire DNA_READY;

reg [7:0] addr;
reg addrd = 0;

always @(posedge ACLK) begin
    ARREADY <= 0;
    RDATA <= 32'hffffffff;
    RVALID <= 0;
    RRESP <= 0;

    if(ARVALID) begin
        addr <= ARADDR[7:0];
        addrd <= 1;
        ARREADY <= 1;
    end

    if(RREADY & addrd & DNA_READY) begin
        RVALID <= 1;
        addrd <= 0;
        case (addr & 32'h000000fc)
        0: RDATA <= {7'h00, DNA[56:32]};
        4: RDATA <= DNA[31:0];
        8: RDATA <= 32'hdeadbeef;
        default: RRESP <= 2'b10;
        endcase
    end

    if(~ARESETn) begin
        addr <= 0;
        addrd <= 0;
    end
end

dna_reader #(
    .SIM_DNA_VALUE(SIM_DNA_VALUE),
    .PCLK_DIV(PCLK_DIV)
) dna (
    .clk(ACLK),
    .rst_n(ARESETn),
    .DNA(DNA),
    .DNA_READY(DNA_READY)
);

endmodule
