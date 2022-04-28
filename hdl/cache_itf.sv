import rv32i_types::*;

module cache_itf(
    input clk,
    input rst,

    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata,

    input logic       inst_read,
    input rv32i_word  inst_addr,
    output logic       inst_resp,
    output rv32i_word  inst_rdata,

    input logic data_read,
    input logic data_write,
    input logic [3:0] data_mbe,
    input rv32i_word data_addr,
    input rv32i_word data_wdata,
    output logic data_resp,
    output rv32i_word data_rdata
);

/******************** Cache <-> Cacheline Adapter Signals *********************/
rv32i_word icline_address;
logic [255:0] icline_rdata;
logic icline_read, icline_resp;

rv32i_word dcline_address;
logic [255:0] dcline_rdata, dcline_wdata;
logic dcline_read, dcline_write, dcline_resp;
/******************************************************************************/

logic iprefetch, iprefetch_done;
logic [31:0] iprefetch_addr;

inst_cache inst_cache(
    .clk(clk),
    .rst(rst),

    .prefetch(iprefetch),
    .prefetch_address(iprefetch_addr),
    .prefetch_ready(iprefetch_done),

    .pmem_address(icline_address),
    .pmem_rdata(icline_rdata),
    .pmem_read(icline_read),
    .pmem_resp(icline_resp),

    .mem_address(inst_addr),
    .mem_rdata(inst_rdata),
    .mem_read(inst_read),
    .mem_resp(inst_resp)
);

param_cache data_cache(
    .clk(clk),
    .rst(rst),

    .pmem_address(dcline_address),
    .pmem_rdata(dcline_rdata),
    .pmem_wdata(dcline_wdata),
    .pmem_read(dcline_read),
    .pmem_write(dcline_write),
    .pmem_resp(dcline_resp),

    .mem_address(data_addr),
    .mem_rdata(data_rdata),
    .mem_wdata(data_wdata),
    .mem_read(data_read),
    .mem_write(data_write),
    .mem_byte_enable(data_mbe),
    .mem_resp(data_resp)
);

arbiter arbiter(.*);


endmodule : cache_itf