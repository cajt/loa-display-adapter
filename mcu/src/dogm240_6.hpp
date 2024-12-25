#ifndef DOGM240_6_HPP
#define DOGM240_6_HPP

#include <modm/architecture/interface/delay.hpp>
#include <modm/ui/display/monochrome_graphic_display_vertical.hpp>

namespace modm
{
	template <typename Scl, typename Sda, typename Reset, unsigned int Width, unsigned int Height>
	class Dogm240_6 : public MonochromeGraphicDisplayVertical<Width, Height>
	{
	public:
		virtual ~Dogm240_6()
		{
		}

		virtual void
		update();

		modm_always_inline void
		initialize();

		uint8_t *getBuffer() { return (uint8_t *)this->buffer; };

	protected:
		unsigned int i2c_delay = 10;

		void
		start(void);

		void
		send(uint8_t d);

		void
		stop(void);

		Scl scl;
		Sda sda;
		Reset reset;
	};
}

#include "dogm240_6_impl.hpp"

#endif // DOGM240_6_HPP
