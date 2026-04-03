# Xilinx dna bus access

Demonstration of annotating modules for use with Vivado block designer as RTL modules.

Allows reading of 57 bit unique ID from `DNA_PORT` primitive.

- `dna_axi.v`
  - AXI4-LITE endpoint

Each endpoint implements reads from 3 address offsets.
Accepts 4096 bytes of address space (minimum vivado AXI crossbar switch allows).

- offset 0 - `{7'h00, DNA[56:32]}`
- offset 4 - `DNA[31:0]`
- offset 8 - `32'hdeadbeef`

Test benches runnable with iverilog.

## References

- UG994 [List of Supported X_ Attributes](https://docs.amd.com/r/en-US/ug994-vivado-ip-subsystems/List-of-Supported-X_-Attributes)
- `IP Catalog` pane -> `Interfaces` tab
  - Look for files in Vivado install: `data/ip/interfaces/interfaces/`
- `X_INTERFACE_PARAMETER` key names documented??
  - So far only "discoverable" effective keys and values through Vivado GUI :(
  - `Block Interface Proporties` pane -> `CONFIG`
- XML Schema Definitions
  - [`spirit:`](http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009/)
  - `xilinx:` ???
- AMBA Specifications, includes AXI4-LITE
