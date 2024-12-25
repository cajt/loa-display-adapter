#ifndef LOA_HDLC_INTERFACE_HPP
#error "Don't include this file directly, use 'interface.hpp' instead!"
#endif

#include <modm/debug/logger.hpp>
#include <modm/container.hpp>

template <typename Device>
uint8_t loa::hdlc::Interface<Device>::buffer[8];
template <typename Device>
uint8_t loa::hdlc::Interface<Device>::crc;
template <typename Device>
uint8_t loa::hdlc::Interface<Device>::position;
template <typename Device>
loa::hdlc::stateT loa::hdlc::Interface<Device>::state;
template <typename Device>
modm::BoundedDeque<loa::hdlc::symbol, 10> loa::hdlc::Interface<Device>::queue;

// ----------------------------------------------------------------------------

template <typename Device>
void loa::hdlc::Interface<Device>::initialize()
{
  state = nesc;
}

// ----------------------------------------------------------------------------

template <typename Device>
void loa::hdlc::Interface<Device>::sendEsc(uint8_t data)
{
  // escape the escpe and frame-sep characters
  if (data == 0x7d)
  {
    Device::write(0x7d);
    Device::write(0x5d);
  }
  else if (data == 0x7e)
  {
    Device::write(0x7d);
    Device::write(0x5e);
  }
  else
  {
    Device::write(data);
  }
}

// ----------------------------------------------------------------------------

template <typename Device>
void loa::hdlc::Interface<Device>::sendWrite(uint16_t address, uint16_t data)
{
  uint8_t crcSend;

  Device::write(0x7e);
  sendEsc(0x20);
  crcSend = loa::hdlc::crcUpdate(0x00, 0x20);
  sendEsc((address >> 8) & 0xff);
  crcSend = loa::hdlc::crcUpdate(crcSend, (address >> 8) & 0xff);
  sendEsc(address & 0xff);
  crcSend = loa::hdlc::crcUpdate(crcSend, address & 0xff);
  sendEsc((data >> 8) & 0xff);
  crcSend = loa::hdlc::crcUpdate(crcSend, (data >> 8) & 0xff);
  sendEsc(data & 0xff);
  crcSend = loa::hdlc::crcUpdate(crcSend, data & 0xff);
  sendEsc(crcSend);
  // sendEsc(0x00);
}

// ----------------------------------------------------------------------------

template <typename Device>
void loa::hdlc::Interface<Device>::sendRead(uint16_t address)
{
  uint8_t crcSend;

  Device::write(0x7e);
  sendEsc(0x10);
  crcSend = loa::hdlc::crcUpdate(0x00, 0x10);
  sendEsc((address >> 8) & 0xff);
  crcSend = loa::hdlc::crcUpdate(crcSend, (address >> 8) & 0xff);
  sendEsc(address & 0xff);
  crcSend = loa::hdlc::crcUpdate(crcSend, address & 0xff);
  sendEsc(crcSend);
  // sendEsc(0x00);
}

// ----------------------------------------------------------------------------

template <typename Device>
bool loa::hdlc::Interface<Device>::findReadResponse()
{
  unsigned int start = 0;
  uint8_t crc = 0;

  if (queue.getSize() < 5)
  {
    return false;
  }

  // find frame seperator (fs)
  while (1)
  {
    if (start == queue.getSize())
    {
      return false;
    } // we iterated out of the deque, and found no fs
    if (queue.get(start).type == frame_sep)
    {
      break;
    } // found fs, we now on assume start points to the fs
    start++;
  }

  // check for msg len
  if ((queue.getSize() - start) < 4)
  {
    return false;
  }

  // check type
  if (not(
          (queue.get(start + 1).type == normal) &
          (queue.get(start + 1).data == 0x11)))
  {
    return false;
  }

  crc = loa::hdlc::crcUpdate(crc, queue.get(start + 1).data);
  crc = loa::hdlc::crcUpdate(crc, queue.get(start + 2).data);
  crc = loa::hdlc::crcUpdate(crc, queue.get(start + 3).data);
  if (crc != queue.get(start + 4).data)
  {
    return false;
  }

  readData = (queue.get(start + 2).data << 8) + (queue.get(start + 3).data);
  return true;
}

// ----------------------------------------------------------------------------

template <typename Device>
bool loa::hdlc::Interface<Device>::findWriteResponse()
{
  unsigned int start = 0;
  uint8_t crc = 0;

  if (queue.getSize() < 3)
  {
    return false;
  }

  // find frame seperator (fs)
  while (1)
  {
    if (start == queue.getSize())
    {
      return false;
    } // we iterated out of the deque, and found no fs
    if (queue.get(start).type == frame_sep)
    {
      break;
    } // found fs, we now on assume start points to the fs
    start++;
  }

  // check for msg len
  if ((queue.getSize() - start) < 3)
  {
    return false;
  }

  // check type
  if (not(
          (queue.get(start + 1).type == normal) &
          (queue.get(start + 1).data == 0x21)))
  {
    return false;
  }

  crc = loa::hdlc::crcUpdate(crc, queue.get(start + 1).data);
  if (crc != queue.get(start + 2).data)
  {
    return false;
  }

  return true;
}

// ----------------------------------------------------------------------------

template <typename Device>
void loa::hdlc::Interface<Device>::update()
{
  uint8_t data;
  loa::hdlc::symbol sym = {normal, 0x00};

  while (queue.isNotFull() && Device::read(data))
  {
    if (state == nesc)
    {
      if (data == 0x7d)
      {
        state = esc;
      }
      else if (data == 0x7e)
      {
        sym.type = frame_sep;
        sym.data = 0x00;
        queue.append(sym);
      }
      else
      {
        sym.type = normal;
        sym.data = data;
        queue.append(sym);
      }
    }
    else
    {
      state = nesc;
      if (data == 0x5e)
      {
        sym.type = normal;
        sym.data = 0x7e;
        queue.append(sym);
      }
      else if (data == 0x5d)
      {
        sym.type = normal;
        sym.data = 0x7d;
        queue.append(sym);
      }
    }
  }
}
