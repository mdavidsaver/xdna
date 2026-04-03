`timescale  1 ns / 1 ns

module test;

reg PCLK = 0;
always #5 PCLK <= ~PCLK;

reg PRESETn = 1;

wire [56:0] ID;
wire ready;

dna_reader #(
    .SIM_DNA_VALUE(57'h24ec844c05e854)
) dna (
    .clk(PCLK),
    .rst_n(PRESETn),
    .DNA(ID),
    .DNA_READY(ready)
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

    @(posedge PCLK);
    PRESETn <= 0;
    @(posedge PCLK);
    PRESETn <= 1;

    while(~ready)
        @(posedge PCLK);

    $display("div %x", ID);
    if(ID!==57'h24ec844c05e854)
        $stop;

`ifdef __ICARUS__
    @(posedge PCLK);
    $finish();
`endif
end

endmodule
