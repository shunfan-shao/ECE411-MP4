/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */
`define BAD_CTRL_VAL $fatal("%0t %s %0d: Bad control value", $time, `__FILE__, `__LINE__)

module cache_control
(
    input clk, 
    input rst,
    input readop,
    input writeop,

    input logic [1:0] hit_bits,

    input logic lru,
    output logic next_lru,

    input logic [1:0] valids,

    output logic load_valid,

    output logic [1:0] load_data_sel,
    
    output logic data_in_sel,
    output logic load_dirty,
    input logic [1:0] dirtys,
    output logic [1:0] next_dirty_bits,
    output logic pmem_addr_sel,

    output logic load_way,
    output logic load_way_sel,

    output logic ba_data_sel,

    output logic mem_resp,
    input  logic pmem_resp,
    output logic pmem_read,
    output logic pmem_write
);

enum int unsigned {
    check_hit,
    read_mem,
    refill,
    evict
} state, next_state;

function automatic void set_defaults();
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    load_valid = 1'b0;
    mem_resp = 1'b0;
    // next_lru = lru;
    ba_data_sel = cache_types::data;

    load_dirty = 1'b0;
    data_in_sel = 1'b0;

    load_data_sel = cache_types::noload;

    for (int i=0; i<2; ++i) begin
        next_dirty_bits[i] = dirtys[i];
    end

    // for (int i=0; i<1; ++i) begin
    //     next_lru[i] = lru[i];
    // end

    next_lru = lru;

    pmem_addr_sel = cache_types::raddr;

    load_way = 1'b0;
    load_way_sel = 1'b0;
endfunction


logic hit, hit_way;

always_comb begin
    hit = hit_bits != 2'b00;
    hit_way = hit_bits[0] ? 1'b0 : 1'b1;

    set_defaults();
    unique case (state)
        check_hit: begin
            if (readop | writeop) begin
                if (hit) begin
                    mem_resp = 1'b1; 
                    ba_data_sel = cache_types::data;

                    next_lru = hit_way;

                    if (writeop) begin
                        data_in_sel = 1'b1;
                        load_dirty = 1'b1;
                        load_way_sel = hit_way;
                        next_dirty_bits[hit_way] = 1'b1;
                        load_data_sel = cache_types::loaden;
                    end
                end 
            end 
        end
        read_mem: begin
            pmem_read = 1'b1;

            if (pmem_resp) begin
                if (readop) mem_resp = 1'b1;


                if (~valids[~lru]) begin
                    load_valid = 1'b1;
                end

                ba_data_sel = cache_types::pmem;

                load_data_sel = cache_types::loadall;

                load_way = 1'b1;
                load_way_sel = ~lru;
            end
        end
        evict: begin
            pmem_write = 1'b1;
            pmem_addr_sel = cache_types::waddr;

            // when evict, reset dirty/valid bits
            load_dirty = 1'b1;
            load_valid = 1'b1;
            
            next_dirty_bits[~lru] = 1'b0;
        end
        refill: begin
            mem_resp = 1'b1; 
            // $display("reflling processing at %0t", $time);
            data_in_sel = 1'b1;
            load_dirty = 1'b1;
            load_way_sel = hit_way;
            next_dirty_bits[hit_way] = 1'b1;
            load_data_sel = cache_types::loaden;
            // unique case (lru) 
            //     1'b0: load_data_sel[0] = cache_types::loaden;
            //     1'b1: load_data_sel[1] = cache_types::loaden;
            // endcase
        end 
        default: `BAD_CTRL_VAL;
    endcase

end

always_comb begin
    next_state = state;
    case (state)
        check_hit: begin
            if (readop | writeop) begin
                if (~hit) begin
                    if (valids[~lru] & dirtys[~lru]) begin
                        next_state = evict;
                    end else begin
                        next_state = read_mem;
                    end
                end 
            end 
        end
        read_mem: begin
            if (pmem_resp) begin
                if (readop) next_state = check_hit;
                else next_state = refill;
            end 
        end
        refill: begin
            next_state = check_hit;
        end
        evict: begin
            if (pmem_resp) begin
                next_state = read_mem;
            end 
        end
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    if (rst) state <= check_hit;
    else state <= next_state;
end

endmodule : cache_control
