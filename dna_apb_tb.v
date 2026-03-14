`timescale  1 ps / 1 ps
module test;

reg PCLK = 0;
always #5000 PCLK <= ~PCLK;

reg PRESETn = 1;

reg PSEL = 0;
reg PENABLE;
reg [31:0] PADDR;
wire PREADY;
wire [31:0] PRDATA;

dna_apb #(
    .SIM_DNA_VALUE(57'h24ec844c05e854)
) dut0 (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PSEL(PSEL),
    .PADDR(PADDR),
    .PENABLE(PENABLE),
    .PWRITE(1'b0),
    .PREADY(PREADY),
    .PRDATA(PRDATA),
    .PWDATA(32'hxxxxxxxx),
    .PSLVERR()
);

initial begin
    #10000000
    $display("Timeout!");
    $stop;
end

initial begin
    $dumpfile(`VCD);
    $dumpvars(0,test);

    #10
    @(posedge PCLK)
    apb_read(0, 32'h0024ec84);
    apb_read(0, 32'h0024ec84);
    apb_read(4, 32'h4c05e854);
    apb_read(8, 32'hdeadbeef);

    #10
    $finish();
end

task apb_read([31:0] addr, expected);
begin
    $display("apb_read %x, expecting %x", addr, expected);
    @(posedge PCLK)
    PSEL <= 1;
    PADDR <= addr;
    PENABLE <= 0;
    @(posedge PCLK)
    PENABLE <= 1;
    while(~PREADY) begin
        @(posedge PCLK);
    end
    PSEL <= 0;
    PADDR <= 32'hxxxxxxxx;
    PENABLE <= 1'bx;
    $display("apb_read %x, expected %x, read %x", addr, expected, PRDATA);
    if(PRDATA!==expected) begin
        $display("Mis-match!");
        $stop;
    end
end
endtask

endmodule
