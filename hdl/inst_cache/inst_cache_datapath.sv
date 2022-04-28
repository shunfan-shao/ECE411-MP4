module inst_cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,
    
    // input logic load_valid_0,
    // input logic load_valid_1,
    // input logic load_tag_0,
    // input logic load_tag_1,
    input logic load_way,
    input logic [1:0] load_way_sel,
    input logic load_prefetch,

    output logic [2:0] lru_array,
    input logic [2:0] next_lru_array,

    // output logic lru,
    // input logic next_lru,

    output logic [3:0] hits,
    // output logic hit_0, // 
    // output logic hit_1, //

    output logic prefetch,
    output logic [31:0] prefetch_address,
    input logic prefetch_ready,


    input logic [31:0] mem_address,
    output logic [31:0] pmem_address, //
    input logic [255:0] pmem_rdata,
    output logic [31:0] mem_rdata // port to cpu
);

// logic [num_sets-1:0] valid_0_bits;
// logic [num_sets-1:0] valid_1_bits;
// logic [num_sets-1:0] valid_2_bits;
// logic [num_sets-1:0] valid_3_bits;
logic [num_sets-1:0] valid_bits [3:0];
// logic [num_sets-1:0][s_tag-1:0] tag_0_bits;
// logic [num_sets-1:0][s_tag-1:0] tag_1_bits;
// logic [num_sets-1:0][s_tag-1:0] tag_2_bits;
// logic [num_sets-1:0][s_tag-1:0] tag_3_bits;
logic [num_sets-1:0][s_tag-1:0] tag_bits [3:0];
// logic [num_sets-1:0][s_line-1:0] data_0_bits;
// logic [num_sets-1:0][s_line-1:0] data_1_bits;
// logic [num_sets-1:0][s_line-1:0] data_2_bits;
// logic [num_sets-1:0][s_line-1:0] data_3_bits;
logic [num_sets-1:0][s_line-1:0] data_bits [3:0];
logic [num_sets-1:0][2:0] lru_bits;

logic [s_index-1:0] addr_index, p_addr_index;
logic [s_tag-1:0] addr_tag, p_addr_tag;

logic [255:0] data_out;
// logic [3:0] hits;
logic [31:0] last_prefetch_address;


assign p_addr_index = prefetch_address[7:5];
assign p_addr_tag = prefetch_address[31:8];

// assign valid_0 = valid_0_bits[addr_index];
// assign valid_1 = valid_1_bits[addr_index];
// assign valid_2 = valid_2_bits[addr_index];
// assign valid_3 = valid_3_bits[addr_index];
assign valid_0 = valid_bits[0][addr_index];
assign valid_1 = valid_bits[1][addr_index];
assign valid_2 = valid_bits[2][addr_index];
assign valid_3 = valid_bits[3][addr_index];
// assign hit_array[0] = valid_0 & ((addr_tag == tag_0_bits[addr_index]) ? 1'b1 : 1'b0);
// assign hit_array[1] = valid_1 & ((addr_tag == tag_1_bits[addr_index]) ? 1'b1 : 1'b0);
// assign hit_array[2] = valid_2 & ((addr_tag == tag_2_bits[addr_index]) ? 1'b1 : 1'b0);
// assign hit_array[3] = valid_3 & ((addr_tag == tag_3_bits[addr_index]) ? 1'b1 : 1'b0);
assign hits[0] = valid_0 & ((addr_tag == tag_bits[0][addr_index]) ? 1'b1 : 1'b0);
assign hits[1] = valid_1 & ((addr_tag == tag_bits[1][addr_index]) ? 1'b1 : 1'b0);
assign hits[2] = valid_2 & ((addr_tag == tag_bits[2][addr_index]) ? 1'b1 : 1'b0);
assign hits[3] = valid_3 & ((addr_tag == tag_bits[3][addr_index]) ? 1'b1 : 1'b0);
assign lru_array = lru_bits[addr_index];


logic [3:0] phits;

