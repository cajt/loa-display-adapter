-------------------------------------------------------------------------------
-- Title      : st7565_capture
-- Project    : Loa
-------------------------------------------------------------------------------
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.bus_pkg.all;
use work.reset_pkg.all;

-------------------------------------------------------------------------------

package st7565_capture_pkg is

  type st7565_capture_in_type is record
    mosi : std_logic;
    cs_n : std_logic;
    sck  : std_logic;
    rs   : std_logic;
  end record;

  type dual_st7565_capture_in_type is record
    mosi  : std_logic;
    cs0_n : std_logic;
    cs1_n : std_logic;
    sck   : std_logic;
    rs    : std_logic;
  end record;

  -----------------------------------------------------------------------------
  -- Component declarations
  -----------------------------------------------------------------------------
  component st7565_capture
    generic (
      RESET_IMPL : reset_type := none);
    port (
      -- signals to and from real hardware
      capture_in : in st7565_capture_in_type;

      -- signals to other logic in FPGA
      addr  : out std_logic_vector(9 downto 0);
      d     : out std_logic_vector(15 downto 0);
      we    : out std_logic;
      reset : in  std_logic;
      clk   : in  std_logic);
  end component;


  component st7565_capture_module
    generic (
      BASE_ADDRESS : integer range 0 to 16#7FFF#;
      RESET_IMPL   : reset_type := none);
    port (
      capture_in_p : in  dual_st7565_capture_in_type;
      bus_o        : out busdevice_out_type;
      bus_i        : in  busdevice_in_type;
      reset        : in  std_logic;
      clk          : in  std_logic);
  end component;

  component reg_file_bram_ice40 is
    generic (
      BASE_ADDRESS : integer range 0 to 2**15-1;
      RESET_IMPL   : reset_type);
    port (
      bus_o       : out busdevice_out_type;
      bus_i       : in  busdevice_in_type;
      bram_data_i : in  std_logic_vector(15 downto 0) := (others => '0');
      bram_data_o : out std_logic_vector(15 downto 0) := (others => '0');
      bram_addr_i : in  std_logic_vector(9 downto 0)  := (others => '0');
      bram_we_p   : in  std_logic                     := '0';
      reset       : in  std_logic;
      clk         : in  std_logic);
  end component reg_file_bram_ice40;

end st7565_capture_pkg;

-------------------------------------------------------------------------------
