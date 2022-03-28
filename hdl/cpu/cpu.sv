import rv32i_types::*;

module cpu(
    input clk,
    input rst,

    output logic       inst_read,
    output rv32i_word  inst_addr,
    input logic        inst_resp,
    input rv32i_word  inst_rdata,

    output logic data_read,
    output logic data_write,
    output logic [3:0] data_mbe,
    output rv32i_word data_addr,
    output rv32i_word data_wdata,
    input logic data_resp,
    input rv32i_word data_rdata

    // input mem_resp,
    // input rv32i_word mem_rdata,
    // output logic mem_read,
    // output logic mem_write,
    // output logic [3:0] mem_byte_enable,
    // output rv32i_word mem_address,
    // output rv32i_word mem_wdata
);

// assign mem_read = 1'b1;
// assign mem_write = 0;

rv32i_opcode opcode;
logic[2:0] funct3;
logic[6:0] funct7;

rv32i_control_word ctrl;

datapath datapath(.*);

control_rom control_rom(.*);

endmodule : cpu