always_ff @(posedge clk) begin
    if (rst) begin
        valid_bits[0] <= 0;
        valid_bits[1] <= 0;
        valid_bits[2] <= 0;
        valid_bits[3] <= 0;
        // valid_1_bits <= 0;
        // valid_2_bits <= 0;
        // valid_3_bits <= 0;
        lru_bits <= 0;
    end else begin
        lru_bits[addr_index] <= next_lru_array;
        if (load_way) begin
            valid_bits[load_way_sel][addr_index] <= 1'b1;
            tag_bits[load_way_sel][addr_index] <= addr_tag;
            data_bits[load_way_sel][addr_index] <= pmem_rdata;
        end
        // if (load_way[0]) begin
        //     valid_0_bits[addr_index] <= 1'b1;
        //     tag_0_bits[addr_index] <= addr_tag;
        //     data_0_bits[addr_index] <= pmem_rdata;
        // end
        // else if (load_way[1]) begin
        //     valid_1_bits[addr_index] <= 1'b1;
        //     tag_1_bits[addr_index] <= addr_tag;
        //     data_1_bits[addr_index] <= pmem_rdata;
        // end
        // else if (load_way[2]) begin
        //     valid_2_bits[addr_index] <= 1'b1;
        //     tag_2_bits[addr_index] <= addr_tag;
        //     data_2_bits[addr_index] <= pmem_rdata;
        // end
        // else if (load_way[3]) begin
        //     valid_3_bits[addr_index] <= 1'b1;
        //     tag_3_bits[addr_index] <= addr_tag;
        //     data_3_bits[addr_index] <= pmem_rdata;
        // end
        last_prefetch_address <= prefetch_address;
    end
end

always_comb begin : prefetch_load
    if (~prefetch_ready) begin
        addr_index = mem_address[7:5];
        addr_tag = mem_address[31:8];
    end else begin
        addr_index = last_prefetch_address[7:5];
        addr_tag = last_prefetch_address[31:8];
    end

end

always_comb begin : prefetch_logistics
    pmem_address = {mem_address[31:5], 5'd0};

    if (load_way | prefetch_ready) begin
        prefetch_address = pmem_address + 32;
    end
    phits[0] = valid_bits[0][p_addr_index] & ((p_addr_tag == tag_bits[0][p_addr_index]) ? 1'b1 : 1'b0);
    phits[1] = valid_bits[1][p_addr_index] & ((p_addr_tag == tag_bits[1][p_addr_index]) ? 1'b1 : 1'b0);
    phits[2] = valid_bits[2][p_addr_index] & ((p_addr_tag == tag_bits[2][p_addr_index]) ? 1'b1 : 1'b0);
    phits[3] = valid_bits[3][p_addr_index] & ((p_addr_tag == tag_bits[3][p_addr_index]) ? 1'b1 : 1'b0);
    if (phits == 4'b0000) begin
        prefetch = 1'b1;
    end

end

always_comb begin
    // hit_way = 2'b00;
    // if (hits[0] == 1'b1) begin
    //     hit_way = 2'b00;
    // end
    // if (hits[1] == 1'b1) begin
    //     hit_way = 2'b01;
    // end
    // if (hits[2] == 1'b1) begin
    //     hit_way = 2'b10;
    // end
    // if (hits[3] == 1'b1) begin
    //     hit_way = 2'b11 ;
    // end
    // if (hits == 4'b0000) hit = 1'b0;
    // unique case (hits) 
    //     4'b0001: begin
    //         hit_way = 2'b11;
    //     end
    //     4'b0010: begin
    //         hit_way = 2'b10;
    //     end
    //     4'b0100: begin
    //         hit_way = 2'b01;
    //     end
    //     4'b1000: begin
    //         hit_way = 2'b00;
    //     end
    //     default: hit = 1'b0;
    // endcase
    if (hits != 4'b0000) begin
        if (hits[0]) data_out = data_bits[0][addr_index];
        else if (hits[1]) data_out = data_bits[1][addr_index];
        else if (hits[2]) data_out = data_bits[2][addr_index];
        else if (hits[3]) data_out = data_bits[3][addr_index];
        else data_out = pmem_rdata;
    end else begin
        data_out = pmem_rdata;
        // if (hit_array[0]) data_out = data_bits[0][addr_index];
        // else if (hit_array[1]) data_out = data_bits[1][addr_index];
        // else if (hit_array[2]) data_out = data_bits[2][addr_index];
        // else if (hit_array[3]) data_out = data_bits[3][addr_index];
    end
    mem_rdata = data_out[(32*mem_address[4:2]) +: 32]; 
end

endmodule : inst_cache_datapath
