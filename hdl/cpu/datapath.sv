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

localparam S_PC_TAG = 5;

logic branch_taken;
logic stall, stall_ifid, flush;
rv32i_word inst[STAGE_ID:STAGE_WB];
rv32i_decoder_word inst_decoder[STAGE_ID:STAGE_WB];
rv32i_control_word inst_control[STAGE_ID:STAGE_WB];
rv32i_word alu_out[STAGE_EX:STAGE_WB];
rv32i_word rs1_out[STAGE_ID:STAGE_EX], rs2_out[STAGE_ID:STAGE_MEM];
rv32i_word mem_rdata[STAGE_WB:STAGE_WB];
rv32i_word pc_out[STAGE_IF:STAGE_WB];
logic br_en[STAGE_EX:STAGE_WB];

logic btb_hit[STAGE_IF:STAGE_EX];
rv32i_word btb_predict_address[STAGE_IF:STAGE_EX];

rv32i_word alu_ex_out;
logic mult_start, mult_done;
logic [63:0] mult_out;
logic div_start, div_done;
rv32i_word quotient;
rv32i_word remainder;

rv32i_word cpmmux_out;
rv32i_word alumux1_out, alumux2_out;
rv32i_word regfilemux_out;
// rv32i_word alu_out;
rv32i_word pcmux_out = 32'h00000060;

rv32i_word rs1_fwoutmux_out, rs2_fwoutmux_out[STAGE_EX:STAGE_MEM];

assign opcode = inst_decoder[STAGE_ID].opcode;
assign funct3 = inst_decoder[STAGE_ID].funct3;
assign funct7 = inst_decoder[STAGE_ID].funct7;

assign inst_read = rst ? 1'b0 : 1'b1;
assign inst_addr = pc_out[STAGE_IF];

assign data_read = inst_decoder[STAGE_MEM].opcode == op_load;
assign data_write = inst_decoder[STAGE_MEM].opcode == op_store;
assign data_addr = {alu_out[STAGE_MEM][31:2], 2'b00};

rv32i_decoder_word id_ex_decoder_word;

rv32i_word memregfilemux_out;


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

rv32i_word inst_addr_minus_4; //TODO: remove this
assign inst_addr_minus_4 = inst_addr - 12;
// assign inst[STAGE_ID] = inst[STAGE_IF]; //TODO: unless stall

pc_register #(.width(32))
PC(
    .clk(clk),
    .rst(rst),
    .load(~(stall | stall_ifid)), 
    .in(pcmux_out),
    .out(pc_out[STAGE_IF])
);

// register #(.width(32))
// InstDecoder_IF_ID(
//     .clk(clk),
//     .rst(rst),
//     .load(1'b1), 
//     .in(inst_decoder[STAGE_IF]),
//     .out(inst_decoder[STAGE_ID])
// );


/* pc out */

genvar in_i;
generate
    for (in_i=STAGE_EX; in_i<STAGE_WB; in_i++) begin : generate_stage_ex_wb
        register #(.width(32))
        pc_register_fwd(
            .clk(clk),
            .rst(rst),
            .load(~stall),
            .in(pc_out[in_i]),
            .out(pc_out[in_i+1])
        );

        register #(.width($bits(rv32i_decoder_word)))
        inst_decoder_fwd(
            .clk(clk),
            .rst(rst),
            .load(~stall), 
            .in(inst_decoder[in_i]),
            .out(inst_decoder[in_i+1])
        );

        register #(.width($bits(rv32i_control_word)))
        inst_control_fwd(
            .clk(clk),
            .rst(rst),
            .load(~stall), 
            .in(inst_control[in_i]),
            .out(inst_control[in_i+1])
        );
        
        register #(.width(32))
        alu_fwd(
            .clk(clk),
            .rst(rst),
            .load(~stall), 
            .in(alu_out[in_i]),
            .out(alu_out[in_i+1])
        );

        register #(.width(1))
        br_en_fwd(
            .clk(clk),
            .rst(rst),
            .load(~stall),
            .in(br_en[in_i]),
            .out(br_en[in_i+1])
        );

        if (in_i < STAGE_MEM) begin
            register #(.width(32))
            rs2_fwd(
                .clk(clk),
                .rst(rst),
                .load(~stall), 
                .in(rs2_out[in_i]),
                .out(rs2_out[in_i+1])
            );

            register #(.width(32))
            rs2_fwoutmux_out_fwd(
                .clk(clk),
                .rst(rst),
                .load(~stall),
                .in(rs2_fwoutmux_out[in_i]),
                .out(rs2_fwoutmux_out[in_i+1])
            );
        end
    end
endgenerate

register #(.width(32))
PC_IF_ID(
    .clk(clk),
    .rst(rst),
    .load(~(stall | stall_ifid)),
    .in(pc_out[STAGE_IF]),
    .out(pc_out[STAGE_ID])
);

register #(.width(32))
PC_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(~(stall | stall_ifid)),
    .in(pc_out[STAGE_ID]),
    .out(pc_out[STAGE_EX])
);

