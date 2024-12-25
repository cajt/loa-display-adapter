#include <modm/debug/logger.hpp>
#include <modm/architecture.hpp>
#include <modm/platform.hpp>
#include "loa_hdlc.hpp"
#include <modm/processing/protothread.hpp>
#include <modm/processing/resumable.hpp>
#include <modm/processing/timer.hpp>
#include <modm/processing/timer/timeout.hpp>
#include <modm/architecture/interface/delay.hpp>
#include <modm/board.hpp>
#include "dogm240_6.hpp"
using namespace modm::platform;
using namespace modm::literals;

using LedD13 = Board::LedD13;
typedef Board::D7 sda;
typedef Board::D8 scl;
typedef Board::A0 rst;

modm::Dogm240_6<scl, sda, rst, 240, 64> display;

volatile uint8_t *buf;

typedef modm::platform::BufferedUart<UsartHal1> staticPort;
typedef loa::hdlc::Interface<staticPort> hdlcInterface;

hdlcInterface hdlcLink0;

class blink : public modm::pt::Protothread, private modm::NestedResumable<10>
{
public:
	bool run()
	{
		PT_BEGIN();
		while (true)
		{
			PT_CALL(write(0x0000, 0x1));
			PT_CALL(delay(5ms));
			PT_CALL(write(0x0000, 0x0));
			for (y = 0; y < 8; ++y)
			{
				for (x = 0; x < 60; ++x)
				{
					d = PT_CALL(read(0x1000 + x + y * 64));
					buf[x * 16 + y] = (uint8_t)d & 0xff;
					buf[x * 16 - 8 + y] = (uint8_t)(d >> 8) & 0xff;
				}
				for (x = 0; x < 60; ++x)
				{
					d = PT_CALL(read(0x2000 + x + y * 64));
					buf[120 * 8 + x * 16 + y] = (uint8_t)d & 0xff;
					buf[120 * 8 + x * 16 - 8 + y] = (uint8_t)(d >> 8) & 0xff;
				}
			}
			display.update();
		}
		PT_END();
	};

	modm::ResumableResult<bool> write(uint16_t addr, uint16_t data)
	{
		RF_BEGIN();
		hdlcLink0.queue.clear(); // protocol is ping-pong sequence, we don't care about old things
		timeout.restart(2ms);
		hdlcLink0.sendWrite(addr, data);

		RF_WAIT_UNTIL(timeout.isExpired() | hdlcLink0.findWriteResponse());

		if (hdlcLink0.findWriteResponse())
		{
			// MODM_LOG_INFO << "got write response" << modm::endl;
		}
		else
		{
			MODM_LOG_INFO << "write timeout" << modm::endl;
		}
		RF_END_RETURN(false);
	}

	modm::ResumableResult<uint16_t> read(uint16_t addr)
	{
		RF_BEGIN();
		hdlcLink0.queue.clear();
		timeout.restart(2ms);
		hdlcLink0.sendRead(addr);

		// this should look for frame seperator, and at least the expected number of characters
		RF_WAIT_UNTIL(timeout.isExpired() | (hdlcLink0.findReadResponse()));

		if (hdlcLink0.findReadResponse())
		{
			// MODM_LOG_INFO << "found read response, got addr " << modm::hex << addr << ": " << hdlcLink0.readData << modm::endl;
		}
		else
		{
			MODM_LOG_INFO << "read timeout" << modm::endl;
		}

		RF_END_RETURN(hdlcLink0.readData);
	}

	modm::ResumableResult<bool> delay(std::chrono::duration<uint16_t, std::milli> t)
	{
		RF_BEGIN();
		interval.restart(t);
		RF_WAIT_UNTIL(interval.isExpired());
		RF_END_RETURN(false);
	}

private:
	modm::ShortTimeout interval;
	modm::ShortTimeout timeout;
	uint16_t x, y, a, d;
};

blink blinker;

int main()
{
	GpioA9::setOutput();
	staticPort::connect<modm::platform::GpioA9::Tx, modm::platform::GpioA10::Rx>();

	staticPort::initialize<Board::SystemClock, 2000000_Bd>(modm::platform::UartBase::Parity::Odd,
														   modm::platform::UartBase::WordLength::Bit9);

	hdlcLink0.initialize();

	Board::initialize();
	display.initialize();
	display.setFont(modm::font::Assertion);
	display << modm::endl;
	display << "HMP 2020 Display Converter" << modm::endl;
	display << "Version 0.1 2021-02-23" << modm::endl;
	display.update();
	MODM_LOG_INFO << "Started: (..)" << modm::endl;
	delay(2000ms);

	buf = (uint8_t *)display.getBuffer();

	display.update();
	while (true)
	{
		hdlcLink0.update();
		blinker.run();
	}
}
