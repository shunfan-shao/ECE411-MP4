/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

// tag[24] index[3] offset[5]
`define BAD_CTRL_VAL $fatal("%0t %s %0d: Bad control value", $time, `__FILE__, `__LINE__)

module cache_datapath #(
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
    
    output logic lru,
    output logic [1:0] hit_bits,
    output logic [1:0] valids,
    output logic [1:0] dirtys,

    input logic next_lru,
    input logic [1:0] next_dirty_bits,

    input logic load_way,
    input logic load_dirty,
    
    input logic load_way_sel,
    input logic ba_data_sel,
    input logic pmem_addr_sel,
    input logic data_in_sel,
    input logic [1:0] load_data_sel,

    input logic [31:0] mem_address,
    output logic [31:0] pmem_address,
    input logic [255:0] pmem_rdata,
    output logic [255:0] pmem_wdata,
    output logic [255:0] ba_mem_rdata256,
    input logic [255:0] ba_mem_wdata256,
    input logic [31:0] ba_mem_byte_enable256
);

logic [num_sets-1:0] lru_bits;
logic [1:0][num_sets-1:0] valid_bits;
logic [1:0][num_sets-1:0] dirty_bits;
logic [num_sets-1:0][s_tag-1:0] tag_bits [1:0];

logic [1:0][s_mask-1:0] write_en;
logic [s_mask-1:0] next_write_en;

logic [s_line-1:0] datain;
logic [1:0][s_line-1:0] dataout;

logic [s_index-1:0] addr_index;
logic [s_tag-1:0] addr_tag;

assign addr_index = mem_address[7:5];
assign addr_tag = mem_address[31:8];
assign lru = lru_bits[addr_index];
assign valids = {valid_bits[1][addr_index], valid_bits[0][addr_index]};
assign dirtys = {dirty_bits[1][addr_index], dirty_bits[0][addr_index]};
assign hit_bits[0] = valids[0] & (addr_tag == tag_bits[0][addr_index]);
assign hit_bits[1] = valids[1] & (addr_tag == tag_bits[1][addr_index]);

assign pmem_wdata = dataout[~lru];

data_array #(.s_offset(s_offset), .s_index(s_index))
data_bits_0(
    .clk(clk),
    .read(1'b1),
    .write_en(write_en[0]),
    .rindex(addr_index),
    .windex(addr_index),
    .datain(datain),
    .dataout(dataout[0])
);

data_array #(.s_offset(s_offset), .s_index(s_index))
data_bits_1(
    .clk(clk),
    .read(1'b1),
    .write_en(write_en[1]),
    .rindex(addr_index),
    .windex(addr_index),
    .datain(datain),
    .dataout(dataout[1])
);

always_ff @(posedge clk) begin
    if (rst) begin
        tag_bits[0] <= 0;
        tag_bits[1] <= 0;
        valid_bits[0] <= 0;
        valid_bits[1] <= 0;
        dirty_bits[0] <= 0;
        dirty_bits[1] <= 0;
        lru_bits <= 0;
    end else begin
        lru_bits[addr_index] <= next_lru;
        if (load_way) begin
            valid_bits[load_way_sel][addr_index] <= 1'b1;
            tag_bits[load_way_sel][addr_index] <= addr_tag;
        end

        if (load_dirty) begin
            dirty_bits[0][addr_index] <= next_dirty_bits[0];
            dirty_bits[1][addr_index] <= next_dirty_bits[1];
        end
    end
end

always_comb begin
    unique case (ba_data_sel)
        cache_types::data: ba_mem_rdata256 = dataout[next_lru];
        cache_types::pmem: ba_mem_rdata256 = pmem_rdata;
    endcase

    unique case (load_data_sel) 
        cache_types::noload: begin 
            next_write_en = 32'd0;
        end
        cache_types::loadall: begin
            next_write_en = {32{1'b1}};
        end
        cache_types::loaden: begin  
            next_write_en = ba_mem_byte_enable256;
        end
    endcase

    unique case (load_way_sel)
        1'b0: begin
            write_en[0] = next_write_en;
            write_en[1] = 32'd0;
        end
        1'b1: begin
            write_en[0] = 32'd0;
            write_en[1] = next_write_en;
        end
    endcase

    unique case (data_in_sel)
        cache_types::rdata: begin
            datain = pmem_rdata;
        end
        cache_types::wdata: begin
            datain = ba_mem_wdata256;
        end
    endcase

    unique case (pmem_addr_sel)
        cache_types::raddr: pmem_address = {mem_address[31:5], 5'd0};
        cache_types::waddr: pmem_address = {tag_bits[~lru][addr_index], addr_index, 5'd0};
    endcase
end


endmodule : cache_datapath
