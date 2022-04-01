import rv32i_types::*;

module arbiter(
    input clk,
    input rst,

    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata,

    input logic       icline_read,
    input rv32i_word  icline_address,
    output logic       icline_resp,
    output logic [255:0] icline_rdata,

    input logic dcline_read,
    input logic dcline_write,
    input rv32i_word dcline_address,
    input logic [255:0] dcline_wdata,
    output logic dcline_resp,
    output logic [255:0] dcline_rdata
);


/******************** Cache <-> Cacheline Adapter Signals *********************/
rv32i_word cline_address;
logic [255:0] cline_rdata, cline_wdata;
logic cline_read, cline_write, cline_resp;
/******************************************************************************/


enum int unsigned {
    s_idle, 
    s_inst, s_inst_fin,
    s_data
} state, next_state;


always_comb
begin : state_actions
    cline_read = 1'b0;
    cline_write = 1'b0;
    icline_resp = 1'b0;
    dcline_resp = 1'b0;
    unique case (state) 
        s_idle: begin

        end
        s_inst: begin
            cline_read = 1'b1;
            cline_write = 1'b0;
            cline_address = icline_address;

            icline_resp = cline_resp;
            icline_rdata = cline_rdata;

            // inst_resp = mem_resp;
            // inst_rdata = mem_rdata;
        end
        s_data: begin
            cline_read = dcline_read;
            cline_write = dcline_write;
            cline_address = dcline_address;
            cline_wdata = dcline_wdata;

            dcline_resp = cline_resp;
            dcline_rdata = cline_rdata;
            // mem_read = data_read;
            // mem_write = data_write;
            // mem_address = data_addr;
            // data_resp = mem_resp;
            // data_rdata = mem_rdata;
            // if (data_write) begin
            //     mem_byte_enable = data_mbe;
            //     mem_wdata = data_wdata;
            // end 
        end
    endcase
end

always_comb
begin : next_state_logic
    unique case (state) 
        s_idle: begin
            if (dcline_read | dcline_write) begin
                next_state = s_data;
            end else if (icline_read) begin
                next_state = s_inst;
            end else begin
                next_state = s_idle;
            end
        end
        s_inst: begin
            if (cline_resp) begin
                next_state = s_idle;
            end else begin
                next_state = s_inst;
            end
        end 
        s_data: begin
            if (cline_resp) begin
                next_state = s_idle;
            end else begin
                next_state = s_data;
            end
        end
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    if (rst) state <= s_idle;
    else state <= next_state;
end

// cache dcache(
//     .clk(clk),

//     .pmem_resp(cline_resp),
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

// cache cache(
//     .clk(clk),
//     .rst(rst),
//     .mem_address(mem_address),
//     .mem_rdata(mem_rdata),
//     .mem_wdata(mem_wdata),
//     .mem_read(mem_read),
//     .mem_write(mem_write),
//     .mem_byte_enable(mem_byte_enable),
//     .mem_resp(mem_resp),
//     .pmem_address(cline_address),
//     .pmem_rdata(cline_rdata),
//     .pmem_wdata(cline_wdata),
//     .pmem_read(cline_read),
//     .pmem_write(cline_write),
//     .pmem_resp(cline_resp)
// );


cacheline_adaptor cacheline_adaptor
(
    .clk(clk),
    .reset_n(~rst),
    .line_i(cline_wdata),
    .line_o(cline_rdata),
    .address_i(cline_address),
    .read_i(cline_read),
    .write_i(cline_write),
    .resp_o(cline_resp),
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);

endmodule : arbiter