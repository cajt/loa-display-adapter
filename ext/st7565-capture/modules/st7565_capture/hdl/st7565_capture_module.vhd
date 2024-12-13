-------------------------------------------------------------------------------
-- Title      : st7565_capture
-- Project    : Loa
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.reg_file_pkg.all;
use work.st7565_capture_pkg.all;
use work.xilinx_block_ram_pkg.all;
use work.reset_pkg.all;

-------------------------------------------------------------------------------

entity st7565_capture_module is
  generic (
    BASE_ADDRESS : integer range 0 to 16#7FFF#;
    RESET_IMPL   : reset_type := none);
  port (
    capture_in_p : in  dual_st7565_capture_in_type;
    bus_o        : out busdevice_out_type;
    bus_i        : in  busdevice_in_type;
    reset        : in  std_logic;
    clk          : in  std_logic);


end entity st7565_capture_module;

-------------------------------------------------------------------------------

architecture behavioral of st7565_capture_module is
  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------

  signal reg_o          : reg_file_type(7 downto 0);
  signal reg_i          : reg_file_type(7 downto 0);
  signal bus0_o, bus1_o : busdevice_out_type;
  signal bram0_data     : std_logic_vector(15 downto 0) := (others => '0');
  signal bram0_addr     : std_logic_vector(9 downto 0)  := (others => '0');
  signal bram0_we       : std_logic                     := '0';
  signal bram1_data     : std_logic_vector(15 downto 0) := (others => '0');
  signal bram1_addr     : std_logic_vector(9 downto 0)  := (others => '0');
  signal bram1_we       : std_logic                     := '0';

  signal capture0 : st7565_capture_in_type;
  signal capture1 : st7565_capture_in_type;
begin

  capture0.mosi <= capture_in_p.mosi;
  capture0.cs_n <= capture_in_p.cs0_n;
  capture0.sck  <= capture_in_p.sck;
  capture0.rs   <= capture_in_p.rs;

  capture1.mosi <= capture_in_p.mosi;
  capture1.cs_n <= capture_in_p.cs1_n;
  capture1.sck  <= capture_in_p.sck;
  capture1.rs   <= capture_in_p.rs;

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------

  st7565_capture_0 : entity work.st7565_capture
    generic map (
      RESET_IMPL => RESET_IMPL)
    port map (
      capture_in => capture0,
      addr       => bram0_addr,
      d          => bram0_data,
      we         => bram0_we,
      reset      => reset,
      clk        => clk);

  reg_file_bram_0 : entity work.reg_file_bram_ice40
    generic map (
      BASE_ADDRESS => BASE_ADDRESS,
      RESET_IMPL   => RESET_IMPL)
    port map (
      bus_o       => bus0_o,
      bus_i       => bus_i,
      bram_data_i => bram0_data,
      bram_data_o => open,
      bram_addr_i => bram0_addr,
      bram_we_p   => bram0_we,
      reset       => reset,
      clk         => clk);

  st7565_capture_1 : entity work.st7565_capture
    generic map (
      RESET_IMPL => RESET_IMPL)
    port map (
      capture_in => capture1,
      addr       => bram1_addr,
      d          => bram1_data,
      we         => bram1_we,
      reset      => reset,
      clk        => clk);

  reg_file_bram_1 : entity work.reg_file_bram_ice40
    generic map (
      BASE_ADDRESS => BASE_ADDRESS + 16#1000#,
      RESET_IMPL   => RESET_IMPL)
    port map (
      bus_o       => bus1_o,
      bus_i       => bus_i,
      bram_data_i => bram1_data,
      bram_data_o => open,
      bram_addr_i => bram1_addr,
      bram_we_p   => bram1_we,
      reset       => reset,
      clk         => clk);

  bus_o.data <= bus0_o.data or bus1_o.data;

end behavioral;
