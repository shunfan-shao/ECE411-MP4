/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */
`define BAD_CTRL_VAL $fatal("%0t %s %0d: Bad control value", $time, `__FILE__, `__LINE__)

module cache_control #(
    parameter num_ways = 2
)
(
    input clk, 
    input rst,
    input readop,
    input writeop,

    input logic [num_ways-1:0] hit_bits,

    input logic [num_ways-2:0] lru_bits,
    output logic [num_ways-2:0] next_lru_bits,
    input byte lru_idx,
    output byte next_lru_idx,

    output logic load_lru,

    input logic [num_ways-1:0] valid_bits,
    output logic [num_ways-1:0] next_valid_bits,

    output logic load_valid,

    output logic [num_ways-1:0] tag_load_bits,

    output logic [1:0] load_data_sel [num_ways-1:0],
    
    output logic data_in_sel,
    output logic load_dirty,
    input logic [num_ways-1:0] dirty_bits,
    output logic [num_ways-1:0] next_dirty_bits,
    output logic pmem_addr_sel,

    output logic ba_data_sel,

    output logic mem_resp,
    input  logic pmem_resp,
    output logic pmem_read,
    output logic pmem_write
);

enum int unsigned {
    check_hit,
    read_mem,
    idle,
    rwop,
    memop,
    ready,
    refill,
    evict
} state, next_state;

function automatic void set_next_lru_bits(int touch_idx);
    for (int i=num_ways, last_idx = touch_idx + 1, curr_idx = (num_ways / 2 - 1) + touch_idx / 2; i>1; i/=2) begin
        next_lru_bits[curr_idx] = (last_idx - 1) % 2;
        last_idx = curr_idx;
        curr_idx = (curr_idx - 1) / 2;
    end
endfunction

function automatic void set_defaults();
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    load_valid = 1'b0;
    mem_resp = 1'b0;
    // next_lru = lru;
    load_lru = 1'b0;
    ba_data_sel = 1'b0;

    load_dirty = 1'b0;
    data_in_sel = 1'b0;

    for (int i=0; i<num_ways; ++i) begin
        load_data_sel[i] = cache_types::noload;
        tag_load_bits[i] = 1'b0;
        next_valid_bits[i] = valid_bits[i];
        next_dirty_bits[i] = dirty_bits[i];
    end

    for (int i=0; i<num_ways-1; ++i) begin
        next_lru_bits[i] = lru_bits[i];
    end

    // next_lru_idx = lru_idx;

    pmem_addr_sel = cache_types::raddr;
endfunction

assign is_memop = readop | writeop;
logic is_hit;
// lru is asserted when second set is most recently used data
// assign should_evict = lru ? (valid_bits[0] & dirty_bits[0]) : (valid_bits[1] & dirty_bits[1]);

byte hit_idx;
logic [$clog2(num_ways):0] least_recent_used_idx;

always_comb begin
    hit_idx = -1;
    is_hit = 1'b0;
    for (int i=0; i<num_ways; ++i) begin
        if (hit_bits[i]) begin
            hit_idx = i;
            is_hit = 1'b1;
            break;
        end
    end 

    least_recent_used_idx = 1;
    for (int i=num_ways, curr_idx=0; i>1; i/=2) begin
        // lru_bits[curr_idx] = ~next_lru_bits[curr_idx];
        least_recent_used_idx += (1 - lru_bits[curr_idx]) * (i / 2);
        curr_idx = (curr_idx + 1) * 2 - lru_bits[curr_idx];
    end
    least_recent_used_idx -= 1;


    set_defaults();
    unique case (state)
        check_hit: begin
            if (readop | writeop) begin
                if (is_hit) begin
                    mem_resp = 1'b1; 
                    load_lru = 1'b1;
                    ba_data_sel = 1'b0;

                    next_lru_idx = hit_idx;
                    set_next_lru_bits(next_lru_idx);

                    if (writeop) begin
                        data_in_sel = 1'b1;
                        load_dirty = 1'b1;
                        next_dirty_bits[next_lru_idx] = 1'b1;
                        load_data_sel[next_lru_idx] = cache_types::loaden;
                    end
                end 
            end 
        end
        read_mem: begin
            pmem_read = 1'b1;

            if (pmem_resp) begin
                if (readop) mem_resp = 1'b1;
                load_lru = 1'b1;

                // for (int i=0; i<num_ways; ++i) begin
                //     if (~valid_bits[i]) begin
                //         load_valid = 1'b1;
                //         next_valid_bits[i] = 1'b1;
                //         hit_idx = i;
                //         set_next_lru_bits(hit_idx);
                //         $display("at time %t setting bit %d to 1", $time, i);
                //         break;
                //     end
                // end

                if (hit_idx == -1) begin
                    hit_idx = 1;
                    for (int i=num_ways, curr_idx=0; i>1; i/=2) begin
                        // $display("%t current index[%d] = %d intial next %d(%d)", $time, i, curr_idx, next_lru_bits[curr_idx], lru_bits[curr_idx]);
                        next_lru_bits[curr_idx] = ~lru_bits[curr_idx];
                        hit_idx += next_lru_bits[curr_idx] * (i / 2);
                        curr_idx = (curr_idx + 1) * 2 - (1 - next_lru_bits[curr_idx]);
                    end
                    hit_idx -= 1;
                end 
                next_lru_idx = hit_idx;

                if (~valid_bits[hit_idx]) begin
                    load_valid = 1'b1;
                    next_valid_bits[hit_idx] = 1'b1;
                end
                // set_next_lru_bits(hit_idx);

                ba_data_sel = 1'b1;

                tag_load_bits[hit_idx] = 1'b1;
                load_data_sel[hit_idx] = cache_types::loadall;
            end
        end
        evict: begin
            pmem_write = 1'b1;
            pmem_addr_sel = cache_types::waddr;

            // when evict, reset dirty/valid bits
            load_dirty = 1'b1;
            load_valid = 1'b1;
            
            next_valid_bits[least_recent_used_idx] = 1'b0;
            next_dirty_bits[least_recent_used_idx] = 1'b0;
            // unique case (lru) 
            //     1'b0: begin
            //         next_valid_bits[1] = 1'b0;
            //         next_dirty_bits[1] = 1'b0;
            //     end
            //     1'b1: begin
            //         next_valid_bits[0] = 1'b0;
            //         next_dirty_bits[0] = 1'b0;
            //     end
            // endcase
        end
        memop: begin
            pmem_read = 1'b1;
        end
        rwop: begin
            /*rwop is necessary for valid/lru bit to be read correctly */
            
            if (is_hit) begin
                mem_resp = 1'b1; //CPU mem_resp
                load_lru = 1'b1;
                // load_valid = 1'b1; //TODO: remove temperorily, no need to laod valid ?
                // if (hit_bits[0]) begin
                //     next_lru = 1'b0;
                // end else begin
                //     next_lru = 1'b1;
                // end
                next_lru_idx = hit_idx;
                set_next_lru_bits(next_lru_idx);

                ba_data_sel = 1'b0;
            end else begin
                // need to recalculate next lru idx
            end
        end
        refill: begin
            mem_resp = 1'b1; 
            // $display("reflling processing at %0t", $time);
            data_in_sel = 1'b1;
            load_dirty = 1'b1;
            next_dirty_bits[next_lru_idx] = 1'b1;
            load_data_sel[next_lru_idx] = cache_types::loaden;
            // unique case (lru) 
            //     1'b0: load_data_sel[0] = cache_types::loaden;
            //     1'b1: load_data_sel[1] = cache_types::loaden;
            // endcase
        end 

        idle: ;
        default: `BAD_CTRL_VAL;
    endcase

