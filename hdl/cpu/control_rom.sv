import rv32i_types::*;

module control_rom
(
    input rv32i_opcode opcode,
    input logic[2:0] funct3,
    input logic[6:0] funct7,
    /* ... other inputs ... */
    output rv32i_control_word ctrl
);

always_comb
begin
    /* Default assignments */
    ctrl.load_regfile = 1'b0;

    ctrl.pcmux_sel = pcmux::pc_plus4;
    ctrl.cmpmux_sel = cmpmux::rs2_out;
    /* ... other defaults ... */
    ctrl.cmpop = branch_funct3_t'(funct3);

    /* Assign control signals based on opcode */
    case(opcode)
        op_lui: begin
            ctrl.load_regfile = 1'b1;
            ctrl.regfilemux_sel = regfilemux::u_imm;
        end 
        op_auipc: begin
            ctrl.load_regfile = 1'b1;
            ctrl.regfilemux_sel = regfilemux::alu_out;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::u_imm;
            ctrl.aluop = alu_add;
        end
        op_jal: begin
            ctrl.load_regfile = 1'b1;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::j_imm;
            ctrl.aluop = alu_add;
        end
        op_jalr: begin
            ctrl.load_regfile = 1'b1;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::i_imm;
            ctrl.aluop = alu_add;
        end
        op_br: begin
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::b_imm;
            // ctrl.pcmux_sel = pcmux::alu_out;
            ctrl.aluop = alu_add;
        end
        op_load: begin
            ctrl.load_regfile = 1'b1;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::i_imm;

            unique case (funct3)
                rv32i_types::lw: begin
                    ctrl.regfilemux_sel = regfilemux::lw;
                end
                rv32i_types::lh: begin
                    ctrl.regfilemux_sel = regfilemux::lh;
                end
                rv32i_types::lhu: begin
                    ctrl.regfilemux_sel = regfilemux::lhu;
                end
                rv32i_types::lb: begin
                    ctrl.regfilemux_sel = regfilemux::lb;
                end
                rv32i_types::lbu: begin
                    ctrl.regfilemux_sel = regfilemux::lbu;
                end
            endcase
            // ctrl.regfilemux_sel = regfilemux::lw;

            ctrl.aluop = alu_add;
        end
        op_store: begin
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::s_imm;
            ctrl.aluop = alu_add;
        end
        op_imm: begin
            ctrl.load_regfile = 1'b1;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::i_imm;
            ctrl.regfilemux_sel = regfilemux::alu_out;

            unique case (funct3) 
                rv32i_types::slt: begin
                    ctrl.cmpop = rv32i_types::blt;
                    ctrl.regfilemux_sel = regfilemux::br_en;
                    ctrl.cmpmux_sel = cmpmux::i_imm;
                end
                rv32i_types::sltu: begin
                    ctrl.cmpop = rv32i_types::bltu;
                    ctrl.regfilemux_sel = regfilemux::br_en;
                    ctrl.cmpmux_sel = cmpmux::i_imm;
                end
                rv32i_types::sr: begin
                    if (funct7 == 7'b0100000) begin
                        ctrl.aluop = rv32i_types::alu_sra;
                    end else begin
                        ctrl.aluop = rv32i_types::alu_srl;
                    end
                end
                default: ctrl.aluop = alu_ops'(funct3);
            endcase
        end
        op_reg: begin
            ctrl.load_regfile = 1'b1;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::rs2_out;
            ctrl.aluop = alu_ops'(funct3);
            ctrl.regfilemux_sel = regfilemux::alu_out;
            if (funct3 == rv32i_types::add) begin 
                if (funct7 == 7'b0100000) begin
                    ctrl.aluop = rv32i_types::alu_sub;
                end
            end else if (funct3 == rv32i_types::sr) begin
                if (funct7 == 7'b0100000) begin
                    ctrl.aluop = rv32i_types::alu_sra;
                end
            end else if (funct3 == rv32i_types::slt) begin
                ctrl.cmpop = rv32i_types::blt;
                ctrl.regfilemux_sel = regfilemux::br_en;
                ctrl.cmpmux_sel = cmpmux::rs2_out;
            end else if (funct3 == rv32i_types::sltu) begin
                ctrl.cmpop = rv32i_types::bltu;
                ctrl.regfilemux_sel = regfilemux::br_en;
                ctrl.cmpmux_sel = cmpmux::rs2_out;
            end
        end 

        /* ... other opcodes ... */

        default: begin
            ctrl = 0;   /* Unknown opcode, set control word to zero */
            $display("current opcode %x at time %0t\n", opcode, $time);
        end
    endcase
end
endmodule : control_rom
