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
    
    input logic load_valid_0,
    input logic load_valid_1,
    input logic load_tag_0,
    input logic load_tag_1,

    output logic lru,
    input logic next_lru,

    output logic hit_0, // 
    output logic hit_1, //


    input logic [31:0] mem_address,
    output logic [31:0] pmem_address, //
    input logic [255:0] pmem_rdata,
    output logic [31:0] mem_rdata // port to cpu
);

logic [num_sets-1:0] valid_0_bits;
logic [num_sets-1:0] valid_1_bits;
logic [num_sets-1:0] lru_bits;
logic [num_sets-1:0][s_tag-1:0] tag_0_bits;
logic [num_sets-1:0][s_tag-1:0] tag_1_bits;
logic [num_sets-1:0][s_line-1:0] data_0_bits;
logic [num_sets-1:0][s_line-1:0] data_1_bits;

logic [s_index-1:0] addr_index;
logic [s_tag-1:0] addr_tag;

logic [255:0] data_out;

assign addr_index = mem_address[7:5];
assign addr_tag = mem_address[31:8];

assign valid_0 = valid_0_bits[addr_index];
assign valid_1 = valid_1_bits[addr_index];
assign hit_0 = valid_0 & ((addr_tag == tag_0_bits[addr_index]) ? 1'b1 : 1'b0);
assign hit_1 = valid_1 & ((addr_tag == tag_1_bits[addr_index]) ? 1'b1 : 1'b0);
assign lru = lru_bits[addr_index];

assign pmem_address = {mem_address[31:5], 5'd0};

always_ff @(posedge clk) begin
    if (rst) begin
        valid_0_bits <= 0;
        valid_1_bits <= 0;
        lru_bits <= 0;
    end else begin
        if (load_valid_0) begin
            valid_0_bits[addr_index] <= 1'b1;
        end
        if (load_valid_1) begin
            valid_1_bits[addr_index] <= 1'b1;
        end
        lru_bits[addr_index] <= next_lru;
        if (load_tag_0) begin
            tag_0_bits[addr_index] <= addr_tag;
            data_0_bits[addr_index] <= pmem_rdata;
        end
        if (load_tag_1) begin
            tag_1_bits[addr_index] <= addr_tag;
            data_1_bits[addr_index] <= pmem_rdata;
        end
    end
end

always_comb begin
    if (load_tag_0 | load_tag_1) begin
        data_out =  pmem_rdata;
    end else begin
        data_out = next_lru ? data_0_bits[addr_index] : data_1_bits[addr_index];
    end
    mem_rdata = data_out[(32*mem_address[4:2]) +: 32]; 
end

endmodule : inst_cache_datapath
