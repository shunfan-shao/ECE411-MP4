/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module param_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index,
    parameter num_ways = 2
)
(
    input clk,
    input rst,

    /* CPU memory signals */
    input   logic [31:0]    mem_address,
    output  logic [31:0]    mem_rdata,
    input   logic [31:0]    mem_wdata,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic [3:0]     mem_byte_enable,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp
);

byte lru_idx;

logic [255:0] ba_mem_wdata256;
logic [255:0] ba_mem_rdata256;
logic [31:0] ba_mem_byte_enable256;

logic load_valid;

logic [num_ways-1:0] tag_load_bits;

logic [num_ways-1:0] hit_bits;
logic [num_ways-1:0] valid_bits;
logic [num_ways-1:0] next_valid_bits;


logic load_lru;

logic [num_ways-2:0] lru_bits;
logic [num_ways-2:0] next_lru_bits;

logic load_dirty;
logic [num_ways-1:0] dirty_bits;
logic [num_ways-1:0] next_dirty_bits;


logic ba_data_sel;

logic [1:0] load_data_sel [num_ways-1:0];


logic data_in_sel;
logic pmem_addr_sel;

cache_control #(.num_ways(num_ways)) control
(
    .clk(clk),
    .rst(rst),
    .readop(mem_read),
    .writeop(mem_write),

    .hit_bits(hit_bits),

    .lru_bits(lru_bits),
    .next_lru_bits(next_lru_bits),
    .lru_idx(lru_idx),

    .load_lru(load_lru),

    .valid_bits(valid_bits),
    .next_valid_bits(next_valid_bits),


    .load_valid(load_valid),
    .tag_load_bits(tag_load_bits),
    
    .load_data_sel(load_data_sel),

    .data_in_sel(data_in_sel),
    .load_dirty(load_dirty),
    .dirty_bits(dirty_bits),
    .next_dirty_bits(next_dirty_bits),
    .pmem_addr_sel(pmem_addr_sel),

    .ba_data_sel(ba_data_sel),

    .mem_resp(mem_resp),
    .pmem_resp(pmem_resp),
    .pmem_read(pmem_read),
    .pmem_write(pmem_write)
);

cache_datapath #(.num_ways(num_ways)) datapath
(
    .clk(clk),
    .rst(rst),
    .load_valid(load_valid),

    .load_lru(load_lru),
    .lru_bits(lru_bits),
    .next_lru_bits(next_lru_bits),
    .lru_idx(lru_idx),

    .load_data_sel(load_data_sel),

    .tag_load_bits(tag_load_bits),

    .mem_address(mem_address),

    .hit_bits(hit_bits),

    .valid_bits(valid_bits),
    .next_valid_bits(next_valid_bits),

    .data_in_sel(data_in_sel),
    .load_dirty(load_dirty),
    .next_dirty_bits(next_dirty_bits),
    .dirty_bits(dirty_bits),
    .pmem_addr_sel(pmem_addr_sel),

    .ba_data_sel(ba_data_sel),

    .pmem_address(pmem_address),
    .pmem_rdata(pmem_rdata),
    .pmem_wdata(pmem_wdata),
    .ba_mem_rdata256(ba_mem_rdata256),
    .ba_mem_wdata256(ba_mem_wdata256),
    .ba_mem_byte_enable256(ba_mem_byte_enable256)
);

bus_adapter bus_adapter
(
    ba_mem_wdata256, 
    ba_mem_rdata256,
    mem_wdata,
    mem_rdata,
    mem_byte_enable,
    ba_mem_byte_enable256,
    mem_address
);

endmodule : param_cache
