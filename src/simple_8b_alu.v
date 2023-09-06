`define BITS 8

// Instrucciones definidas para la ALU
`define ALU_ADD     'b000
`define ALU_SUB     'b001
`define ALU_AND     'b010
`define ALU_OR      'b011
`define ALU_SLT     'b101


module alu_8b (
    input [`BITS-1:0] A,        // Puede ser PC o rd1
    input [`BITS-1:0] B,        // Puede ser rd2 o Imm
    input [2:0] opcode,         // Senal que indica que operacion se debe ejecutar, esto viene del modulo de control
    output reg [`BITS-1:0] R,   //
    output reg zero_flag        // Bit que se pone en zero cuando el resultado de la operacion es zero
);

    always @(*) begin
        case (opcode)
            `ALU_ADD: begin
                R = A + B;
            end
            `ALU_SUB: begin
                R = A - B;
            end
            `ALU_AND: begin
                R = A & B;
            end
            `ALU_OR: begin
                R = A | B;
            end
            `ALU_SLT: begin
                R = (A < B)? 1 : 0;
            end
            default: begin
                R = {`BITS{1'bz}};
            end
        endcase
        // Seteo (o no) el flag de resultado 0 si es necesario.
        zero_flag = (R == 0)? 1 : 0;
    end
    
endmodule
