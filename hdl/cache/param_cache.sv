/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module param_cache #(
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

logic lru;
logic next_lru;

logic [1:0] hit_bits;
logic [1:0] valids;

logic [1:0] dirtys;
logic [1:0] next_dirty_bits;

logic load_way;
logic load_dirty;
    
logic load_way_sel;
logic ba_data_sel;
logic pmem_addr_sel;
logic data_in_sel;
logic [1:0] load_data_sel;

logic [255:0] ba_mem_rdata256;
logic [255:0] ba_mem_wdata256;
logic [31:0] ba_mem_byte_enable256;

cache_control control(.*);

cache_datapath datapath(.*);

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
