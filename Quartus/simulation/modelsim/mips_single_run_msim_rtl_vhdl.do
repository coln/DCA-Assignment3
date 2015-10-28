transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/reg_bit.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/lib.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/reg.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/extender.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/cla4.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/Quartus/data_memory.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/Quartus/instr_memory.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/control.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/mux2.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/reg_file.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/mux4.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/alu_control.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/add.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/program_counter.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/alu.vhd}
vcom -93 -work work {C:/Users/Colin/Documents/UF/Fall 2015/Digital Computer Architecture/Lab 3/mips_single.vhd}

