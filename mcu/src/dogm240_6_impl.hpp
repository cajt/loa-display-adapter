#ifndef DOGM240_6_HPP
#error "Don't include this file directly, use 'dogm240-6.hpp' instead!"
#endif
using namespace modm;

template <typename Scl, typename Sda, typename Reset, unsigned int Width, unsigned int Height>
void modm::Dogm240_6<Scl, Sda, Reset, Width, Height>::update()
{
	for (uint8_t y = 0; y < (Height / 8); ++y)
	{
		start();
		send(0x70);		// command
		send(0x60 + y); // set page addr
		send(0x70);
		stop();

		start();
		send(0x70); // command
		send(0x00); // set col addr
		send(0x10);
		stop();

		start();
		send(0x72);

		for (uint8_t x = 0; x < Width; ++x)
		{
			send(this->buffer[x][y]);
		}
		stop();
	}
}

// ----------------------------------------------------------------------------
template <typename Scl, typename Sda, typename Reset, unsigned int Width, unsigned int Height>
void modm::Dogm240_6<Scl, Sda, Reset, Width, Height>::initialize()
{
	Reset::setOutput(modm::platform::Gpio::OutputType::PushPull, modm::platform::Gpio::OutputSpeed::Low);
	Sda::setOutput(modm::platform::Gpio::OutputType::PushPull, modm::platform::Gpio::OutputSpeed::Low);
	Scl::setOutput(modm::platform::Gpio::OutputType::PushPull, modm::platform::Gpio::OutputSpeed::Low);
	Sda::set();
	Scl::set();

	// reset
	Reset::reset();
	delay(2ms);
	Reset::set();
	delay(60ms);

	// init according example table on page 8 in dogm240-6.pdf (version: 2019-05)
	start();
	send(0x70); // command
	send(0xf1);
	send(0x3f);
	stop();

	start();
	send(0x70); // command
	send(0xf2);
	send(0x00);
	stop();

	start();
	send(0x70); // command
	send(0xf3);
	send(0x00);
	stop();

	start();
	send(0x70); // command
	send(0x81);
	send(0xb7);
	stop();

	start();
	send(0x70); // command
	send(0xc0);
	send(0x02); // bottom view
	// send(0x04); // top view
	stop();

	start();
	send(0x70); // command
	send(0xa3);
	stop();

	start();
	send(0x70); // command
	send(0xe9);
	stop();

	start();
	send(0x70); // command
	send(0xa9);
	stop();

	start();
	send(0x70); // command
	send(0xd1);
	stop();

	this->clear();
	this->update();
}

template <typename Scl, typename Sda, typename Reset, unsigned int Width, unsigned int Height>
void modm::Dogm240_6<Scl, Sda, Reset, Width, Height>::start(void)
{
	Sda::set();
	Scl::set();
	delay(10ns);
	Sda::reset();
	delay(10ns);
	Scl::reset();
}

template <typename Scl, typename Sda, typename Reset, unsigned int Width, unsigned int Height>
void modm::Dogm240_6<Scl, Sda, Reset, Width, Height>::send(uint8_t d)
{
	uint8_t cnt;
	for (cnt = 0; cnt < 8; cnt++)
	{
		Sda::set(d & 0x80);
		d = (d << 1);
		delay(10ns);
		Scl::set();
		delay(10ns);
		Scl::reset();
	}
	Sda::reset(); // no ack bit, we ignore it, and actively drive it low
	Scl::set();
	delay(10ns);
	Scl::reset();
	delay(10ns);
}

template <typename Scl, typename Sda, typename Reset, unsigned int Width, unsigned int Height>
void modm::Dogm240_6<Scl, Sda, Reset, Width, Height>::stop(void)
{
	Sda::reset();
	delay(10ns);
	Scl::set();
	delay(10ns);
	Sda::set();
}
