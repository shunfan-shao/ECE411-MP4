import rv32i_types::*;

module datapath(
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
    input rv32i_word data_rdata,

    input rv32i_control_word ctrl,

    output rv32i_opcode opcode,
    output logic[2:0] funct3,
    output logic[6:0] funct7
);

localparam STAGE_IF  = 0;
localparam STAGE_ID  = 1;
localparam STAGE_EX  = 2;
localparam STAGE_MEM = 3;
localparam STAGE_WB  = 4;

logic stall;
rv32i_word inst[STAGE_ID:STAGE_WB];
rv32i_decoder_word inst_decoder[STAGE_ID:STAGE_WB];
rv32i_control_word inst_control[STAGE_ID:STAGE_WB];
rv32i_word alu_out[STAGE_EX:STAGE_WB];
rv32i_word rs1_out[STAGE_ID:STAGE_EX], rs2_out[STAGE_ID:STAGE_MEM];
rv32i_word mem_rdata[STAGE_WB:STAGE_WB];
rv32i_word pc_out[STAGE_IF:STAGE_WB];
logic br_en[STAGE_EX:STAGE_WB];

rv32i_word cpmmux_out;
rv32i_word alumux1_out, alumux2_out;
rv32i_word regfilemux_out;
// rv32i_word alu_out;
rv32i_word pcmux_out = 32'h00000060;

assign opcode = inst_decoder[STAGE_ID].opcode;
assign funct3 = inst_decoder[STAGE_ID].funct3;
assign funct7 = inst_decoder[STAGE_ID].funct7;

assign inst_read = rst ? 1'b0 : 1'b1;
assign inst_addr = pc_out[STAGE_IF];

assign data_read = inst_decoder[STAGE_MEM].opcode == op_load;
assign data_write = inst_decoder[STAGE_MEM].opcode == op_store;
assign data_addr = {alu_out[STAGE_MEM][31:2], 2'b00};

// logic[2:0] funct3[STAGE_IF:STAGE_WB];
// logic[6:0] funct7[STAGE_IF:STAGE_WB];
// rv32i_opcode opcode[STAGE_IF:STAGE_WB];
// logic [31:0] i_imm[STAGE_IF:STAGE_WB];
// logic [31:0] s_imm[STAGE_IF:STAGE_WB];
// logic [31:0] b_imm[STAGE_IF:STAGE_WB];
// logic [31:0] u_imm[STAGE_IF:STAGE_WB];
// logic [31:0] j_imm[STAGE_IF:STAGE_WB];
// logic [4:0] rs1[STAGE_IF:STAGE_WB];
// logic [4:0] rs2[STAGE_IF:STAGE_WB];
// logic [4:0] rd[STAGE_IF:STAGE_WB];

assign inst[STAGE_ID] = inst_rdata;
// assign inst[STAGE_ID] = inst[STAGE_IF]; //TODO: unless stall
assign inst_control[STAGE_ID] = ctrl;

pc_register #(.width(32))
PC(
    .clk(clk),
    .rst(rst),
    .load(~stall), // TODO: for cp1, always load
    .in(pcmux_out),
    .out(pc_out[STAGE_IF])
);

// register #(.width(32))
// InstDecoder_IF_ID(
//     .clk(clk),
//     .rst(rst),
//     .load(1'b1), // TODO: for cp1, always load
//     .in(inst_decoder[STAGE_IF]),
//     .out(inst_decoder[STAGE_ID])
// );


/* pc out */
register #(.width(32))
PC_IF_ID(
    .clk(clk),
    .rst(rst),
    .load(~stall),
    .in(pc_out[STAGE_IF]),
    .out(pc_out[STAGE_ID])
);

register #(.width(32))
PC_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(~stall),
    .in(pc_out[STAGE_ID]),
    .out(pc_out[STAGE_EX])
);

register #(.width(32))
PC_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(~stall),
    .in(pc_out[STAGE_EX]),
    .out(pc_out[STAGE_MEM])
);

register #(.width(32))
PC_MEM_WB(
    .clk(clk),
    .rst(rst),
    .load(~stall),
    .in(pc_out[STAGE_MEM]),
    .out(pc_out[STAGE_WB])
);

/* Instruction Decoder IR */
register #(.width($bits(rv32i_decoder_word)))
InstDecoder_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(~stall), // TODO: for cp1, always load
    .in(inst_decoder[STAGE_ID]),
    .out(inst_decoder[STAGE_EX])
);

register #(.width($bits(rv32i_decoder_word)))
InstDecoder_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(~stall), // TODO: for cp1, always load
    .in(inst_decoder[STAGE_EX]),
    .out(inst_decoder[STAGE_MEM])
);

register #(.width($bits(rv32i_decoder_word)))
InstDecoder_MEM_WB(
    .clk(clk),
    .rst(rst),
    .load(~stall), // TODO: for cp1, always load
    .in(inst_decoder[STAGE_MEM]),
    .out(inst_decoder[STAGE_WB])
);

