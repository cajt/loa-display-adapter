#
# Mash'd together Makefile to use YOSYS/GHDL to build the
# FPGA Configuration 
#
# https://hdl.github.io/containers/ug/FineGrained.html

# tested with:
# GHDL 5.0.0-dev (v4.1.0-134-g10b9c9cae) [Dunoon edition]
# Yosys 0.36+42 (git sha1 70d35314d, clang 11.0.1-2 -fPIC -Os)
# "nextpnr-ice40" -- Next Generation Place and Route (Version nextpnr-0.7-53-gf17caa23)
# ghdl/synth       beta       fb3e9aaa6e33   
# ghdl/synth       nextpnr    8e4d7630a922   
# ghdl/synth       icestorm   4ac9e23f74e4   

PROJ = toplevel
PIN_DEF = pins.pcf
TOP_LEVEL = toplevel
VHDL_FILES = toplevel/toplevel.vhd hdl/*.vhd
VERILOG_FILES = toplevel/pll.v

DOCKER     = docker
PWD        = $(shell pwd)
DOCKERARGS = run --rm -v $(PWD):/src -w /src
GHDL       = $(DOCKER) $(DOCKERARGS) ghdl/synth:beta ghdl
YOSYS      = $(DOCKER) $(DOCKERARGS) ghdl/synth:beta yosys
NEXTPNR    = $(DOCKER) $(DOCKERARGS) ghdl/synth:nextpnr nextpnr-ice40
ICEPACK    = $(DOCKER) $(DOCKERARGS) ghdl/synth:icestorm icepack

ifneq ($(VERILOG_FILES),)
MAYBE_READ_VERILOG = read_verilog $(VERILOG_FILES);
endif

all: $(PROJ).bin

$(PIN_DEF): toplevel/debug.pcf toplevel/icestick.pcf toplevel/leds.pcf toplevel/st7565.pcf toplevel/uart_stm32.pcf toplevel/uart.pcf
	rm -f $@
	cat $^ >> $@

%.json: $(VHDL_FILES) toplevel/%.vhd
	$(YOSYS) -m ghdl -p \
		"ghdl --ieee=synopsys $^ -e $(TOP_LEVEL); \
		$(MAYBE_READ_VERILOG) \
		synth_ice40 -json $@"

%.asc: %.json $(PIN_DEF)
	$(NEXTPNR) --package hx1k --pcf $(PIN_DEF) --pcf-allow-unconstrained --json $< --asc $@

%.bin: %.asc
	$(ICEPACK) $< $@

prog: $(PROJ).bin
	iceprog $<

clean:
	rm -f $(PROJ).json $(PROJ).asc $(PROJ).bin $(PIN_DEF)

.SECONDARY:

.PHONY: all prog clean
