import rv32i_types::*;

module btb #(
    parameter pc_width = 32,
    parameter buffer_width = 8
)
(
    input clk,

    input logic load,

    input logic[pc_width-1:0] current_pc,
    
    input logic br_en,
    input rv32i_word jump_address,

    output logic hit,
    output rv32i_word predict_address
);

int _tail = 0;

logic [pc_width-1:0] pc_buffer [buffer_width-1:0];
rv32i_word predict_pc_buffer [buffer_width-1:0];

always_ff @(posedge clk)
begin
    if (br_en) begin
        if (_tail >= buffer_width) begin
            _tail = 0;
        end
        
        // only store address when branch is actually taken, otherwise just fall through
        // if (br_en) begin
        pc_buffer[_tail] = current_pc;
        predict_pc_buffer[_tail] = jump_address;
        _tail += 1;
        // end
    end
end

endmodule : btb