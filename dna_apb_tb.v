`timescale  1 ps / 1 ps

module dna_apb_tb();


reg PCLK = 0;
always #5000 PCLK <= ~PCLK;

reg PRESETn = 1;

// simulate bus with 3 devices
localparam N = 3;

reg [N-1:0] PSEL = 0;
reg PENABLE;
reg [31:0] PADDR;
wire PREADYx [N];
wire [31:0] PRDATAx [N];

genvar i;
generate
for(i = 0; i<N; i++)
    dna_apb #(
        .SIM_DNA_VALUE(57'h123456789abcdef),
        .PCLK_DIV(1<<i) // 1, 2, 4
    ) dut0(
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL[i]),
        .PADDR(PADDR),
        .PENABLE(PENABLE),
        .PWRITE(1'b0),
        .PREADY(PREADYx[i]),
        .PRDATA(PRDATAx[i]),
        .PWDATA(32'hxxxxxxxx),
        .PSLVERR()
    );
endgenerate

wire PREADY = PSEL&1 ? PREADYx[0]
            : PSEL&2 ? PREADYx[1]
            : PSEL&4 ? PREADYx[2]
            : 1'bx;
wire [31:0] PRDATA = PSEL&1 ? PRDATAx[0]
                    : PSEL&2 ? PRDATAx[1]
                    : PSEL&4 ? PRDATAx[2]
                    : 32'bxxxxxxxx;

initial begin
    #10000000
    $display("Timeout!");
    $stop;
end

initial begin
    $dumpfile(`VCD);
    $dumpvars(0,dna_apb_tb);

    #10
    @(posedge PCLK)
    apb_read(0, 0, 32'h01234567);
    apb_read(0, 0, 32'h01234567);
    apb_read(0, 1, 32'h89abcdef);

    apb_read(1, 0, 32'h01234567);
    apb_read(1, 0, 32'h01234567);
    apb_read(1, 1, 32'h89abcdef);

    apb_read(2, 0, 32'h01234567);
    apb_read(2, 0, 32'h01234567);
    apb_read(2, 1, 32'h89abcdef);
    #10
    $finish();
end

task apb_read(input [1:0] sel, [31:0] addr, expected);
begin
    $display("apb_read %x, expecting %x", addr, expected);
    @(posedge PCLK)
    PSEL <= 1<<sel;
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
