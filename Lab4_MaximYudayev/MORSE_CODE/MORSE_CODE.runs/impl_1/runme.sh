#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
# 

if [ -z "$PATH" ]; then
  PATH=/usr/local/Xilinx/Vivado/2019.2/ids_lite/ISE/bin/lin64:/usr/local/Xilinx/Vivado/2019.2/bin
else
  PATH=/usr/local/Xilinx/Vivado/2019.2/ids_lite/ISE/bin/lin64:/usr/local/Xilinx/Vivado/2019.2/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=
else
  LD_LIBRARY_PATH=:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='/home/maxim/Vivado/Lab4/MORSE_CODE/MORSE_CODE.runs/impl_1'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

# pre-commands:
/bin/touch .init_design.begin.rst
EAStep vivado -log morse_code_lock.vdi -applog -m64 -product Vivado -messageDb vivado.pb -mode batch -source morse_code_lock.tcl -notrace


