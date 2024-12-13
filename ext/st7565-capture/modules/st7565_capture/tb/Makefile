Makefile_ghdl:
	ghdl --clean
	ghdl -i ../../hdl/*.vhd
	#ghdl -i st7565_capture_tb.vhd
	ghdl -i st7565_capture_module_tb.vhd
	ghdl --gen-makefile file_tb > Makefile_ghdl

wave.ghw: Makefile_ghdl
	make -f Makefile_ghdl  run GHDLRUNFLAGS="--stop-time=55ms --wave=wave.ghw"

view: wave.ghw
	gtkwave wave.gtkw

clean:
	rm -f Makefile_ghdl work-obj93.cf wave.ghw
