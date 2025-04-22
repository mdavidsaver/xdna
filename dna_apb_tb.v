`timescale  1 ps / 1 ps

module dna_apb_tb();


reg PCLK = 0;
always #5000 PCLK <= ~PCLK;

reg PRESETn = 1;

reg PSEL = 0, PENABLE;
reg [31:0] PADDR;
wire PREADY, PSLVERR;
wire [31:0] PRDATA;

dna_apb #(
    .PCLK_DIV(1)
) dut(
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PSEL(PSEL),
    .PADDR(PADDR),
    .PENABLE(PENABLE),
    .PWRITE(1'b0),
    .PREADY(PREADY),
    .PRDATA(PRDATA),
    .PWDATA(32'hxxxxxxxx),
    .PSLVERR(PSLVERR)
);

initial begin
    $dumpfile(`VCD);
    $dumpvars(0,dna_apb_tb);

    #10
    @(posedge PCLK)
    apb_read(0, 32'h01234567);
    apb_read(0, 32'h01234567);
    apb_read(1, 32'h89abcdef);
    #10
    $finish();
end

	task sum (input [7:0] a, b, output [7:0] c);
		begin
			c = a + b;
		end
	endtask

task apb_read(input [31:0] addr, expected);
begin
    $display("apb_read %x, expect %x", addr, expected);
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
    $display("apb_read %x, expect %x, read %x", addr, expected, PRDATA);
    if(PRDATA!=expected) begin
        $display("Mis-match!");
        $stop;
    end
end
endtask

endmodule
