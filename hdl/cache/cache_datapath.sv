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
    parameter num_sets = 2**s_index,
    parameter num_ways = 2
)
(
    input clk,
    input rst,
    
    input load_valid,

    input logic load_lru,
    output logic [num_ways-2:0] lru_bits,
    input logic [num_ways-2:0] next_lru_bits,
    output byte lru_idx,
    input byte next_lru_idx,

    input logic [1:0] load_data_sel [num_ways-1:0],

    input logic [num_ways-1:0] tag_load_bits,

    input logic [31:0] mem_address,

    output logic [num_ways-1:0] hit_bits,

    output logic [num_ways-1:0] valid_bits,
    input logic [num_ways-1:0] next_valid_bits,


    input logic data_in_sel,
    input logic load_dirty,
    input logic [num_ways-1:0] next_dirty_bits,
    output logic [num_ways-1:0] dirty_bits,
    input logic pmem_addr_sel,

    input logic ba_data_sel,

    output logic [31:0] pmem_address,
    input logic [255:0] pmem_rdata,
    output logic [255:0] pmem_wdata,
    output logic [255:0] ba_mem_rdata256,
    input logic [255:0] ba_mem_wdata256,
    input logic [31:0] ba_mem_byte_enable256
);

logic [num_ways-1:0][s_tag-1:0] tag_out_bits;
logic [num_ways-1:0] tag_read_bits;

logic [s_index-1:0] addr_index;
logic [s_tag-1:0] addr_tag;

assign addr_index = mem_address[7:5];
assign addr_tag = mem_address[31:8];



array #(.s_index(s_index), .width(num_ways)) 
valid_bits_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid),
    .rindex(addr_index),
    .windex(addr_index),
    .datain(next_valid_bits),
    .dataout(valid_bits)
);

array #(.s_index(s_index), .width(num_ways))
dirty_bits_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty),
    .rindex(addr_index),
    .windex(addr_index),
    .datain(next_dirty_bits),
    .dataout(dirty_bits)

);

array #(.s_index(s_index), .width(num_ways-1))
lru_bits_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_lru),
    .rindex(addr_index),
    .windex(addr_index),
    .datain(next_lru_bits),
    .dataout(lru_bits)

);

// array #(.s_index(s_index), .width(2))
// lru_idx_array(
//     .clk(clk),
//     .rst(rst),
//     .read(1'b1),
//     .load(load_lru),
//     .rindex(addr_index),
//     .windex(addr_index),
//     .datain(next_lru_idx),
//     .dataout(lru_idx)

// );

// array #(.s_index(s_index), .width(1))
// lru_bits_array_old(
//     .clk(clk),
//     .rst(rst),
//     .read(1'b1),
//     .load(load_lru),
//     .rindex(addr_index),
//     .windex(addr_index),
//     .datain(next_lru),
//     .dataout(lru)
// );


param_array #(.s_index(s_index), .width(s_tag), .num_ways(num_ways))
tag_bits_array(
    .clk(clk),
    .rst(rst),
    .read(tag_read_bits),
    .load(tag_load_bits),
    .rindex(addr_index),
    .windex(addr_index),
    .datain(addr_tag),
    .dataout(tag_out_bits)
);


logic [num_ways-1:0] data_read_bits;
logic [num_ways-1:0][s_mask-1:0] write_en;
logic [num_ways-1:0][s_line-1:0] datain;
logic [num_ways-1:0][s_line-1:0] dataout;

param_data_array #(.s_offset(s_offset), .s_index(s_index), .num_ways(num_ways))
data_sets(
    .clk(clk),
    .read(data_read_bits),
    .write_en(write_en),
    .rindex(addr_index),
    .windex(addr_index),
    .datain(datain),
    .dataout(dataout)
);

byte tmp_next_lru_idx, least_recent_used_idx;


always_comb begin
    for (int i=0; i<num_ways; ++i) begin
        data_read_bits[i] = 1'b1;
        tag_read_bits[i] = 1'b1;
        hit_bits[i] = valid_bits[i] & (addr_tag == tag_out_bits[i]);
    end

    lru_idx = 1;
    for (int i=1, curr_idx=0; i<num_ways; i*=2) begin
        lru_idx += next_lru_bits[curr_idx] * (i / 2);
        curr_idx = (curr_idx + 1) * 2 - (1 - next_lru_bits[curr_idx]);
    end
    lru_idx -= 1;


    least_recent_used_idx = 1;
    for (int i=num_ways, curr_idx=0; i>1; i/=2) begin
        // lru_bits[curr_idx] = ~next_lru_bits[curr_idx];
        least_recent_used_idx += (1 - lru_bits[curr_idx]) * (i / 2);
        curr_idx = (curr_idx + 1) * 2 - lru_bits[curr_idx];
    end
    least_recent_used_idx -= 1;


    pmem_wdata = dataout[least_recent_used_idx];

end


always_comb begin
    tmp_next_lru_idx = 1;
    for (int i=num_ways, curr_idx=0; i>1; i/=2) begin
        tmp_next_lru_idx += next_lru_bits[curr_idx] * (i / 2);
        curr_idx = (curr_idx + 1) * 2 - (1 - next_lru_bits[curr_idx]);
    end
    tmp_next_lru_idx -= 1;
      unique case (ba_data_sel)
            1'b0: begin
                ba_mem_rdata256 = dataout[tmp_next_lru_idx];
            end
            1'b1: ba_mem_rdata256 = pmem_rdata;
            default: ;
      endcase

      for (int i=0; i<num_ways; ++i) begin
            unique case (load_data_sel[i])
                cache_types::noload: begin 
                    write_en[i] = 32'd0;
                    // load_set_1 = 32'd0;
                end
                cache_types::loadall: begin
                    write_en[i] = {32{1'b1}};
                    // load_set_1 = {32{1'b1}};
                end
                cache_types::loaden: begin  
                    write_en[i] = ba_mem_byte_enable256;
                    // load_set_1 = ba_mem_byte_enable256;
                end
                default: begin  
                    write_en[i] = 32'd0;
                    // load_set_1 = 32'd0;
                end
            endcase
      end

      unique case (data_in_sel)
            1'b0: begin
                for (int i=0; i<num_ways; ++i) begin
                    datain[i] = pmem_rdata;
                end
                // datain[next_lru_idx] = pmem_rdata;
                // datain[1] = pmem_rdata;
            end
            1'b1: begin
                for (int i=0; i<num_ways; ++i) begin
                    datain[i] = ba_mem_wdata256;
                end
                // datain[next_lru_idx] = ba_mem_wdata256;
                // datain[0] = ba_mem_wdata256;
                // datain[1] = ba_mem_wdata256;
            end
            default: ;
      endcase

      unique case (pmem_addr_sel)
            cache_types::raddr: pmem_address = {mem_address[31:5], 5'd0};
            cache_types::waddr: begin
                pmem_address = {tag_out_bits[least_recent_used_idx], addr_index, 5'd0};
            end
            default: ;
      endcase
end


endmodule : cache_datapath
