module multicycle_multiplier(
    input clk,
    input rst,
    input logic [31:0] a, 
    input logic [31:0] b,
    output logic [63:0] product,

    input calc,
    output logic done
);

byte unsigned step, next_step;
logic [31:0] t32_3, t32_2, t32_1, t32_0;
logic [31:0] next_t32_3, next_t32_2, next_t32_1, next_t32_0;
logic [31:0] multiplicand; 
logic [31:0] multiplier;

task automatic half_adder(
    input a,
    input b,
    output r,
    output c
);
    begin
        r = a ^ b;
        c = a & b;
    end
endtask

task automatic full_adder(
    input x,
    input y,
    input z,
    output r,
    output c
);
    begin
        r = x ^ y ^ z;
        c = ((x ^ y) & z) | (x & y);
    end
endtask

task automatic wallace_tree_8bit(
    input [7:0] a, b,
    output logic [15:0] p
);

    logic [7:0] partial_product_0;
    logic [7:0] partial_product_1;
    logic [7:0] partial_product_2;
    logic [7:0] partial_product_3;
    logic [7:0] partial_product_4;
    logic [7:0] partial_product_5;
    logic [7:0] partial_product_6;
    logic [7:0] partial_product_7;

    logic har1_0, hac1_0, har1_1, hac1_1, har1_2, hac1_2, har1_3, hac1_3; 

    logic far1_0, far1_1, far1_2, far1_3, far1_4, far1_5, 
        fac1_0, fac1_1, fac1_2, fac1_3, fac1_4, fac1_5;

    logic far1_6, far1_7, far1_8, far1_9, far1_a, far1_b, 
        fac1_6, fac1_7, fac1_8, fac1_9, fac1_a, fac1_b;

    logic har2_0, har2_1, har2_2,
        hac2_0, hac2_1, hac2_2;

    logic far2_0, far2_1, far2_2, far2_3, far2_4, far2_5, far2_6, 
        fac2_0, fac2_1, fac2_2, fac2_3, fac2_4, fac2_5, fac2_6;

    logic far2_7, far2_8, far2_9, far2_a, far2_b, far2_c, 
        fac2_7, fac2_8, fac2_9, fac2_a, fac2_b, fac2_c;
        
    logic har3_0, har3_1, har3_2, har3_3,
        hac3_0, hac3_1, hac3_2, hac3_3;

    logic far3_0, far3_1, far3_2, far3_3, far3_4, far3_5,
        fac3_0, fac3_1, fac3_2, fac3_3, fac3_4, fac3_5;

    logic har4_0, har4_1, har4_2, har4_3,
        hac4_0, hac4_1, hac4_2, hac4_3;

    logic far4_0, far4_1, far4_2, far4_3, far4_4, far4_5, far4_6,
        fac4_0, fac4_1, fac4_2, fac4_3, fac4_4, fac4_5, fac4_6;
    // logic [15:0] final_a;
    // logic [15:0] final_b;
    logic [15:0] carry;

    begin
        partial_product_0 = a & {8{b[0]}};
        partial_product_1 = a & {8{b[1]}};
        partial_product_2 = a & {8{b[2]}};
        partial_product_3 = a & {8{b[3]}};
        partial_product_4 = a & {8{b[4]}};
        partial_product_5 = a & {8{b[5]}};
        partial_product_6 = a & {8{b[6]}};
        partial_product_7 = a & {8{b[7]}};

        half_adder(partial_product_0[1], partial_product_1[0], har1_0, hac1_0);
        half_adder(partial_product_1[7], partial_product_2[6], har1_1, hac1_1);
        full_adder(partial_product_0[2], partial_product_1[1], partial_product_2[0], far1_0, fac1_0);
        full_adder(partial_product_0[3], partial_product_1[2], partial_product_2[1], far1_1, fac1_1);
        full_adder(partial_product_0[4], partial_product_1[3], partial_product_2[2], far1_2, fac1_2);
        full_adder(partial_product_0[5], partial_product_1[4], partial_product_2[3], far1_3, fac1_3);
        full_adder(partial_product_0[6], partial_product_1[5], partial_product_2[4], far1_4, fac1_4);
        full_adder(partial_product_0[7], partial_product_1[6], partial_product_2[5], far1_5, fac1_5);

        half_adder(partial_product_3[1], partial_product_4[0], har1_2, hac1_2);
        half_adder(partial_product_4[7], partial_product_5[6], har1_3, hac1_3);
        full_adder(partial_product_3[2], partial_product_4[1], partial_product_5[0], far1_6, fac1_6);
        full_adder(partial_product_3[3], partial_product_4[2], partial_product_5[1], far1_7, fac1_7);
        full_adder(partial_product_3[4], partial_product_4[3], partial_product_5[2], far1_8, fac1_8);
        full_adder(partial_product_3[5], partial_product_4[4], partial_product_5[3], far1_9, fac1_9);
        full_adder(partial_product_3[6], partial_product_4[5], partial_product_5[4], far1_a, fac1_a);
        full_adder(partial_product_3[7], partial_product_4[6], partial_product_5[5], far1_b, fac1_b);

        half_adder(far1_0, hac1_0, har2_0, hac2_0);
        full_adder(far1_1, fac1_0, partial_product_3[0], far2_0, fac2_0);
        full_adder(far1_2, fac1_1, har1_2, far2_1, fac2_1);
        full_adder(far1_3, fac1_2, far1_6, far2_2, fac2_2);
        full_adder (far1_4, fac1_3, far1_7, far2_3, fac2_3);
        full_adder (far1_5, fac1_4, far1_8, far2_4, fac2_4);
        full_adder (har1_1, fac1_5, far1_9, far2_5, fac2_5);
        full_adder (partial_product_2[7], hac1_1, far1_a, far2_6, fac2_6);

        half_adder (fac1_6, partial_product_6[0], har2_1, hac2_1);
        half_adder (partial_product_6[7], partial_product_7[6], har2_2, hac2_2);
        full_adder (fac1_7, partial_product_6[1], partial_product_7[0], far2_7, fac2_7);
        full_adder (fac1_8, partial_product_6[2], partial_product_7[1], far2_8, fac2_8);
        full_adder (fac1_9, partial_product_6[3], partial_product_7[2], far2_9, fac2_9);
        full_adder (fac1_a, partial_product_6[4], partial_product_7[3], far2_a, fac2_a);
        full_adder (fac1_b, partial_product_6[5], partial_product_7[4], far2_b, fac2_b);
        full_adder (hac1_3, partial_product_6[6], partial_product_7[5], far2_c, fac2_c);

        half_adder (far2_0, hac2_0, har3_0, hac3_0);
        half_adder (far2_1, fac2_0, har3_1, hac3_1);
        half_adder (har1_3, far2_b, har3_2, hac3_2);
        half_adder (partial_product_5[7], far2_c, har3_3, hac3_3);
        full_adder (far2_2, fac2_1, hac1_2, far3_0, fac3_0);
        full_adder (far2_3, fac2_2, har2_1, far3_1, fac3_1);
        full_adder (far2_4, fac2_3, far2_7, far3_2, fac3_2);
        full_adder (far2_5, fac2_4, far2_8, far3_3, fac3_3);
        full_adder (far2_6, fac2_5, far2_9, far3_4, fac3_4);
        full_adder (far1_b, fac2_6, far2_a, far3_5, fac3_5);

        half_adder (har3_1, hac3_0, har4_0, hac4_0);
        half_adder (far3_0, hac3_1, har4_1, hac4_1);
        half_adder (far3_1, fac3_0, har4_2, hac4_2);
        full_adder (far3_2, fac3_1, hac2_1, far4_0, fac4_0);
        full_adder (far3_3, fac3_2, fac2_7, far4_1, fac4_1);
        full_adder (far3_4, fac3_3, fac2_8, far4_2, fac4_2);
        full_adder (far3_5, fac3_4, fac2_9, far4_3, fac4_3);
        full_adder (har3_2, fac3_5, fac2_a, far4_4, fac4_4);
        full_adder (har3_3, hac3_2, fac2_b, far4_5, fac4_5);
        full_adder (har2_2, hac3_3, fac2_c, far4_6, fac4_6);
        half_adder (partial_product_7[7], hac2_2, har4_3, hac4_3);

        p[5:0] = {har4_0, har3_0, har2_0, har1_0, partial_product_0[0]};
        full_adder(hac4_0, har4_1, 1'b0, p[5], carry[5]);
        full_adder(hac4_1, har4_2, carry[5], p[6], carry[6]);
        full_adder(hac4_2, far4_0, carry[6], p[7], carry[7]);
        full_adder(fac4_0, far4_1, carry[7], p[8], carry[8]);
        full_adder(fac4_1, far4_2, carry[8], p[9], carry[9]);
        full_adder(fac4_2, far4_3, carry[9], p[10], carry[10]);
        full_adder(fac4_3, far4_4, carry[10], p[11], carry[11]);
        full_adder(fac4_4, far4_5, carry[11], p[12], carry[12]);
        full_adder(fac4_5, far4_6, carry[12], p[13], carry[13]);
        full_adder(fac4_6, har4_3, carry[13], p[14], carry[14]);
        full_adder(hac4_3, 1'b0, carry[14], p[15], carry[15]);
    end    
endtask

enum int unsigned {
    idle,
    w00,
    w01,
    w10,
    w11,
    addall
} state, next_state;

task automatic wallace_tree_16bit(
    input [15:0] a, b,
    output logic [31:0] p
);
    logic [15:0] t16_3, t16_2, t16_1, t16_0;
    begin
        wallace_tree_8bit(a[7:0] , b[7:0], t16_0);
        wallace_tree_8bit(a[7:0], b[15:8], t16_1);
        wallace_tree_8bit(a[15:8], b[7:0], t16_2);
        wallace_tree_8bit(a[15:8], b[15:8], t16_3);
        p = (t16_3 << 16) + (t16_2 << 8) + (t16_1 << 8) + t16_0;
    end
endtask

always_ff @(posedge clk) begin
    if (rst) begin
        state <= idle;
        t32_0 <= 0;
        t32_1 <= 0;
        t32_2 <= 0;
        t32_3 <= 0;
    end else begin
        state <= next_state;
        t32_0 <= next_t32_0;
        t32_1 <= next_t32_1;
        t32_2 <= next_t32_2;
        t32_3 <= next_t32_3;

        if (calc) begin
            multiplicand <= a;
            multiplier <= b;
        end
    end
end


always_comb begin
    next_state = state;
    case (state)
        idle: begin
            if (calc) begin
                next_state = w00;
            end else begin
                next_state = idle;
            end
        end
        w00: begin
            next_state = w01;
        end
        w01: begin
            next_state = w10;
        end
        w10: begin
            next_state = w11;
        end
        w11: begin
            next_state = addall;
        end
        addall: begin
            next_state = idle;
        end
    endcase
end

always_comb begin
    next_t32_0 = t32_0;
    next_t32_1 = t32_1;
    next_t32_2 = t32_2;
    next_t32_3 = t32_3;
    product = 0;
    done = 1'b0;
    unique case (state) 
        idle: begin
        end
        w00: begin
            wallace_tree_16bit(multiplicand[15:0], multiplier[15:0], next_t32_0);
        end
        w01: begin
            wallace_tree_16bit(multiplicand[15:0], multiplier[31:16], next_t32_1);
        end
        w10: begin
            wallace_tree_16bit(multiplicand[31:16], multiplier[15:0], next_t32_2);
        end
        w11: begin
            wallace_tree_16bit(multiplicand[31:16], multiplier[31:16], next_t32_3);
        end
        addall: begin
            product = (t32_3 << 32) + (t32_2 << 16) + (t32_1 << 16) + t32_0;
            done = 1'b1;
        end
    endcase

end
endmodule : multicycle_multiplier
