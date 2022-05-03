/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */
`define BAD_CTRL_VAL $fatal("%0t %s %0d: Bad control value", $time, `__FILE__, `__LINE__)

module cache_control
(
    input clk, 
    input rst,

    input mem_read,
    input mem_write,

    input logic lru,
    input logic [1:0] valids,
    input logic [1:0] hit_bits,
    input logic [1:0] dirtys,

    output logic next_lru,
    output logic [1:0] next_dirty_bits,


    output logic load_way,
    output logic load_dirty,

    output logic load_way_sel,
    output logic data_in_sel,
    output logic pmem_addr_sel,
    output logic ba_data_sel,
    output logic [1:0] load_data_sel,

    output logic mem_resp,
    input  logic pmem_resp,
    output logic pmem_read,
    output logic pmem_write
);

logic hit, hit_way;

enum int unsigned {
    check_hit,
    read_mem,
    refill,
    evict
} state, next_state;

function automatic void set_defaults();
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    mem_resp = 1'b0;

    next_lru = lru;
    next_dirty_bits = dirtys;

    load_dirty = 1'b0;

    load_way = 1'b0;
    load_way_sel = 1'b0;
    data_in_sel = cache_types::rdata;
    pmem_addr_sel = cache_types::raddr;
    ba_data_sel = cache_types::data;
    load_data_sel = cache_types::noload;
endfunction

function void writeops();
    data_in_sel = cache_types::wdata;
    load_dirty = 1'b1;
    load_way_sel = hit_way;
    next_dirty_bits[hit_way] = 1'b1;
    load_data_sel = cache_types::loaden;
endfunction

always_comb begin
    hit = hit_bits != 2'b00;
    hit_way = hit_bits[0] ? 1'b0 : 1'b1;

    set_defaults();
    unique case (state)
        check_hit: begin
            if (mem_read | mem_write) begin
                if (hit) begin
                    mem_resp = 1'b1; 
                    ba_data_sel = cache_types::data;

                    next_lru = hit_way;

                    if (mem_write) begin
                        writeops();
                    end
                end 
            end 
        end
        read_mem: begin
            pmem_read = 1'b1;

            if (pmem_resp) begin
                if (mem_read) mem_resp = 1'b1;

                load_way = 1'b1;
                load_way_sel = ~lru;

                ba_data_sel = cache_types::pmem;
                load_data_sel = cache_types::loadall;
            end
        end
        evict: begin
            pmem_write = 1'b1;
            pmem_addr_sel = cache_types::waddr;

            load_dirty = 1'b1;
            next_dirty_bits[~lru] = 1'b0;
        end
        refill: begin
            mem_resp = 1'b1; 
            writeops();
        end 
        default: `BAD_CTRL_VAL;
    endcase

end

always_comb begin
        case (state)
            check_hit: begin
                if (mem_read | mem_write) begin
                    // if hit, stays check_hit
                    if (~hit) begin
                        if (valids[~lru] & dirtys[~lru]) begin
                            next_state = evict;
                        end else begin
                            next_state = read_mem;
                        end
                    end else begin
                        next_state = check_hit;
                    end
                end else begin
                    next_state = check_hit;
                end
            end
            read_mem: begin
                if (pmem_resp) begin
                    if (mem_read) next_state = check_hit;
                    else next_state = refill;
                end else begin
                    next_state = read_mem;
                end
            end
            refill: begin
                next_state = check_hit;
            end
            evict: begin
                // next_state = ready;
                if (pmem_resp) begin
                    next_state = read_mem;
                end else begin
                    // $display("at %t, evict to address", $time);
                    next_state = evict;
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