/* Control Rom */
register #(.width($bits(rv32i_control_word)))
Ctrl_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(~stall), //TODO: for cp not stall
    .in(inst_control[STAGE_ID]),
    .out(inst_control[STAGE_EX])
);

register #(.width($bits(rv32i_control_word)))
Ctrl_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(~stall), //TODO: for cp not stall
    .in(inst_control[STAGE_EX]),
    .out(inst_control[STAGE_MEM])
);

register #(.width($bits(rv32i_control_word)))
Ctrl_MEM_WB(
    .clk(clk),
    .rst(rst),
    .load(~stall), //TODO: for cp not stall
    .in(inst_control[STAGE_MEM]),
    .out(inst_control[STAGE_WB])
);

/* ALU OUT */
register #(.width(32))
ALU_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(~stall), //TODO: for cp not stall
    .in(alu_out[STAGE_EX]),
    .out(alu_out[STAGE_MEM])
);

register #(.width(32))
ALU_MEM_WB(
    .clk(clk),
    .rst(rst),
    .load(~stall), //TODO: for cp not stall
    .in(alu_out[STAGE_MEM]),
    .out(alu_out[STAGE_WB])
);

/* rs_out data */
register #(.width(32))
RS1_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(~stall), //TODO: for cp not stall
    .in(rs1_out[STAGE_ID]),
    .out(rs1_out[STAGE_EX])
);

register #(.width(32))
RS2_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(~stall), //TODO: for cp not stall
    .in(rs2_out[STAGE_ID]),
    .out(rs2_out[STAGE_EX])
);

register #(.width(32))
RS2_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(~stall), //TODO: for cp not stall
    .in(rs2_out[STAGE_EX]),
    .out(rs2_out[STAGE_MEM])
);

/* MDR */
register #(.width(32))
MDR(
    .clk(clk),
    .rst(rst),
    .load(~stall),
    .in(data_rdata),
    .out(mem_rdata[STAGE_WB])
);

/* BR_EN */
register #(.width(1))
BR_EN_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(~stall),
    .in(br_en[STAGE_EX]),
    .out(br_en[STAGE_MEM])
);

register #(.width(1))
BR_EN_MEM_WB(
    .clk(clk),
    .rst(rst),
    .load(~stall),
    .in(br_en[STAGE_MEM]),
    .out(br_en[STAGE_WB])
);
/* All Registers */


ir 
IR(
    .clk(clk),
    .rst(rst),
    .load(~stall),
    .in(inst[STAGE_ID]),
    .funct3(inst_decoder[STAGE_ID].funct3),
    .funct7(inst_decoder[STAGE_ID].funct7),
    .opcode(inst_decoder[STAGE_ID].opcode),
    .i_imm(inst_decoder[STAGE_ID].i_imm),
    .s_imm(inst_decoder[STAGE_ID].s_imm),
    .b_imm(inst_decoder[STAGE_ID].b_imm),
    .u_imm(inst_decoder[STAGE_ID].u_imm),
    .j_imm(inst_decoder[STAGE_ID].j_imm),
    .rs1(inst_decoder[STAGE_ID].rs1),
    .rs2(inst_decoder[STAGE_ID].rs2),
    .rd(inst_decoder[STAGE_ID].rd)
);

alu 
ALU(
    .aluop(inst_control[STAGE_EX].aluop),
    .a(alumux1_out),
    .b(alumux2_out),
    .f(alu_out[STAGE_EX])
);

regfile
REGFILE(
    .clk(clk),
    .rst(rst),
    .load(inst_control[STAGE_WB].load_regfile),
    .in(regfilemux_out), 
    .src_a(inst_decoder[STAGE_ID].rs1), 
    .src_b(inst_decoder[STAGE_ID].rs2), 
    .dest(inst_decoder[STAGE_WB].rd),
    .reg_a(rs1_out[STAGE_ID]), 
    .reg_b(rs2_out[STAGE_ID])
);

cmp
CMP(
    .cmpop(inst_control[STAGE_EX].cmpop),
    .a(rs1_out[STAGE_EX]),
    .b(cpmmux_out),
    .br_en(br_en[STAGE_EX])
);


always_comb begin : STALL
    stall = 1'b0;

    if (inst_read & ~inst_resp) begin
        stall = 1'b1;
    end else if (data_read & ~data_resp) begin
        stall = 1'b1;
    end else if (data_write & ~data_resp) begin
        stall = 1'b1;
    end

end

