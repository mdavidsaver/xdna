`timescale  1 ps / 1 ps
module test;

reg PCLK = 0;
always #5000 PCLK <= ~PCLK;

reg PRESETn = 1;

reg [31:0] ARADDR;
reg ARVALID = 0;
wire ARREADY;

wire [31:0] RDATA;
wire [1:0] RRESP;
wire RVALID;
reg RREADY = 0;

wire [56:0] DNA;
wire DNA_READY;

dna_axi axi (
    .ACLK(PCLK),
    .ARESETn(PRESETn),
    .ARADDR(ARADDR),
    .ARPROT(3'b010), // data, non-secure, unpriv.
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),
    .RDATA(RDATA),
    .RRESP(RRESP),
    .RVALID(RVALID),
    .RREADY(RREADY),
    .DNA(DNA),
    .DNA_READY(DNA_READY)
);

dna_reader #(
    .SIM_DNA_VALUE(57'h24ec844c05e854)
) dna (
    .clk(PCLK),
    .rst_n(PRESETn),
    .DNA(DNA),
    .DNA_READY(DNA_READY)
);


initial begin
    #10000000
    $display("Timeout!");
    $stop;
end

initial begin
    $dumpfile(`VCD);
    $dumpvars(0,test);

    $display("Reset");
    @(posedge PCLK);
    PRESETn <= 0;
    @(posedge PCLK);
    PRESETn <= 1;

    axi_read(0, 0, 32'h0024ec84);
    axi_read(0, 0, 32'h0024ec84);
    axi_read(0, 4, 32'h4c05e854);
    axi_read(0, 8, 32'hdeadbeef);

    $display("Reset");
    @(posedge PCLK);
    PRESETn <= 0;
    @(posedge PCLK);
    PRESETn <= 1;

    axi_read(1, 0, 32'h0024ec84);
    axi_read(1, 0, 32'h0024ec84);
    axi_read(1, 4, 32'h4c05e854);
    axi_read(1, 8, 32'hdeadbeef);

    $display("Reset");
    @(posedge PCLK);
    PRESETn <= 0;
    @(posedge PCLK);
    PRESETn <= 1;

    axi_read(2, 0, 32'h0024ec84);
    axi_read(2, 0, 32'h0024ec84);
    axi_read(2, 4, 32'h4c05e854);
    axi_read(2, 8, 32'hdeadbeef);

    #10
    $finish();
end

/* AXI4LITE read transaction(s)
 *
 * channel ordering variants:
 * 0 - Start both AR and R channel on the same tick
 * 1 - Complete AR before R
 * 2 - Start R before AR
 */
task axi_read(integer variant, [31:0] addr, expected);
    reg [31:0] actual;
begin
    $display("axi_read %x, expecting %x", addr, expected);

    if(variant==0) begin

        ARADDR <= addr;
        ARVALID <= 1;
        RREADY <= 1;

        while(~ARREADY)
            @(posedge PCLK);

    end else if(variant==1) begin

        ARADDR <= addr;
        ARVALID <= 1;

        while(~ARREADY)
            @(posedge PCLK);

        RREADY <= 1;

    end else if(variant==2) begin
        RREADY <= 1;
        @(posedge PCLK);
        @(posedge PCLK);

        ARADDR <= addr;
        ARVALID <= 1;

        while(~ARREADY)
            @(posedge PCLK);
    end

    ARADDR <= 32'hxxxxxxxx;
    ARVALID <= 0;

    while(~RVALID) begin
        @(posedge PCLK);
        actual <= RDATA;
    end
    RREADY <= 0;

    while(RVALID)
        @(posedge PCLK);

    $display("axi_read %x, expected %x, read %x", addr, expected, actual);
    if(actual!==expected) begin
        $display("Mis-match!");
        $stop;
    end
end
endtask

endmodule
