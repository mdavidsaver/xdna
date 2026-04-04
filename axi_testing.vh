
/* Refering to "AMBA® AXI™ and ACE™ Protocol Specification"
 * revision E, 22 Feb. 2013
 *
 * Principly A3.3.1 "Dependencies between channel handshake signals"
 * sub-sections "Read transaction dependencies"
 * and "Write transaction dependencies"
 */

/* AXI master protocol variant
 *
 * 0 - Master waits for slave.
 *     "the master can wait for RVALID to be asserted before it asserts RREADY"
 *     "the master can wait for BVALID before asserting BREADY"
 * 1 - Master leads
 *     "the master can assert RREADY before RVALID is asserted."
 *     "the master can assert BREADY before BVALID is asserted."
 */
reg axi_proto = 0;

initial begin
    if($value$plusargs("axiproto=%d", axi_proto)) begin end
    $display("# Using AXI master protocol variant %d", axi_proto);
    if(axi_proto<0 || axi_proto>1) begin
        $display("$  Invalid variant");
        $stop;
    end
end

reg [31:0] ractual;
reg rdone = 1;
always @(posedge ACLK) begin
    if(ARVALID && ARREADY && RVALID) begin
        // "the slave must wait for both ARVALID and ARREADY to be asserted before
        // it asserts RVALID to indicate that valid data is available"
        $display("  axi_read premature RVALID");
        $stop;
    end
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

task axi_read_mask;
    input [31:0] addr;
    input [31:0] mask;
    input [31:0] expected;
begin
    $display("axi_reading 0x%x, mask 0x%x, expecting 0x%x", addr, mask, expected);

    ractual <= 32'hxxxxxxxx;

    @(negedge ACLK);

    ARADDR <= addr;
    // "the master must not wait for the slave to assert ARREADY before asserting ARVALID"
    ARVALID <= 1;

    case(axi_proto)
    0: rdone <= 0;
    1: RREADY <= 1;
    endcase

    @(posedge ACLK);
    while(ARVALID || ~(rdone && ~RREADY))
        @(posedge ACLK);

    $display("  axi_read 0x%x, mask 0x%x, expected 0x%x, found 0x%x",
        addr, mask, expected, ractual);
    if((ractual&mask)!==(expected&mask)) begin
        $display("  Mis-match! 0x%x !== 0x%x", ractual&mask, expected&mask);
        $stop;
    end else begin
        $display("  Ok");
    end
end
endtask

task axi_read;
    input [31:0] addr;
    input [31:0] expected;
begin
    axi_read_mask(addr, 32'hffffffff, expected);
end
endtask

reg [1:0] wactual;
reg wdone = 1;
always @(posedge ACLK) begin
    if(AWVALID && AWREADY && BVALID) begin
        // "the slave must wait for both WVALID and WREADY to be asserted before asserting BVALID"
        $display("  axi_write premature BVALID");
        $stop;
    end
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

    // " the master must not wait for the slave to assert AWREADY or WREADY before asserting
    //   AWVALID or WVALID"
    AWADDR <= addr;
    AWVALID <= 1;

    WDATA <= wdata;
    WVALID <= 1;

    case(axi_proto)
    0:wdone <= 0;
    1:BREADY <= 1;
    endcase

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
