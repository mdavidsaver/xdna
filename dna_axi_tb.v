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

    axi_write(8, 32'h1badface);
    axi_read(8, 32'h1badface);

`ifdef __ICARUS__
    #10
    $finish();
`endif
end

/* Refering to "AMBA® AXI™ and ACE™ Protocol Specification"
 * revision E, 22 Feb. 2013
 *
 * Principly A3.3.1 "Dependencies between channel handshake signals"
 * sub-sections "Read transaction dependencies"
 * and "Write transaction dependencies"
 */

reg [31:0] ractual;
reg rdone = 1;
always @(posedge ACLK) begin
    if(ARVALID && ARREADY) begin
        ARVALID <= 0;
        ARADDR <= 32'hxxxxxxxx;
    end
    // "the master can wait for RVALID to be asserted before it asserts RREADY"
    if(~rdone && RVALID) begin
        RREADY <= 1;
        rdone <= 1;
    end else if(RVALID && RREADY) begin
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

    @(negedge ACLK);
    if(RVALID) begin
        // "the slave must wait for both ARVALID and ARREADY to be asserted before
        // it asserts RVALID to indicate that valid data is available"
        $display("  axi_read premature RVALID");
        $stop;
    end

    ARADDR <= addr;
    // "the master must not wait for the slave to assert ARREADY before asserting ARVALID"
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

reg [1:0] wactual;
reg wdone = 1;
always @(posedge ACLK) begin
    if(AWVALID && AWREADY) begin
        AWVALID <= 0;
        AWADDR <= 32'hxxxxxxxx;
    end
    if(WVALID && WREADY) begin
        WVALID <= 0;
        WDATA <= 32'hxxxxxxxx;
    end
    // "the master can wait for BVALID before asserting BREADY"
    if(~wdone && BVALID) begin
        BREADY <= 1;
        wdone <= 1;
    end else if(BVALID && BREADY) begin
        BREADY <= 0;
        wactual <= BRESP;
    end
end

// AXI4LITE write transaction
task axi_write;
    input [31:0] addr, wdata;
begin
    $display("axi_writing 0x%x, value 0x%x", addr, wdata);
    AWADDR <= 32'hxxxxxxxx;
    WDATA <= 32'hxxxxxxxx;

    @(negedge ACLK);
    if(BVALID) begin
        // "the slave must wait for both WVALID and WREADY to be asserted before asserting BVALID"
        $display("  axi_write premature BVALID");
        $stop;
    end

    // " the master must not wait for the slave to assert AWREADY or WREADY before asserting
    //   AWVALID or WVALID"
    AWADDR <= addr;
    AWVALID <= 1;

    WDATA <= wdata;
    WVALID <= 1;

    wdone <= 0;

    @(posedge ACLK);
    while(AWVALID || WVALID || BREADY) // wait for idle
        @(posedge ACLK);

    if(wactual!=0) begin
        $display("  Error! %x", wactual);
        $stop;
    end else begin
        $display("  Ok");
    end

end
endtask

endmodule
