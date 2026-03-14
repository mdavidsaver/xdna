`timescale  1 ns / 1 ps

/* AMBA APB Completer/slave for reading the xilinx FPGA unique ID (aka. device DNA)
 */

// TODO: Figure out where this X_INTERFACE_INFO business is actually documented.
//       How to specify window size?
module dna_apb #(
    parameter [56:0] SIM_DNA_VALUE = 57'h0,
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

wire [56:0] DNA;
wire DNA_READY;

always @(posedge PCLK)
begin
    PRDATA <= 32'hffffffff;
    PREADY <= 0;

    if(PRESETn & PSEL) begin
        if(~PWRITE) begin
            PREADY <= DNA_READY;
            case (PADDR & 32'h000000fc)
            0: PRDATA <= {7'h00, DNA[56:32]};
            4: PRDATA <= DNA[31:0];
            8: PRDATA <= 32'hdeadbeef;
            endcase
        end
    end
end

dna_reader #(
    .SIM_DNA_VALUE(SIM_DNA_VALUE),
    .PCLK_DIV(PCLK_DIV)
) dna (
    .clk(PCLK),
    .rst_n(PRESETn),
    .DNA(DNA),
    .DNA_READY(DNA_READY)
);

endmodule
