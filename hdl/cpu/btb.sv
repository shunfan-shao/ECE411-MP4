// import rv32i_types::*;

// module btb #(
//     parameter pc_width = 32,
//     parameter buffer_width = 8
// )
// (
//     input clk,

//     input logic load,

//     input logic[pc_width-1:0] pc_if,
//     input logic[pc_width-1:0] pc_ex,
    
//     input logic br_en,
//     input rv32i_word jump_address,

//     output logic hit,
//     output rv32i_word predict_address
// );

// int _tail = 0;

// logic [pc_width-1:0] pc_buffer [buffer_width-1:0];
// rv32i_word predict_pc_buffer [buffer_width-1:0];

// always_ff @(posedge clk)
// begin
//     if (br_en) begin
//         if (_tail >= buffer_width) begin
//             _tail = 0;
//         end
        
//         // only store address when branch is actually taken, otherwise just fall through
//         // if (br_en) begin
//         pc_buffer[_tail] = pc_ex;
//         predict_pc_buffer[_tail] = jump_address;
//         _tail += 1;
//         // end
//     end
// end

// always_comb begin
//     hit = 1'b0;
//     predict_address = 32'd0;
//     for (int i=0; i<buffer_width; ++i) begin
//         if (pc_buffer[i] == pc_if) begin
//             hit = 1'b1;
//             predict_address = predict_pc_buffer[i];
//             break;
//         end
//     end
// end

// endmodule : btb

import rv32i_types::*;

module btb #(
    parameter s_index = 5,
    parameter s_tag = 12,
    parameter s_buffer = 2 ** s_index,
    parameter s_ras = 32
)
(
    input clk,
    input rst,
    input stall,

    input logic br_en,

    input rv32i_decoder_word ex_decoder,

    input logic[31:0] pc_ex,
    input logic[31:0] target_address,

    input logic[31:0] pc_if,
    output logic hit,
    output logic[31:0] predict_address
);
logic [s_tag-1:0] pc_if_tag, pc_ex_tag;
logic [s_index-1:0] pc_if_index, pc_ex_index;

assign pc_if_index = pc_if[s_index-1+2:2];
assign pc_ex_index = pc_ex[s_index-1+2:2];
assign pc_if_tag = pc_if[s_tag-1+s_index+2:s_index+2];
assign pc_ex_tag = pc_ex[s_tag-1+s_index+2:s_index+2];

rv32i_word ras[s_ras-1:0];
int ras_ptr;
assign is_ret = (ex_decoder.opcode == op_jalr && ex_decoder.rd == 5'b00000);

always_ff @(posedge clk)
begin
	if (rst) begin
		ras_ptr <= 0;
		ras[0] <= 0;
	end else begin
        if (~stall & ex_decoder.opcode == op_jalr) begin
            unique case (ex_decoder.rd) 
                5'b00001: begin
                    // call
                    ras[ras_ptr] <= pc_ex + 4;
                    ras_ptr <= ras_ptr + 1;
                end
                5'b00000: begin
                    // ret
                    ras_ptr <= ras_ptr - 1;
                end
            endcase
        end 
	end
end

logic [s_buffer-1:0][s_tag-1:0] ret_tag;
logic [s_buffer-1:0] ret_valid;

// always_ff @(posedge clk) begin
//     if (rst) begin
//         ret_valid <= 0;
//     end else begin
//         if (is_ret) begin
//             ret_valid[pc_ex_index] = 1'b1;
//             ret_tag[pc_ex_index] = pc_ex_tag;
//         end
//     end
// end

logic [s_buffer-1:0][s_tag-1:0] tag;
logic [s_buffer-1:0] valid;
logic [s_buffer-1:0][31:0] predicted_pc;


always_ff @(posedge clk) begin
    if (rst) begin
        valid <= 0;
        ret_valid <= 0;
    end else begin
        if (is_ret) begin
            ret_valid[pc_ex_index] = 1'b1;
            ret_tag[pc_ex_index] = pc_ex_tag;
        end
        else if (br_en) begin
            // If branch taken at ex stage
            valid[pc_ex_index] = 1'b1;
            predicted_pc[pc_ex_index] = target_address;
            tag[pc_ex_index] = pc_ex_tag;
        end 
    end
end

always_comb begin
    hit = 1'b0;
    predict_address = 32'd0;
    if (ret_valid[pc_if_index] && ret_tag[pc_if_index] == pc_if_tag) begin
        hit = 1'b1;
        predict_address = ras[ras_ptr - 1];
    end else if (valid[pc_if_index] && tag[pc_if_index] == pc_if_tag) begin
        hit = 1'b1;
        predict_address = predicted_pc[pc_if_index];
    end
end

endmodule : btb
