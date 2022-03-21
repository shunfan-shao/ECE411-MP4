import rv32i_types::*;

module cmp
(
    input branch_funct3_t cmpop,
    input rv32i_word a, b,
    output logic br_en
);

always_comb
begin
    unique case (cmpop)
        beq: br_en = (a == b);
        bne: br_en = (a != b);
        blt: br_en = ($signed(a) < $signed(b));
        bge: br_en = ($signed(a) >= $signed(b));
        bltu: br_en = (a < b);
        bgeu: br_en = (a >= b);
        default:;
    endcase
end

endmodule : cmp