always_comb begin : MEM_W
    unique case (inst_decoder[STAGE_MEM].funct3) 
        rv32i_types::sh: begin
            data_wdata = rs2_out[STAGE_MEM] << {alu_out[STAGE_MEM][1:0], 3'd0};  //shift bits, so *8 to bytes
            data_mbe = 4'b0011 << alu_out[STAGE_MEM][1:0];
        end
        rv32i_types::sb: begin
            data_wdata = rs2_out[STAGE_MEM] << {alu_out[STAGE_MEM][1:0], 3'd0};
            data_mbe = 4'b0001 << alu_out[STAGE_MEM][1:0];
        end
        default: begin  
            data_wdata = rs2_out[STAGE_MEM];
            data_mbe = 4'b1111;
        end
    endcase
end

always_comb begin : BRANCH
    unique case (inst_decoder[STAGE_EX].opcode)
        op_br: begin
            pcmux_out = (br_en[STAGE_EX] ? alu_out[STAGE_EX] : pc_out[STAGE_IF] + 4);
        end
        op_jal:  begin
            pcmux_out = alu_out[STAGE_EX];
        end
        op_jalr: begin
            pcmux_out = {alu_out[STAGE_EX][31:1], 1'b0};
        end
        default: pcmux_out = pc_out[STAGE_IF] + 4;
    endcase
end

always_comb begin : MUXES

    unique case (inst_control[STAGE_EX].cmpmux_sel)
        cmpmux::rs2_out: cpmmux_out = rs2_out[STAGE_EX];
    endcase


    unique case (inst_control[STAGE_EX].alumux1_sel)
        alumux::rs1_out: alumux1_out = rs1_out[STAGE_EX];
        alumux::pc_out: alumux1_out = pc_out[STAGE_EX];
    endcase

    unique case (inst_control[STAGE_EX].alumux2_sel)
        alumux::i_imm: alumux2_out = inst_decoder[STAGE_EX].i_imm;
        alumux::s_imm: alumux2_out = inst_decoder[STAGE_EX].s_imm;
        alumux::b_imm: alumux2_out = inst_decoder[STAGE_EX].b_imm;
        alumux::u_imm: alumux2_out = inst_decoder[STAGE_EX].u_imm;
        alumux::rs2_out: alumux2_out = rs2_out[STAGE_EX];
        // default: $display("unimplemented option %d at %0d\n", inst_control[STAGE_EX].alumux2_sel, `__LINE__);
    endcase

    unique case (inst_control[STAGE_WB].regfilemux_sel)
        regfilemux::u_imm: regfilemux_out = inst_decoder[STAGE_WB].u_imm;
        regfilemux::br_en: regfilemux_out =  {31'd0, br_en[STAGE_WB]};
        regfilemux::pc_plus4: regfilemux_out = pc_out[STAGE_WB] + 4;
        regfilemux::alu_out: regfilemux_out = alu_out[STAGE_WB];
        regfilemux::lw: regfilemux_out = mem_rdata[STAGE_WB]; 
        regfilemux::lh: begin
            unique case (alu_out[STAGE_WB][1:0])
                2'b00: regfilemux_out = {{16{mem_rdata[STAGE_WB][15]}}, mem_rdata[STAGE_WB][15:0]}; 
                2'b10: regfilemux_out = {{16{mem_rdata[STAGE_WB][31]}}, mem_rdata[STAGE_WB][31:16]};
            endcase
        end
        regfilemux::lhu: begin
            unique case (alu_out[STAGE_WB][1:0])
                2'b00: regfilemux_out = {16'd0, mem_rdata[STAGE_WB][15:0]}; 
                2'b10: regfilemux_out = {16'd0, mem_rdata[STAGE_WB][31:16]};
            endcase
        end
        regfilemux::lb: begin
            unique case (alu_out[STAGE_WB][1:0])
                2'b00: regfilemux_out = {{24{mem_rdata[STAGE_WB][7]}}, mem_rdata[STAGE_WB][7:0]};
                2'b01: regfilemux_out = {{24{mem_rdata[STAGE_WB][15]}}, mem_rdata[STAGE_WB][15:8]};
                2'b10: regfilemux_out = {{24{mem_rdata[STAGE_WB][23]}}, mem_rdata[STAGE_WB][23:16]};
                2'b11: regfilemux_out = {{24{mem_rdata[STAGE_WB][31]}}, mem_rdata[STAGE_WB][31:24]};
            endcase
        end
        regfilemux::lbu: begin
            unique case (alu_out[STAGE_WB][1:0])
                2'b00: regfilemux_out = {24'd0, mem_rdata[STAGE_WB][7:0]};
                2'b01: regfilemux_out = {24'd0, mem_rdata[STAGE_WB][15:8]};
                2'b10: regfilemux_out = {24'd0, mem_rdata[STAGE_WB][23:16]};
                2'b11: regfilemux_out = {24'd0, mem_rdata[STAGE_WB][31:24]};
            endcase
        end
        // default: $display("Unexpected regfilemux_sel %d at %0t\n", inst_control[STAGE_WB].regfilemux_sel, $time);
    endcase
end

endmodule : datapath