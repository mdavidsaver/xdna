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
    .RREADY(RREADY)
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
    $dumpfile(`VCD);
    $dumpvars(0,test);
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

`ifdef __ICARUS__
    #10
    $finish();
`endif
end

reg [31:0] ractual;
reg rdone = 1;
always @(posedge ACLK) begin
    if(ARVALID && ARREADY) begin
        ARVALID <= 0;
        ARADDR <= 32'hxxxxxxxx;
    end
    if(~rdone && RVALID) begin // wait for valid
        RREADY <= 1;
        rdone <= 1;
    end else if(RVALID && RREADY) begin // complete
        RREADY <= 0;
        ractual <= RDATA;
    end
end

// AXI4LITE read transaction
task axi_read;
    input [31:0] addr;
    input [31:0] expected;
begin
    $display("axi_reading 0x%x, expecting 0x%x", addr, expected);
    ractual <= 32'hxxxxxxxx;

    // cf. AXI4 spec.  A3.3 "Read transaction dependencies"

    @(negedge ACLK);
    if(RVALID) begin
        // "the slave must wait for both ARVALID and ARREADY to be asserted before
        // it asserts RVALID to indicate that valid data is available"
        $display("  axi_read premature RVALID");
        $stop;
    end

    ARADDR <= addr;
    ARVALID <= 1;
    rdone <= 0;

    @(posedge ACLK);
    while(ARVALID || ~(rdone && ~RREADY))
        @(posedge ACLK);

    $display("  axi_read 0x%x, expected 0x%x, found 0x%x", addr, expected, ractual);
    if(ractual!==expected) begin
        $display("  Mis-match!");
        $stop;
    end else begin
        $display("  Ok");
    end
end
endtask


endmodule
