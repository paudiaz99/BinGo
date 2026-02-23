#!/bin/bash
set -e

echo "================================================="
echo " Starting Gate-Level Simulation Compile (GLS) "
echo "================================================="

PDK_ROOT=~/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af
SKY130_PRIMITIVES=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
SKY130_MODELS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

NETLIST=../rtl/top.pnl.v
TB_FILE=../../tb/top_tb.sv

OUTPUT_FILE=../sim/top_gls.vvp

mkdir -p ../sim

iverilog -g2012 -DGL_SIM -DFUNCTIONAL -DUSE_POWER_PINS -DUNIT_DELAY=#1 -o $OUTPUT_FILE $SKY130_PRIMITIVES $SKY130_MODELS $NETLIST $TB_FILE 

echo "Compilation successful. Running simulation..."
echo "================================================="

cd ../sim
vvp top_gls.vvp

echo "================================================="
echo " GLS Done. You can view waves using: "
echo " gtkwave top_gls_tb.vcd & "
echo "================================================="
