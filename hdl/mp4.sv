import rv32i_types::*;

module mp4(
    input clk,
    input rst,

    // output logic       inst_read,
    // output rv32i_word  inst_addr,
    // input logic        inst_resp,
    // input rv32i_word  inst_rdata,

    // output logic data_read,
    // output logic data_write,
    // output logic [3:0] data_mbe,
    // output rv32i_word data_addr,
    // output rv32i_word data_wdata,
    // input logic data_resp,
    // input rv32i_word data_rdata
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

/*************************** CPU <-> Cache Signals ****************************/
// rv32i_word mem_address, mem_rdata, mem_wdata;
// logic mem_read, mem_write, mem_resp;
// logic [3:0] mem_byte_enable;
/******************************************************************************/

/******************** Cache <-> Cacheline Adapter Signals *********************/
// rv32i_word cline_address;
// logic [255:0] cline_rdata, cline_wdata;
// logic cline_read, cline_write, cline_resp;
/******************************************************************************/

logic       inst_read;
rv32i_word  inst_addr;
logic       inst_resp;
rv32i_word inst_rdata;

logic data_read;
logic data_write;
logic [3:0] data_mbe;
rv32i_word data_addr;
rv32i_word data_wdata;
logic data_resp;
rv32i_word data_rdata;


cache_itf cache_itf(.*);

// assign pmem_write = 1'b0;
// assign pmem_read = rst ? 1'b0 : 1'b1;
// assign mem_address = 32'h00000060;
// assign pmem_address = {mem_address[31:2], 2'b00};

// /* I Cache */
// logic       inst_read;
// rv32i_word  inst_addr;
// logic       inst_resp;
// rv32i_word inst_rdata;

cpu cpu(.*);

// cache cache(
//     .clk(clk),

//     .pmem_resp(pmem_resp),
//     .pmem_rdata(cline_rdata),
//     .pmem_address(cline_address),
//     .pmem_wdata(cline_wdata),
//     .pmem_read(cline_read),
//     .pmem_write(cline_write),

//     .mem_read(mem_read),
//     .mem_write(mem_write),
//     .mem_byte_enable_cpu(mem_byte_enable),
//     .mem_address(mem_address),
//     .mem_wdata_cpu(mem_wdata),
//     .mem_resp(mem_resp),
//     .mem_rdata_cpu(mem_rdata)
// );

// cacheline_adaptor cacheline_adaptor
// (
//     .clk(clk),
//     .reset_n(~rst),
//     .line_i(cline_wdata),
//     .line_o(cline_rdata),
//     .address_i(cline_address),
//     .read_i(cline_read),
//     .write_i(cline_write),
//     .resp_o(cline_resp),
//     .burst_i(pmem_rdata),
//     .burst_o(pmem_wdata),
//     .address_o(pmem_address),
//     .read_o(pmem_read),
//     .write_o(pmem_write),
//     .resp_i(pmem_resp)
// );


endmodule : mp4
