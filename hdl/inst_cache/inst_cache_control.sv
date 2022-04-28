module inst_cache_control
(
    input clk, 
    input rst,
    input readop,
    input writeop,

    // input logic hit_0,
    // input logic hit_1,
    // input logic lru,
    // output logic next_lru,
    input logic [3:0] hits,

    input logic [2:0] lru_array,
    output logic [2:0] next_lru_array, 

    // output logic load_lru,
    // output logic load_valid_0,
    // output logic load_valid_1,
    // output logic load_tag_0,
    // output logic load_tag_1,
    output logic load_way,
    output logic [1:0] load_way_sel,
    output logic load_prefetch,

    input logic prefetch_ready,
    output logic mem_resp,
    input  logic pmem_resp,
    output logic pmem_read
);

// logic hit;
// assign hit = hit_0 | hit_1;

enum int unsigned {
    check_hit,
    read_mem,
    pf_load
} state, next_state;

function automatic void set_defaults();
    pmem_read = 1'b0;
    mem_resp = 1'b0;

    // load_valid_0 = 1'b0;
    // load_valid_1 = 1'b0;

    // load_tag_0 = 1'b0;
    // load_tag_1 = 1'b0;

    next_lru_array = lru_array;

    load_way = 1'b0;
    load_way_sel = 2'b00;
endfunction

always_comb begin
    set_defaults();
    unique case (state)
        check_hit: begin
            if (~prefetch_ready) begin
                if (readop | writeop) begin
                    if (hits > 0) begin
                        mem_resp = 1'b1;

                        if (hits[0] == 1'b1) begin
                            next_lru_array[0] = 1'b1;
                            next_lru_array[1] = 1'b1;
                        end else if (hits[1] == 1'b1) begin
                            next_lru_array[0] = 1'b1;
                            next_lru_array[1] = 1'b0;
                        end else if (hits[2] == 1'b1) begin
                            next_lru_array[0] = 1'b0;
                            next_lru_array[2] = 1'b1;
                        end else if (hits[3] == 1'b1) begin
                            next_lru_array[0] = 1'b0;
                            next_lru_array[2] = 1'b0;
                        end 
                    end 
                end 
            end else begin
                load_way = 1'b1;
                next_lru_array[0] = ~lru_array[0];
                if (lru_array[0]) begin
                    next_lru_array[2] = ~lru_array[2];
                    load_way_sel = {1'b1, lru_array[2]};
                end else begin
                    next_lru_array[1] = ~lru_array[1];
                    load_way_sel = {1'b0, lru_array[1]};
                end
            end
        end
        read_mem: begin
            if (prefetch_ready) begin
                load_way = 1'b1;
                next_lru_array[0] = ~lru_array[0];
                if (lru_array[0]) begin
                    next_lru_array[2] = ~lru_array[2];
                    load_way_sel = {1'b1, lru_array[2]};
                end else begin
                    next_lru_array[1] = ~lru_array[1];
                    load_way_sel = {1'b0, lru_array[1]};
                end
            end else begin

                pmem_read = 1'b1;

                if (pmem_resp) begin
                    mem_resp = 1'b1;
                    load_way = 1'b1;
                    next_lru_array[0] = ~lru_array[0];
                    if (lru_array[0]) begin
                        next_lru_array[2] = ~lru_array[2];
                        load_way_sel = {1'b1, lru_array[2]};
                    end else begin
                        next_lru_array[1] = ~lru_array[1];
                        load_way_sel = {1'b0, lru_array[1]};
                    end
                end
            end
        end
        pf_load: begin
            load_way = 1'b1;
            next_lru_array[0] = ~lru_array[0];
            if (lru_array[0]) begin
                next_lru_array[2] = ~lru_array[2];
                load_way_sel = {1'b1, lru_array[2]};
            end else begin
                next_lru_array[1] = ~lru_array[1];
                load_way_sel = {1'b0, lru_array[1]};
            end
        end
    endcase
end

always_comb begin
    next_state = state;
    case (state)
        check_hit: begin
            if (prefetch_ready) next_state = check_hit;
            else if (readop | writeop) begin
                if (hits == 4'b0000) begin
                    next_state = read_mem;
                end
            end else begin
                next_state = check_hit;
            end
        end
        read_mem: begin
            if (prefetch_ready) begin
                next_state = check_hit;
            end else begin
                if (pmem_resp) begin
                    next_state = check_hit;
                end
            end 
        end
        pf_load: begin
            next_state = check_hit;
        end
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    if (rst) state <= check_hit;
    else state <= next_state;
end

endmodule : inst_cache_control
