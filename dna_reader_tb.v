`timescale  1 ps / 1 ps

module test;

reg PCLK = 0;
always #5000 PCLK <= ~PCLK;

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

initial begin
    #10000000
    $display("Timeout!");
    $stop;
end

initial begin
    $dumpfile(`VCD);
    $dumpvars(0,test);

    #10
    PRESETn <= 0;
    #10
    PRESETn <= 1;

    while(~ready)
        @(posedge PCLK);

    $display("div %x", ID);
    if(ID!==57'h24ec844c05e854)
        $stop;

    #100
    $finish();
end

endmodule
