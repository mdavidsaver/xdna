`timescale  1 ps / 1 ps
module dna_reader #(
    parameter [56:0] SIM_DNA_VALUE = 57'h0
) (
    input clk,
    input rst_n,
    output reg [56:0] DNA,
    output DNA_READY
);

// number of bits in DNA_PORT shift register
localparam NBIT = 57;
localparam NSTATE = NBIT + 3;

(* MARK_DEBUG="TRUE" *)
reg [$clog2(NSTATE)-1:0] state = 0;
assign DNA_READY = state == NSTATE-1;

(* MARK_DEBUG="TRUE" *)
reg shift=0, shifted=0, read=0;
(* MARK_DEBUG="TRUE" *)
wire dout;

always @(posedge clk)
begin
    shift <= 0;
    shifted <= shift;
    read <= 0;

    if(shifted)
        DNA <= {DNA[NBIT-2:0], dout};

    if(~rst_n) begin
        DNA <= 0;
        state <= 0;
        shifted <= 0;

    end else if(~DNA_READY && state!=NSTATE-1) begin
        state <= state + 1;

        if(state==0)
            read <= 1;

        if(state<NBIT)
            shift <= 1;
    end
end

DNA_PORT #(
    .SIM_DNA_VALUE(SIM_DNA_VALUE)
) dna_i (
    .CLK(clk),
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
