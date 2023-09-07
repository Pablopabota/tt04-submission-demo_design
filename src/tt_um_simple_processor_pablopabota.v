`default_nettype none
//`include "simple_8b_alu.v"
`include "i2c_slave.v"

module tt_um_simple_processor_pablopabota #( parameter MAX_COUNT = 24'd10_000_000 ) (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // use bidirectionals as outputs
    assign uio_oe = 8'b00000000;
    // unused bidirectional have to be tied to GND
    assign uio_out = 0;

    // Simple mux for SDA line
    wire sda_wire;
    assign sda_wire = ui_in[7] ? uo_out[0] : ui_in[0];

    i2c_slave prog_port(.sda(sda_wire), .scl(ui_in[1]), .i2c_rst(ui_in[2]));


endmodule
