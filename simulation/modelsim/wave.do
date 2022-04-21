onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mp4_tb/itf/clk
add wave -noupdate -expand -subitemconfig {{/mp4_tb/dut/cpu/datapath/REGFILE/data[10]} {-color Orange -height 16} {/mp4_tb/dut/cpu/datapath/REGFILE/data[11]} {-color Magenta -height 16} {/mp4_tb/dut/cpu/datapath/REGFILE/data[15]} {-color Orange -height 16}} /mp4_tb/dut/cpu/datapath/REGFILE/data
add wave -noupdate -expand -group Cache /mp4_tb/dut/cache_itf/arbiter/state
add wave -noupdate -expand -group Cache /mp4_tb/dut/cache_itf/data_cache/control/state
add wave -noupdate -expand -group Cache -radix hexadecimal /mp4_tb/dut/cache_itf/data_cache/clk
add wave -noupdate -expand -group Cache -expand /mp4_tb/dut/cache_itf/data_cache/control/hit_bits
add wave -noupdate -expand -group Cache -expand /mp4_tb/dut/cache_itf/data_cache/datapath/lru_bits
add wave -noupdate -expand -group Cache /mp4_tb/dut/cache_itf/data_cache/control/next_lru_idx
add wave -noupdate -expand -group Cache -radix decimal -radixshowbase 0 /mp4_tb/dut/cache_itf/data_cache/datapath/least_recent_used_idx
add wave -noupdate -expand -group Cache /mp4_tb/dut/cache_itf/data_cache/datapath/valid_bits
add wave -noupdate -expand -group Cache -expand /mp4_tb/dut/cache_itf/data_cache/control/next_valid_bits
add wave -noupdate -expand -group Cache /mp4_tb/dut/cache_itf/data_cache/control/next_dirty_bits
add wave -noupdate -expand -group Cache /mp4_tb/dut/cache_itf/data_cache/datapath/valid_bits_array/data
add wave -noupdate -expand -group Cache /mp4_tb/dut/cache_itf/data_cache/datapath/addr_index
add wave -noupdate -expand -group Cache /mp4_tb/dut/cache_itf/data_cache/datapath/addr_tag
add wave -noupdate -expand -group Cache -expand -subitemconfig {{/mp4_tb/dut/cache_itf/data_cache/datapath/tag_bits_array/data[1]} -expand {/mp4_tb/dut/cache_itf/data_cache/datapath/tag_bits_array/data[0]} -expand} /mp4_tb/dut/cache_itf/data_cache/datapath/tag_bits_array/data
add wave -noupdate -expand -group Cache -expand -subitemconfig {{/mp4_tb/dut/cache_itf/data_cache/datapath/data_sets/data[1]} -expand {/mp4_tb/dut/cache_itf/data_cache/datapath/data_sets/data[0]} -expand} /mp4_tb/dut/cache_itf/data_cache/datapath/data_sets/data
add wave -noupdate /mp4_tb/dut/cpu/inst_addr
add wave -noupdate /mp4_tb/dut/cpu/datapath/inst_addr_minus_4
add wave -noupdate /mp4_tb/dut/cpu/inst_rdata
add wave -noupdate /mp4_tb/dut/cpu/inst_read
add wave -noupdate /mp4_tb/dut/cpu/inst_resp
add wave -noupdate /mp4_tb/dut/cpu/data_addr
add wave -noupdate /mp4_tb/dut/data_read
add wave -noupdate /mp4_tb/dut/cpu/data_write
add wave -noupdate /mp4_tb/dut/data_resp
add wave -noupdate /mp4_tb/dut/cpu/data_wdata
add wave -noupdate /mp4_tb/dut/cpu/data_rdata
add wave -noupdate /mp4_tb/dut/cpu/control_rom/ctrl
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_decoder[1]}
add wave -noupdate -expand {/mp4_tb/dut/cpu/datapath/inst_decoder[2]}
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_decoder[3]}
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_decoder[4]}
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_control[1]}
add wave -noupdate -expand {/mp4_tb/dut/cpu/datapath/inst_control[2]}
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_control[3]}
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_control[4]}
add wave -noupdate /mp4_tb/dut/cpu/datapath/div_start
add wave -noupdate /mp4_tb/dut/cpu/datapath/div_done
add wave -noupdate /mp4_tb/dut/cpu/datapath/DIV/calc
add wave -noupdate /mp4_tb/dut/cpu/datapath/DIV/state
add wave -noupdate /mp4_tb/dut/cpu/datapath/quotient
add wave -noupdate /mp4_tb/dut/cpu/datapath/remainder
add wave -noupdate /mp4_tb/dut/cpu/datapath/alumux1_out
add wave -noupdate /mp4_tb/dut/cpu/datapath/alumux2_out
add wave -noupdate /mp4_tb/dut/cpu/datapath/rs1_fwoutmux_sel
add wave -noupdate /mp4_tb/dut/cpu/datapath/rs2_fwoutmux_sel
add wave -noupdate /mp4_tb/dut/cpu/datapath/rs1_fwoutmux_out
add wave -noupdate /mp4_tb/dut/cpu/datapath/rs2_fwoutmux_out
add wave -noupdate /mp4_tb/dut/cpu/datapath/rs1_out
add wave -noupdate /mp4_tb/dut/cpu/datapath/rs2_out
add wave -noupdate /mp4_tb/dut/cpu/datapath/ALU/a
add wave -noupdate /mp4_tb/dut/cpu/datapath/ALU/b
add wave -noupdate /mp4_tb/dut/cpu/datapath/MULT/multiplicand
add wave -noupdate /mp4_tb/dut/cpu/datapath/MULT/multiplier
add wave -noupdate /mp4_tb/dut/cpu/datapath/MULT/product
add wave -noupdate /mp4_tb/dut/cpu/datapath/mult_start
add wave -noupdate /mp4_tb/dut/cpu/datapath/mult_done
add wave -noupdate -radix decimal -radixshowbase 0 /mp4_tb/dut/cpu/datapath/mult_out
add wave -noupdate -expand /mp4_tb/dut/cpu/datapath/alu_out
add wave -noupdate /mp4_tb/dut/cpu/datapath/cpmmux_out
add wave -noupdate /mp4_tb/dut/cpu/datapath/CMP/a
add wave -noupdate /mp4_tb/dut/cpu/datapath/CMP/b
add wave -noupdate /mp4_tb/dut/cpu/datapath/CMP/cmpop
add wave -noupdate /mp4_tb/dut/cpu/datapath/br_en
add wave -noupdate /mp4_tb/dut/cpu/datapath/branch_taken
add wave -noupdate /mp4_tb/dut/cpu/datapath/stall_ifid
add wave -noupdate /mp4_tb/rvfi/pc_rdata
add wave -noupdate /mp4_tb/pc_rdata_p1
add wave -noupdate /mp4_tb/pc_rdata_p2
add wave -noupdate /mp4_tb/pc_rdata_p3
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {79535285 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 359
configure wave -valuecolwidth 207
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {79356865 ps} {79565429 ps}
