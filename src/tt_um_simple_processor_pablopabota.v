`default_nettype none
// `include "program_counter.v"
// `include "instruction_mem.v"
// `include "i2c_slave.v"

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

    wire ext_sda_in = ui_in[0];
    wire ext_scl_in = ui_in[1];
    wire ext_i2c_rst = ui_in[2];
    wire i2c_cs = ui_in[3]; // i2c_cs = 1: Device is programmable, i2c_cs = 0: Device is running
    wire pc_src = ui_in[4];
    wire sda_oe = ui_in[7]; // sda_oe = 1: SDA OUTPUT, sda_oe = 0: SDA INPUT

    wire ext_sda_out, ext_scl_out;
    assign uo_out[0] = ext_sda_out;
    assign uo_out[1] = ext_scl_out;

    wire [7:0]  pc_wire;
    wire [7:0]  next_pc_wire;

    // use bidirectionals as outputs
    assign uio_oe = 8'b00000000;
    // unused bidirectional have to be tied to GND
    assign uio_out = 0;
    assign uo_out[7:2] = 0;

    // Simple mux for SDA line
    i2c_slave i2c_prog_port(.i_sda(ext_sda_in), .i_scl(ext_scl_in), .i2c_rst(ext_i2c_rst), 
                            .o_sda(ext_sda_out), .o_scl(ext_scl_out),
                            .addr_reg(i2c_instruction_addr), .inst_data_read_reg(instruction[7:0]), .inst_data_reg(i2c_instruction_value));

    assign next_pc_wire = pc_src ? (pc_wire + 4) : 0;
    device_pc program_counter_register(.i_nrst(rst_n), .i_clk(clk), .i_data_in(next_pc_wire), .o_data_out(pc_wire));

    wire [7:0]  next_inst_addr;
    wire [7:0]  i2c_instruction_addr;
    wire [7:0]  i2c_instruction_value;
    wire [31:0] instruction;
    assign next_inst_addr = i2c_cs ? i2c_instruction_addr : pc_wire;

    inst_memory device_inst_mem(.i_address(next_inst_addr), .i_data_in(i2c_instruction_value), .i_cs(i2c_cs), .o_data_out(instruction));


endmodule
