`define INST_MEM_DEPTH 128
`define PC_BITS 8

module device_pc (
    input                       i_nrst,
    input                       i_clk,
    input       [`PC_BITS-1:0]  i_data_in,
    output reg  [`PC_BITS-1:0]  o_data_out
);

    // Defino el tamaño de memoria
    reg [`PC_BITS-1:0] mem;

    // Siempre que cambia cs o we
    always @(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            mem <= { `PC_BITS{1'b0} };
            $display("inst mem erase: %d", mem);
        end
        else begin
            // if (i_cs && i_we) begin // Si esta seleccionado y debo escribir...
                mem <= i_data_in;
                $display("inst mem update: %d", mem);
            // end
        end
    end
    
    always @(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            o_data_out = { `PC_BITS{1'bz} };
            $display("inst mem erase: %d", mem);
        end
        else begin    
            // if (i_cs && i_oe) begin
                o_data_out = mem;
                $display("out inst mem: %d", o_data_out);
            // end
            // Si esta seleccionado el chip y debo sacar el dato.. sino Z
            // else if (i_cs && !i_oe) begin
            //     o_data_out = { `PC_BITS{1'bz} };
            //     $display("inst mem off: %d", o_data_out);
            // end
        end
    end

endmodule
