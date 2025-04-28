`timescale  1 ps / 1 ps

module test;

reg PCLK = 0;
always #5000 PCLK <= ~PCLK;

reg PRESETn = 1;

wire [56:0] ID [2:0];
wire [2:0] ready;

genvar i;
generate
for(i = 0; i<3; i++)
    dna_reader #(
        .SIM_DNA_VALUE(57'h24ec844c05e854),
        .PCLK_DIV(1<<i) // 1, 2, 4
    ) dna (
        .clk(PCLK),
        .rst_n(PRESETn),
        .DNA(ID[i]),
        .DNA_READY(ready[i])
    );
endgenerate

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

    while(ready!==3'b111)
        @(posedge PCLK);

    $display("div 1 %x", ID[0]);
    $display("div 2 %x", ID[1]);
    $display("div 4 %x", ID[2]);
    if(ID[0]!==57'h24ec844c05e854)
        $stop;
    if(ID[1]!==57'h24ec844c05e854)
        $stop;
    if(ID[2]!==57'h24ec844c05e854)
        $stop;

    #100
    $finish();
end

endmodule
