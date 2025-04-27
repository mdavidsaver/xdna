`timescale  1 ns / 1 ps

/* AMBA APB Completer/slave for reading the xilinx FPGA unique ID (aka. device DNA)
 */

// TODO: Figure out where this X_INTERFACE_INFO business is actually documented.
//       How to specify window size?
module dna_apb #(
    parameter [56:0] SIM_DNA_VALUE = 57'h0,
    parameter [31:0] PADDR_MASK = 32'h000000ff,
    // divide down PCLK to mean undocumented <= 100MHz requirement
    // asserted in LBNL Bedrock source.
    parameter PCLK_DIV = 1
) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 PCLK CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET PRESETn, ASSOCIATED_BUSIF S_APB" *)
    input PCLK,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 PRESETn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input PRESETn,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PADDR" *)
    (* MARK_DEBUG="TRUE" *)
    input      [31:0]           PADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PSEL" *)
    (* MARK_DEBUG="TRUE" *)
    input PSEL, // Slave Select (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PENABLE" *)
    (* MARK_DEBUG="TRUE" *)
    input PENABLE, // Enable (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PWRITE" *)
    input PWRITE, // Write Control (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PWDATA" *)
    input [31:0] PWDATA, // Write Data (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PREADY" *)
    (* MARK_DEBUG="TRUE" *)
    output reg PREADY, // Slave Ready (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PRDATA" *)
    (* MARK_DEBUG="TRUE" *)
    output reg [31:0] PRDATA, // Read Data (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PSLVERR" *)
    output PSLVERR // Slave Error Response (required)
);

assign PSLVERR = 1'b0; // always all right!

reg [$clog2(PCLK_DIV)-1:0] div = 0;

always @(posedge PCLK) begin
    div <= div + 1;
    if(~PRESETn | div==PCLK_DIV-1)
        div <= 0;
end

always @(posedge PCLK)
begin
    PRDATA <= 32'hffffffff;
    PREADY <= 0;

    if(PRESETn & PSEL) begin
        if(~PWRITE) begin
            PREADY <= READY;
            case (PADDR & PADDR_MASK)
            0: PRDATA <= {7'h00, ID[56:32]};
            4: PRDATA <= ID[31:0];
            8: PRDATA <= 32'hdeadbeef;
            endcase
        end
    end
end

// number of bits in DNA_PORT shift register
localparam NBIT = 57;
localparam NSTATE = NBIT + 3;

(* MARK_DEBUG="TRUE" *)
reg [$clog2(NSTATE)-1:0] state = 0;
wire READY = state == NSTATE-1;

(* MARK_DEBUG="TRUE" *)
reg shift=0, shifted=0, read=0;
(* MARK_DEBUG="TRUE" *)
wire dout;
(* MARK_DEBUG="TRUE" *)
reg [NBIT-1:0] ID;

always @(posedge PCLK)
begin
    shift <= 0;
    shifted <= shift;
    read <= 0;

    if(shifted)
        ID <= {ID[NBIT-2:0], dout};

    if(~PRESETn) begin
        ID <= 0;
        state <= 0;
        shifted <= 0;

    end else if(~READY & div==0 & state!=NSTATE-1) begin
        state <= state + 1;

        if(state==0)
            read <= 1;

        if(state<NBIT)
            shift <= 1;
    end
end

/* xilinx documentation "7 Series FPGAs Configuration User Guide" (UG470) v1.17 page 115
 * Table 5-42
 * seems to show the same high bit of DNA appears on two consecutive ticks,
 * after READ and after first SHIFT.
 */
DNA_PORT #(
    .SIM_DNA_VALUE(SIM_DNA_VALUE)
) dna_i (
    .CLK(PCLK),
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
