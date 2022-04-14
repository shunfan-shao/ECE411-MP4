module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit f;
logic [31:0] pc_rdata_p1, pc_rdata_p2, pc_rdata_p3; // last 2 instructions

/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2
assign rvfi.pc_rdata = dut.cpu.datapath.inst_addr;
assign rvfi.pc_wdata = dut.cpu.datapath.pcmux_out;

// assign rvfi.commit = ~(dut.cpu.datapath.stall | dut.cpu.datapath.stall_ifid); // Set high when a valid instruction is modifying regfile or PC
assign rvfi.commit = 1'b0; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = (rvfi.pc_rdata == pc_rdata_p3);
// assign rvfi.halt = (dut.cpu.datapath.inst_addr_minus_4 == 32'hd4);
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/*
The following signals need to be set:
Instruction and trap:
    rvfi.inst
    rvfi.trap

Regfile:
    rvfi.rs1_addr
    rvfi.rs2_add
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata

Please refer to rvfi_itf.sv for more information.
*/
// assign branch_inst = dut.cpu.datapath.inst_decoder[STAGE_EX].opcode == op_br;

always_ff @(posedge itf.clk) 
begin
    if (~itf.rst && (~(dut.cpu.datapath.stall | dut.cpu.datapath.stall_ifid))) begin
        pc_rdata_p3 = pc_rdata_p2;
        pc_rdata_p2 = pc_rdata_p1;
        pc_rdata_p1 = rvfi.pc_rdata;
    end
end

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/
/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level:
Clock and reset signals:
    itf.clk
    itf.rst

Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

mp4 dut(
    .clk          (itf.clk),
    .rst          (itf.rst),
    // .inst_read    (itf.inst_read),
    // .inst_addr    (itf.inst_addr),
    // .inst_resp    (itf.inst_resp),
    // .inst_rdata   (itf.inst_rdata),

    // .data_read(itf.data_read),
    // .data_write(itf.data_write),
    // .data_mbe(itf.data_mbe),
    // .data_addr(itf.data_addr),
    // .data_wdata(itf.data_wdata),
    // .data_resp(itf.data_resp),
    // .data_rdata(itf.data_rdata)
    .pmem_resp    (itf.mem_resp),
    .pmem_rdata   (itf.mem_rdata),
    .pmem_read    (itf.mem_read),
    .pmem_write   (itf.mem_write),
    .pmem_address (itf.mem_addr),
    .pmem_wdata   (itf.mem_wdata)
);
/***************************** End Instantiation *****************************/


endmodule