end

always_comb begin
    // if (rst) begin
    //     next_state = idle;
    // end else begin
        case (state)
            check_hit: begin
                if (readop | writeop) begin
                    // if hit, stays check_hit
                    if (~is_hit) begin
                        if (valid_bits[least_recent_used_idx] & dirty_bits[least_recent_used_idx]) begin
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
                    if (readop) next_state = check_hit;
                    else next_state = refill;
                end else begin
                    next_state = read_mem;
                end
            end
            idle: begin
                if (is_memop) begin
                    // if (is_hit) begin
                    //     next_state = ready;
                    // end else begin
                    //     next_state = memop;
                    // end
                    next_state = rwop;
                end else begin
                    next_state = idle;
                end
            end
            rwop: begin
                if (is_hit) begin
                    if (writeop) begin
                        // write hit, refill
                        next_state = refill;
                    end else begin
                        next_state = idle;
                    end
                end else begin
                    // If new entry is valid and dirty, needs to evict data into memory 
                    if (valid_bits[least_recent_used_idx] & dirty_bits[least_recent_used_idx]) begin
                        next_state = evict;
                    end else begin
                        next_state = memop;
                    end
                end
            end
            memop: begin
                if (pmem_resp) begin
                    next_state = ready;
                end else begin
                    next_state = memop;
                end
            end
            ready: begin
                if (writeop) begin
                    // if write miss, data is ready, next step is to refill.
                    next_state = refill;
                end else begin
                    next_state = idle;
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
    // end 

end

always_ff @(posedge clk)
begin: next_state_assignment
    if (rst) state <= check_hit;
    else state <= next_state;
end

endmodule : cache_control
