# loa-display-adapter

# Problem solved

A HMP2030 with a broken display. The display is a custom part with no easily available replacement (matching electrical & mechanical interfaces).


# Architecture 

A FPGA emulates the protocol used between the powersupplies controller and the broken display, and places this in an internal framebuffer. Another microcontroller transfers this framebuffer content
to another LC-display. The FPGA's gateware is developed using the LOA project and the microcontroller uses large parts of the modm framework.


# Development Setup 

Xubuntu 18.04
Icecube2 (Version ??)
modm 2024q3
loa 

# HW Setup

See doc/images .

- HMP 2030
- IceStick 
- Nucleo F042 Board
- EA 240 display
- Adafruit Breakout board 
