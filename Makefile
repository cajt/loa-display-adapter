mcu/SConstruct: lbuild-mcu

lbuild-mcu:
	(cd mcu; lbuild build)

build-mcu: mcu/SConstruct 
	(cd mcu; scons)

clean-mcu:
	(cd mcu; scons -c)

clean-mcu-lbuild: clean-mcu
	(cd mcu; lbuild clean)
	rm -rf mcu/build mcu/modm mcu/.sconsign.dblite 

mcu/build/scons-release/mcu.elf: build-mcu

prog-mcu: mcu/build/scons-release/mcu.elf
	(cd mcu; scons program)

build-fpga:
	(cd fpga; make all)
clean-fpga:
	(cd fpga; make clean)

clean: clean-fpga clean-mcu-lbuild

all: build-mcu build-fpga

latency:
	echo 1 > /sys/bus/usb-serial/devices/ttyUSB0/latency_timer
	echo 1 > /sys/bus/usb-serial/devices/ttyUSB1/latency_timer

