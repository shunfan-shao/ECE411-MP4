/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module inst_cache #(
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

    /* CPU memory signals */
    input   logic [31:0]    mem_address,
    output  logic [31:0]    mem_rdata,
    input   logic           mem_read,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic           pmem_read,
    input   logic           pmem_resp
);

logic [3:0] hits;
logic load_way;
logic [1:0] load_way_sel;
logic [2:0] lru_array, next_lru_array;

inst_cache_control inst_control
(
    .clk(clk),
    .rst(rst),
    .readop(mem_read),
    .writeop(mem_write),

    .hits(hits),

    .lru_array(lru_array),
    .next_lru_array(next_lru_array),

    .load_way(load_way),    
    .load_way_sel(load_way_sel),

    .mem_resp(mem_resp),
    .pmem_resp(pmem_resp),
    .pmem_read(pmem_read)
);

inst_cache_datapath inst_datapath
(
    .clk(clk),
    .rst(rst),
    
    // .load_valid_0(load_valid_0),
    // .load_valid_1(load_valid_1),
    // .load_tag_0(load_tag_0),
    // .load_tag_1(load_tag_1),

    // .lru(lru),
    // .next_lru(next_lru),

    // .hit_0(hit_0),
    // .hit_1(hit_1),
    .load_way(load_way),    
    .load_way_sel(load_way_sel),

    .lru_array(lru_array),
    .next_lru_array(next_lru_array),
    
    .hits(hits),


    .mem_address(mem_address),
    .pmem_address(pmem_address),
    .pmem_rdata(pmem_rdata),
    .mem_rdata(mem_rdata)
);

endmodule : inst_cache