/* Instruction Decoder IR */
register #(.width($bits(rv32i_decoder_word)))
InstDecoder_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(~stall), 
    .in(id_ex_decoder_word),
    .out(inst_decoder[STAGE_EX])
);

/* Control Rom */
register #(.width($bits(rv32i_control_word)))
Ctrl_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(~(stall | stall_ifid)), 
    .in(inst_control[STAGE_ID]),
    .out(inst_control[STAGE_EX])
);

/* rs_out data */
register #(.width(32))
RS1_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(~(stall | stall_ifid)), 
    .in(rs1_out[STAGE_ID]),
    .out(rs1_out[STAGE_EX])
);

register #(.width(32))
RS2_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(~(stall | stall_ifid)), 
    .in(rs2_out[STAGE_ID]),
    .out(rs2_out[STAGE_EX])
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


/* BTB predict */
register #(.width(1))
BTB_IF_ID(
    .clk(clk),
    .rst(rst | flush),
    .load(~(stall | stall_ifid)),
    .in(btb_hit[STAGE_IF]),
    .out(btb_hit[STAGE_ID])
);

register #(.width(1))
BTB_ID_EX(
    .clk(clk),
    .rst(rst | flush),
    .load(~(stall | stall_ifid)),
    .in(btb_hit[STAGE_ID]),
    .out(btb_hit[STAGE_EX])
);

register #(.width(32))
BTB_PRED_ADDR_IF_ID(
    .clk(clk),
    .rst(rst),
    .load(~(stall | stall_ifid)),
    .in(btb_predict_address[STAGE_IF]),
    .out(btb_predict_address[STAGE_ID])
);

register #(.width(32))
BTB_PRED_ADDR_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(~(stall | stall_ifid)),
    .in(btb_predict_address[STAGE_ID]),
    .out(btb_predict_address[STAGE_EX])
);



/* All Registers */


ir 
IR(
    .clk(clk),
    .rst(rst),
    .load(~(stall | stall_ifid)),
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
    .f(alu_ex_out)
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
    .a(rs1_fwoutmux_out),
    .b(cpmmux_out),
    .br_en(br_en[STAGE_EX])
);

btb #(.s_index(S_PC_TAG))
BTB(
    .clk(clk),
    .rst(rst),
    .br_en(branch_taken),

    .pc_ex(pc_out[STAGE_EX]),
    .target_address(alu_ex_out),

    .pc_if(pc_out[STAGE_IF]),
    .hit(btb_hit[STAGE_IF]),
    .predict_address(btb_predict_address[STAGE_IF])
);

multicycle_multiplier
MULT(
    .clk(clk),
    .a(alumux1_out),
    .b(alumux2_out),
    .product(mult_out),
    .calc(mult_start),
    .done(mult_done)
);

multicycle_divider
DIV(
    .clk(clk),
    .rst(rst),
    .dividend(alumux1_out),
    .divisor(alumux2_out),
    .quotient(quotient),
    .remainder(remainder),
    .calc(div_start),
    .done(div_done)
); 

