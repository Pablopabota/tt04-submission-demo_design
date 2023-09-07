`define INST_MEM_DEPTH 256
`define PC_BITS $clog2(`INST_MEM_DEPTH)
`define INST_MEM_WORD 32
`define INST_MEM_PROG_WORD 8
`define BYTE_SIZE 8

module inst_memory (
    input   [`PC_BITS-1:0]          i_address,
    input   [`PC_BITS-1:0]          i_data_in,
    input                           i_cs,
    output  [`INST_MEM_WORD-1:0]    o_data_out
);

    // Defino el tamaño de memoria como un arreglo de 256 lugares de 8bits (64 instrucciones de 32 bits)
    // Esta limitante se deberia poder cambiar cambiando el puerto i2c que esta limitado direcciones de 8bits
    reg [`BYTE_SIZE-1:0] mem [`INST_MEM_DEPTH-1:0];

    // Si esta seleccionado el chip y debo sacar el dato.. sino Z
    assign o_data_out = (!i_cs) ? { mem [i_address+3], mem [i_address+2], mem [i_address+1], mem [i_address] } : { { 24{1'bz} }, mem[i_address] };

    // Siempre que cambia cs
    always @(*) begin
        // Si esta seleccionado y debo escribir...
        if (i_cs) begin
            mem[i_address]  =   i_data_in;
        end
    end

endmodule
