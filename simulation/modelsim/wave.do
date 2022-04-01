onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mp4_tb/itf/clk
add wave -noupdate /mp4_tb/dut/cpu/datapath/REGFILE/data
add wave -noupdate /mp4_tb/dut/cpu/inst_addr
add wave -noupdate /mp4_tb/dut/cpu/inst_rdata
add wave -noupdate /mp4_tb/dut/cpu/inst_read
add wave -noupdate /mp4_tb/dut/cpu/inst_resp
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_decoder[1]}
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_decoder[2]}
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_decoder[3]}
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_decoder[4]}
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_control[1]}
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_control[2]}
add wave -noupdate {/mp4_tb/dut/cpu/datapath/inst_control[4]}
add wave -noupdate /mp4_tb/dut/cpu/datapath/regfilemux_out
add wave -noupdate /mp4_tb/dut/cpu/datapath/alu_out
add wave -noupdate /mp4_tb/dut/cpu/datapath/rs1_out
add wave -noupdate /mp4_tb/dut/cpu/datapath/rs2_out
add wave -noupdate /mp4_tb/dut/cpu/datapath/data_read
add wave -noupdate /mp4_tb/dut/cpu/datapath/data_addr
add wave -noupdate /mp4_tb/dut/cpu/datapath/data_rdata
add wave -noupdate /mp4_tb/dut/cpu/datapath/br_en
add wave -noupdate /mp4_tb/dut/cpu/datapath/CMP/a
add wave -noupdate /mp4_tb/dut/cpu/datapath/CMP/b
add wave -noupdate /mp4_tb/dut/cpu/datapath/CMP/cmpop
add wave -noupdate /mp4_tb/pc_rdata_p1
add wave -noupdate /mp4_tb/pc_rdata_p2
add wave -noupdate /mp4_tb/pc_rdata_p3
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1036013 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 264
configure wave -valuecolwidth 179
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
WaveRestoreZoom {1732070 ps} {1958933 ps}
