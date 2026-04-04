`timescale  1 ns / 1 ns
module test;

reg ACLK = 0;
always #5 ACLK <= ~ACLK;

reg ARESETn = 1;

reg [11:0] ARADDR;
reg ARVALID = 0;
wire ARREADY;

wire [31:0] RDATA;
wire [1:0] RRESP;
wire RVALID;
reg RREADY = 0;

reg [11:0] AWADDR;
reg AWVALID = 0;
wire AWREADY;

reg [31:0] WDATA;
reg WVALID = 0;
wire WREADY;

wire [1:0] BRESP;
wire BVALID;
reg BREADY = 0;

wire [56:0] DNA;
wire DNA_READY;

dna_axi #(
    .SIM_DNA_VALUE(57'h24ec844c05e854)
) axi (
    .ACLK(ACLK),
    .ARESETn(ARESETn),

    .ARADDR(ARADDR),
    .ARPROT(3'b010), // data, non-secure, unpriv.
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),

    .RDATA(RDATA),
    .RRESP(RRESP),
    .RVALID(RVALID),
    .RREADY(RREADY),

    .AWADDR(AWADDR),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),

    .WDATA(WDATA),
    .WVALID(WVALID),
    .WREADY(WREADY),

    .BRESP(BRESP),
    .BVALID(BVALID),
    .BREADY(BREADY)
);

`ifdef __ICARUS__
initial begin
    #10000
    $display("Timeout!");
    $stop;
end
`endif



initial begin
`ifdef __ICARUS__
    string vcd;
    if($value$plusargs("vcd=%s", vcd)) begin
        $display("Dump to %s", vcd);
        $dumpfile(vcd);
        $dumpvars(0,test);
    end
`endif

    $display("Reset");
    @(posedge ACLK);
    ARESETn <= 0;
    @(posedge ACLK);
    ARESETn <= 1;

    axi_read(0, 32'h0024ec84);
    axi_read(0, 32'h0024ec84);
    axi_read(4, 32'h4c05e854);
    axi_read(8, 32'hdeadbeef);

    axi_write(8, 32'h1badface);
    axi_read(8, 32'h1badface);

`ifdef __ICARUS__
    #10
    $finish();
`endif
end

`include "axi_testing.vh"

endmodule
