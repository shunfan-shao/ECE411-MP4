transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

set mp4_path [pwd]

vlog -reportprogress 300 -work work $mp4_path/../../hdl/rv32i_mux_types.sv
vlog -reportprogress 300 -work work $mp4_path/../../hdl/rv32i_types.sv
vlog -reportprogress 300 -work work $mp4_path/../../hdl/inst_cache/*.sv
vlog -reportprogress 300 -work work $mp4_path/../../hdl/cache/cache_types.sv
vlog -reportprogress 300 -work work $mp4_path/../../hdl/cache/*.sv
vlog -reportprogress 300 -work work $mp4_path/../../hdl/cpu/*.sv
vlog -reportprogress 300 -work work $mp4_path/../../hdl/*.sv
vlog -reportprogress 300 -work work $mp4_path/../../hvl/*.sv
vlog -reportprogress 300 -work work $mp4_path/../../hvl/*.v

vsim -t 1ps -gui -L rtl_work -L work mp4_tb

view structure
view signals
do wave.do

run 60ns