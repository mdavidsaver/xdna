`timescale  1 ps / 1 ps

module dna_tb();

reg clk = 0;
always #5000 clk <= ~clk;

reg RESETn = 0;

DNA_READ dna (
    .CLK(clk),
    .RESETn(RESETn)
);

initial begin
    $dumpfile(`VCD);
    $dumpvars(0,dna_tb);

    #10
    RESETn <= 1;
    while(~dna.READY) begin
        @(posedge clk)
        begin end
    end
    $display("ID %x", dna.ID);
    if(dna.ID!=57'h123456789abcdef)
        $stop;

    @(posedge clk)
    @(posedge clk)

    RESETn <= 0;
    while(dna.READY) begin
        @(posedge clk)
        begin end
    end

    RESETn <= 1;
    while(~dna.READY) begin
        @(posedge clk)
        begin end
    end
    $display("ID %x", dna.ID);
    if(dna.ID!=57'h123456789abcdef)
        $stop;

    $finish();
end

endmodule

module DNA_READ(
    input CLK,
    input RESETn,
    output reg [NBIT-1:0] ID = 0,
    output READY
);

localparam NBIT = 57;
localparam NSTATE = NBIT + 3;

reg [$clog2(NSTATE)-1:0] state = 0;
assign READY = state == NSTATE-1;

reg shift=0, read=0;
wire dout;

always @(posedge CLK)
begin
    shift <= 0;
    read <= 0;

    if(~RESETn) begin
        ID <= 0;
        state <= 0;

    end else if(~READY) begin
        state <= state + 1;

        if(state==0) begin
            read <= 1;

        end else begin
            shift <= 1;
            ID <= {ID[NBIT-2:0], dout};
        end
    end
end

DNA_PORT #(
    .SIM_DNA_VALUE(57'h123456789abcdef)
) dna_i (
    .CLK(CLK),
    .READ(read),
    .SHIFT(shift),
    .DOUT(dout),
`ifdef SIM
    .DIN(1'bx)
`else
    .DIN(1'b0)
`endif
);

endmodule