always_comb begin : FORWARD
    rs2_fwoutmux_out[STAGE_EX] = rs2_out[STAGE_EX];
    if (inst_decoder[STAGE_WB].rd != 5'd0) begin
        if (inst_decoder[STAGE_WB].rd == inst_decoder[STAGE_EX].rs2) begin
            rs2_fwoutmux_out[STAGE_EX] = regfilemux_out;
        end
    end
    if (inst_decoder[STAGE_MEM].rd != 5'd0) begin
        if (inst_decoder[STAGE_MEM].rd == inst_decoder[STAGE_EX].rs2) begin
            rs2_fwoutmux_out[STAGE_EX] = alu_out[STAGE_MEM];
        end
    end

    rs1_fwoutmux_out = rs1_out[STAGE_EX];
    if (inst_decoder[STAGE_WB].rd != 5'd0) begin
        if (inst_decoder[STAGE_WB].rd == inst_decoder[STAGE_EX].rs1) begin
            rs1_fwoutmux_out = regfilemux_out;
        end
    end
    if (inst_decoder[STAGE_MEM].rd != 5'd0) begin
        if (inst_decoder[STAGE_MEM].rd == inst_decoder[STAGE_EX].rs1) begin
            unique case (inst_control[STAGE_MEM].regfilemux_sel) 
                regfilemux::alu_out: rs1_fwoutmux_out = alu_out[STAGE_MEM];
                regfilemux::u_imm: rs1_fwoutmux_out = inst_decoder[STAGE_MEM].u_imm; // auipc
                regfilemux::br_en: rs1_fwoutmux_out = {31'd0, br_en[STAGE_MEM]}; // shift
                default: rs1_fwoutmux_out = alu_out[STAGE_MEM];
            endcase
        end
    end
end

always_comb begin : STALL
    stall = 1'b0;
    mult_start = 1'b0;
    div_start = 1'b0;
    if (inst_decoder[STAGE_EX].opcode == rv32i_types::op_reg && inst_decoder[STAGE_EX].funct7 == 7'b0000001) begin
        unique case (inst_decoder[STAGE_EX].funct3) 
            rv32i_types::mul, mulhu: begin 
                mult_start = 1'b1;
            end
            rv32i_types::div, divu, rem, remu: begin 
                div_start = 1'b1;
            end

            default: ;
        endcase
    end

    if (inst_read & ~inst_resp) begin
        stall = 1'b1;
    end else if (data_read & ~data_resp) begin
        stall = 1'b1;
    end else if (data_write & ~data_resp) begin
        stall = 1'b1;
    end else if (mult_start & ~mult_done) begin
        stall = 1'b1;
    end else if (div_start & ~div_done) begin
        stall = 1'b1;
    end

end

always_comb begin : MEM_W
    // data_wdata = rs2_fwoutmux_out[STAGE_MEM]; 
    // data_mbe = 4'b1111;
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
            // data_addr = {alu_out[STAGE_EX][31:2], 2'b00};
            data_wdata = rs2_fwoutmux_out[STAGE_MEM]; // rs2_out[STAGE_MEM];
            data_mbe = 4'b1111;
        end
        // default: ;
    endcase
end


always_comb begin : INST
// always_ff @(posedge clk) begin


    inst[STAGE_ID] = inst_rdata;
    inst_control[STAGE_ID] = ctrl;
    id_ex_decoder_word = inst_decoder[STAGE_ID];

    branch_taken = 1'b0;
    stall_ifid = 1'b0;
    flush = 1'b0;
    
    if (inst_decoder[STAGE_EX].rd != 5'd0) begin
        if (inst_decoder[STAGE_EX].opcode == rv32i_types::op_load &&
            (inst_decoder[STAGE_EX].rd == inst_decoder[STAGE_ID].rs1 || inst_decoder[STAGE_EX].rd == inst_decoder[STAGE_ID].rs2)) begin
			stall_ifid = 1'b1;

            id_ex_decoder_word.rs1 = 0;
            id_ex_decoder_word.rs2 = 0;
            id_ex_decoder_word.rd = 0;
            id_ex_decoder_word.opcode = op_imm;

            inst_control[STAGE_ID].load_regfile = 1'b0; 
            // inst_control[STAGE_ID].opcode = rv32i_types::op_imm;
        end
    end

    // if btb predicts a hit, immediately reflect the next predicted address
    // if (btb_hit[STAGE_IF]) begin
    //     pcmux_out = btb_predict_address[STAGE_IF];
    // end 
    
    unique case (inst_decoder[STAGE_EX].opcode)
        op_br: begin
            pcmux_out = (br_en[STAGE_EX] ? alu_ex_out : pc_out[STAGE_IF] + 4);
            branch_taken = br_en[STAGE_EX];

            // $display("brach op at %t", $time);
        end
        op_jal:  begin
            pcmux_out = alu_ex_out;
            branch_taken = 1'b1;
            // $display("op_jal op at %t", $time);
        end
        op_jalr: begin
            pcmux_out = {alu_ex_out[31:1], 1'b0};
            branch_taken = 1'b1;
            // $display("op_jalr op at %t", $time);
        end
        default: pcmux_out = pc_out[STAGE_IF] + 4;
    endcase


    if (btb_hit[STAGE_EX]) begin
        if (branch_taken) begin
            if (pcmux_out == btb_predict_address[STAGE_EX]) begin
                pcmux_out = pc_out[STAGE_IF] + 4;

                if (btb_hit[STAGE_IF]) begin
                    pcmux_out = btb_predict_address[STAGE_IF];
                end 
            end else begin
                // predict wrong address
                inst[STAGE_ID] = 32'h00000013; 
                inst_control[STAGE_ID].load_regfile = 1'b0; 

                id_ex_decoder_word.rs1 = 0;
                id_ex_decoder_word.rs2 = 0;
                id_ex_decoder_word.rd = 0;
                id_ex_decoder_word.opcode = op_imm;

                flush = 1'b1;

                // pcmux_out = pc_out[STAGE_EX] + 4;
            end
        end else begin
            inst[STAGE_ID] = 32'h00000013; 
            inst_control[STAGE_ID].load_regfile = 1'b0; 

            id_ex_decoder_word.rs1 = 0;
            id_ex_decoder_word.rs2 = 0;
            id_ex_decoder_word.rd = 0;
            id_ex_decoder_word.opcode = op_imm;

            flush = 1'b1;

            pcmux_out = pc_out[STAGE_EX] + 4;
        end
    end else begin
        if (branch_taken) begin
            // Not hit but a branch was taken
            inst[STAGE_ID] = 32'h00000013; 
            inst_control[STAGE_ID].load_regfile = 1'b0; 

            id_ex_decoder_word.rs1 = 0;
            id_ex_decoder_word.rs2 = 0;
            id_ex_decoder_word.rd = 0;
            id_ex_decoder_word.opcode = op_imm;
            flush = 1'b1;

        end else begin
            if (btb_hit[STAGE_IF]) begin
                pcmux_out = btb_predict_address[STAGE_IF];
            end 
        end
    end

    // Sometimes the register values are nevered used and should not be forwarded
    unique case (id_ex_decoder_word.opcode)
        op_br: id_ex_decoder_word.rd = 0;
        default: ;
    endcase
end

always_comb begin : ALUMUXSEL
    alu_out[STAGE_EX] = alu_ex_out;
    if (inst_decoder[STAGE_EX].opcode == rv32i_types::op_reg && inst_decoder[STAGE_EX].funct7 == 7'b0000001) begin
        unique case (inst_decoder[STAGE_EX].funct3) 
            rv32i_types::mul: begin 
                // $display("mul at %0t\n", $time);
                // $display("mul %d * %d = %d", alumux1_out, alumux2_out, mult_out);
                alu_out[STAGE_EX] = mult_out[31:0];
            end
            rv32i_types::div, rv32i_types::divu: begin 
                // $display("div %d %d at %0t\n", alumux1_out, alumux2_out, $time);
                // $display("div at %0t\n", $time);
                alu_out[STAGE_EX] = quotient;
            end
            rv32i_types::rem: begin 
                // $display("rem %d %d at %0t\n", alumux1_out, alumux2_out, $time);
                alu_out[STAGE_EX] = remainder;
            end
            rv32i_types::remu: begin 
                // $display("remu %d %d at %0t\n", alumux1_out, alumux2_out, $time);
                alu_out[STAGE_EX] = remainder;
            end
            rv32i_types::mulhu: begin 
                // $display("mulhu %d * %d = %d", alumux1_out, alumux2_out, mult_out);
                // $display("mulh at %0t\n", $time);
                alu_out[STAGE_EX] = mult_out[63:32];
            end
            default: alu_out[STAGE_EX] = alu_ex_out;
        endcase
    end

end

always_comb begin : MUXES
    unique case (inst_control[STAGE_EX].cmpmux_sel)
        cmpmux::rs2_out: cpmmux_out = rs2_fwoutmux_out[STAGE_EX]; //rs2_out[STAGE_EX];
        cmpmux::i_imm: cpmmux_out = inst_decoder[STAGE_EX].i_imm;
        default: $display("Unexpected cmpmux_sel %d at %0t\n", inst_control[STAGE_EX].cmpmux_sel, $time);
    endcase


    unique case (inst_control[STAGE_EX].alumux1_sel)
        alumux::rs1_out: alumux1_out = rs1_fwoutmux_out; //rs1_out[STAGE_EX];
        alumux::pc_out: alumux1_out = pc_out[STAGE_EX];
    endcase

    unique case (inst_control[STAGE_EX].alumux2_sel)
        alumux::i_imm: alumux2_out = inst_decoder[STAGE_EX].i_imm;
        alumux::s_imm: alumux2_out = inst_decoder[STAGE_EX].s_imm;
        alumux::b_imm: alumux2_out = inst_decoder[STAGE_EX].b_imm;
        alumux::u_imm: alumux2_out = inst_decoder[STAGE_EX].u_imm;
        alumux::j_imm: alumux2_out = inst_decoder[STAGE_EX].j_imm;
        alumux::rs2_out: alumux2_out = rs2_fwoutmux_out[STAGE_EX]; //rs2_out[STAGE_EX];
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