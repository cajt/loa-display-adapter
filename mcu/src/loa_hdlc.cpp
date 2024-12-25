#include <cstddef>
#include <stdint.h>
#include <modm/architecture/utils.hpp>
#include "loa_hdlc.hpp"
#include <modm/container.hpp>

uint8_t
loa::hdlc::crcUpdate(uint8_t crc, uint8_t data)
{
	crc = crc ^ data;
	for (uint_fast8_t i = 0; i < 8; ++i)
	{
		if (crc & 0x80) {
			crc = (crc << 1) ^ 0x07; // CRC-8-CCiTT, SMBUS PEC
		}
		else {
			crc <<= 1;
		}
	}
	return crc;
}
