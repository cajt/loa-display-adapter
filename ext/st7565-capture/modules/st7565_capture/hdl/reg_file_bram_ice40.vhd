-------------------------------------------------------------------------------
-- Title      : A Register File Made of Dual Port Block RAM
-------------------------------------------------------------------------------
-- Platform   : lattice ICE40
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: A Larger Register File Using Block RAM.
--
--              A dual port block RAM is interfaced to the internal parallel
--              bus.
--
--              Read A
--              Port A of Block RAM: connected to the internal parallel bus:
--              1024 addresses of 16 bits
--              1024 address = 10 bits (9 downto 0)
--
--              Write B
--              Port B: used by the internal processes of the design.
--              Same configuration
--
-------------------------------------------------------------------------------
-- Copyright (c) 2012 strongly-typed
--               2020 cajt
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.reg_file_pkg.all;
use work.reset_pkg.all;

-------------------------------------------------------------------------------

entity reg_file_bram_ice40 is

  generic (
    -- The module uses 10 bits for 1024 addresses and the base address must be aligned.
    -- Valid BASE_ADDRESSes are 0x0000, 0x0400, 0x0800, ...
    BASE_ADDRESS : integer range 0 to 2**15-1;
    RESET_IMPL   : reset_type := none);

  port (
    -- Interface to the internal parallel bus.
    bus_o : out busdevice_out_type;
    bus_i : in  busdevice_in_type;

    -- Read and write interface to the block RAM for the application.
    bram_data_i : in  std_logic_vector(15 downto 0) := (others => '0');
    bram_data_o : out std_logic_vector(15 downto 0) := (others => '0');
    bram_addr_i : in  std_logic_vector(9 downto 0)  := (others => '0');
    bram_we_p   : in  std_logic                     := '0';

    -- Dummy reset, all signals are initialised.
    reset : in std_logic;
    clk   : in std_logic);

end reg_file_bram_ice40;

-------------------------------------------------------------------------------

architecture str of reg_file_bram_ice40 is

  constant BASE_ADDRESS_VECTOR : std_logic_vector(14 downto 0) :=
    std_logic_vector(to_unsigned(BASE_ADDRESS, 15));

  -- Port A to bus
  constant ADDR_A_WIDTH : positive := 10;
  constant DATA_A_WIDTH : positive := 16;

  -- Port B to application
  constant ADDR_B_WIDTH : positive := 10;
  constant DATA_B_WIDTH : positive := 16;

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  -- Port A - read
  -- Port B - write
  -----------------------------------------------------------------------------

  signal ram_a_addr : std_logic_vector(ADDR_A_WIDTH-1 downto 0) := (others => '0');
  signal ram_a_out  : std_logic_vector(DATA_A_WIDTH-1 downto 0) := (others => '0');

  signal ram_a_en : std_logic := '0';

  signal ram_b_addr : std_logic_vector(ADDR_B_WIDTH-1 downto 0) := (others => '0');
  signal ram_b_in  : std_logic_vector(DATA_B_WIDTH-1 downto 0) := (others => '0');

  signal ram_b_we : std_logic := '0';
  signal ram_b_en : std_logic := '0';

  --
  signal addr_match_a    : std_logic;
  signal bus_o_enable_d  : std_logic := '0';
  signal bus_o_enable_d2 : std_logic := '0';

begin  -- str

  ----------------------------------------------------------------------------
  -- Connections
  ----------------------------------------------------------------------------

  ----------------------------------------------------------------------------
  -- Block RAM as dual port RAM with asymmetrical port widths. 
  ----------------------------------------------------------------------------

  ram_ice40_dp_0 : entity work.ram_ice40_dp
    generic map (
      addr_width => 10,
      data_width => 4)
    port map (
      write_en => ram_b_we,
      waddr    => ram_b_addr,
      wclk     => clk,

      raddr => ram_a_addr,
      rclk  => clk,

      din  => ram_b_in(3 downto 0),
      dout => ram_a_out(3 downto 0)
      );

  ram_ice40_dp_1 : entity work.ram_ice40_dp
    generic map (
      addr_width => 10,
      data_width => 4)
    port map (
      write_en => ram_b_we,
      waddr    => ram_b_addr,
      wclk     => clk,

      raddr => ram_a_addr,
      rclk  => clk,

      din  => ram_b_in(7 downto 4),
      dout => ram_a_out(7 downto 4)
      );

  ram_ice40_dp_2 : entity work.ram_ice40_dp
    generic map (
      addr_width => 10,
      data_width => 4)
    port map (
      write_en => ram_b_we,
      waddr    => ram_b_addr,
      wclk     => clk,

      raddr => ram_a_addr,
      rclk  => clk,

      din  => ram_b_in(11 downto 8),
      dout => ram_a_out(11 downto 8)
      );

  ram_ice40_dp_3 : entity work.ram_ice40_dp
    generic map (
      addr_width => 10,
      data_width => 4)
    port map (
      write_en => ram_b_we,
      waddr    => ram_b_addr,
      wclk     => clk,

      raddr => ram_a_addr,
      rclk  => clk,

      din  => ram_b_in(15 downto 12),
      dout => ram_a_out(15 downto 12)
      );

  ----------------------------------------------------------------------------
  -- Port A: parallel bus
  ----------------------------------------------------------------------------
  -- Always present the address from the parallel bus to the block RAM.
  -- When the bus address matches the address range of the block RAM
  -- route the result of the Block RAM to the parallel bus.
  ram_a_addr <= bus_i.addr(ADDR_A_WIDTH-1 downto 0);

  -- ADDR_A_WIDTH = 10
  -- 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
  --                |<---- match ---->|
  addr_match_a <= '1'       when (bus_i.addr(14 downto ADDR_A_WIDTH) = BASE_ADDRESS_VECTOR(14 downto ADDR_A_WIDTH)) else '0';
  ram_a_en     <= '1';
  bus_o.data   <= ram_a_out when (addr_match_a = '1')                                                               else (others => '0');

  ----------------------------------------------------------------------------
  -- Port B: internal device
  ----------------------------------------------------------------------------

  -- write to the RAM
  ram_b_we   <= bram_we_p;
  ram_b_addr <= bram_addr_i;
  ram_b_in   <= bram_data_i;

end str;

-------------------------------------------------------------------------------
