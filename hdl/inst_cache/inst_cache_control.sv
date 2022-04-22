module inst_cache_control
(
    input clk, 
    input rst,
    input readop,
    input writeop,

    input logic hit_0,
    input logic hit_1,
    input logic lru,
    output logic next_lru,

    // output logic load_lru,
    output logic load_valid_0,
    output logic load_valid_1,
    output logic load_tag_0,
    output logic load_tag_1,

    output logic mem_resp,
    input  logic pmem_resp,
    output logic pmem_read
);

logic hit;
assign hit = hit_0 | hit_1;

enum int unsigned {
    check_hit,
    read_mem
} state, next_state;

function automatic void set_defaults();
    pmem_read = 1'b0;
    mem_resp = 1'b0;

    load_valid_0 = 1'b0;
    load_valid_1 = 1'b0;
    load_tag_0 = 1'b0;
    load_tag_1 = 1'b0;

    next_lru = lru;
endfunction

always_comb begin
    set_defaults();
    unique case (state)
        check_hit: begin
            if (readop | writeop) begin
                if (hit) begin
                    mem_resp = 1'b1;

                    next_lru = hit_0 ? 1'b1 : 1'b0;
                end 
            end 
        end
        read_mem: begin
            pmem_read = 1'b1;

            if (pmem_resp) begin
                mem_resp = 1'b1;
                unique case (lru) 
                    1'b0: begin
                        load_valid_0 = 1'b1;
                        load_tag_0 = 1'b1;

                    end
                    1'b1: begin
                        load_valid_1 = 1'b1;
                        load_tag_1 = 1'b1;
                    end
                endcase
                next_lru = ~lru;
            end
        end
    endcase
end

always_comb begin
    case (state)
        check_hit: begin
            if (readop | writeop) begin
                if (~hit) begin
                    next_state = read_mem;
                end
            end else begin
                next_state = check_hit;
            end
        end
        read_mem: begin
            if (pmem_resp) begin
                next_state = check_hit;
            end
        end
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    if (rst) state <= check_hit;
    else state <= next_state;
end

endmodule : inst_cache_control
