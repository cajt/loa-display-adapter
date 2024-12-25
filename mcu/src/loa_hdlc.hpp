/*
 * Copyright (c) 2009, Georgi Grinshpun
 * Copyright (c) 2009-2012, Fabian Greif
 * Copyright (c) 2012-2013, 2016, Niklas Hauser
 * Copyright (c) 2013, Sascha Schade
 *
 * This file is part of the modm project.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
// ----------------------------------------------------------------------------

#ifndef	LOA_HDLC_INTERFACE_HPP
#define	LOA_HDLC_INTERFACE_HPP

#include <cstddef>
#include <stdint.h>
#include <modm/architecture/utils.hpp>
#include <modm/container.hpp>

namespace loa
{
	namespace hdlc
	{
		uint8_t
		crcUpdate(uint8_t crc, uint8_t data);

		typedef enum{esc=1, nesc=0} stateT;
		typedef enum{frame_sep=1, normal=0} symbolType;
		typedef struct {
			symbolType type;
			unsigned char data;
		} symbol;

		template <typename Device>
		class Interface
		{
		public:

			static void
			initialize();

			static void
			sendWrite(uint16_t address, uint16_t data);

			bool
			findWriteResponse();

			static void
			sendRead(uint16_t address);

			bool
			findReadResponse();
			uint16_t readData = 0;


			static void
			update();

			static modm::BoundedDeque<symbol, 10> queue;

		private:
			static uint8_t buffer[8];
			static uint8_t crc;
			static uint8_t position;
			static stateT state;
			static void sendEsc(uint8_t d); 
		};
	}
}

#include "loa_hdlc_impl.hpp"

#endif	// LOA_HDLC_INTERFACE_HPP
