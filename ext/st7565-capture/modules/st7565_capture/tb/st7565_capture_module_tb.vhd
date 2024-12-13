-------------------------------------------------------------------------------
-- Title      : File Stimuli TB
-- Project    :
-------------------------------------------------------------------------------
-- File       : file_tb.vhd
-- Author     : Carl Treudler
-- Company    :
-- Created    : 2020-06-08
-- Last update: 2020-08-06
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Copyright (c) 2020
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.reset_pkg.all;
use work.reg_file_pkg.all;
use work.bus_pkg.all;
use work.st7565_capture_pkg.all;

entity file_tb is
-- empty
end entity file_tb;

architecture str of file_tb is

  signal stim_mosi  : std_logic := '0';
  signal stim_clk   : std_logic := '0';
  signal stim_cs0   : std_logic := '0';
  signal stim_cs1   : std_logic := '0';
  signal stim_rs    : std_logic := '0';
  signal clk        : std_logic := '0';
  signal rst        : std_logic := '1';
  signal capture_in : work.st7565_capture_pkg.dual_st7565_capture_in_type;
  signal bus_o      : busdevice_out_type;
  signal bus_i      : busdevice_in_type;

begin  -- architecture str

  rst <= '0'     after 35 ns;
  clk <= not clk after 10 ns;

  capture_in.mosi  <= stim_mosi;
  capture_in.sck   <= stim_clk;
  capture_in.cs0_n <= stim_cs0;
  capture_in.cs1_n <= stim_cs1;
  capture_in.rs    <= stim_rs;

  bus_i.addr <= (others => '0');
  bus_i.data <= (others => '0');
  bus_i.re   <= '0';
  bus_i.we   <= '0';

  st7565_capture_module_1 : entity work.st7565_capture_module
    generic map (
      BASE_ADDRESS => 0,
      RESET_IMPL   => none)
    port map (
      capture_in_p => capture_in,
      bus_o        => bus_o,
      bus_i        => bus_i,
      reset        => rst,
      clk          => clk);

  ------------------

  file_stimuli : process
    file text_file     : text open read_mode is "single_frame.csv";
    variable text_line : line;
    variable ok        : boolean;
    variable sig       : bit;
    variable step      : natural;
    variable wait_time : time := 0 ns;
    variable last_time : time := 0 ns;

    function to_logic(x : in bit) return std_logic is
    begin
      if x = '1' then
        return '1';
      else
        return '0';
      end if;
    end;

  begin
    while not endfile(text_file) loop
      readline(text_file, text_line);
      -- Skip comments
      if text_line.all'length = 0 or text_line.all(1) = ';' then
        next;
      end if;

      read(text_line, step, ok);
      assert ok
        report "Read 'step' failed for line: " & text_line.all
        severity failure;

      read(text_line, sig, ok);
      assert ok
        report "Read 'cs0' failed for line: " & text_line.all
        severity failure;
      stim_cs0 <= to_logic(sig);

      read(text_line, sig, ok);
      assert ok
        report "Read 'cs1' failed for line: " & text_line.all
        severity failure;
      stim_cs1 <= to_logic(sig);

      read(text_line, sig, ok);
      assert ok
        report "Read 'rs' failed for line: " & text_line.all
        severity failure;
      stim_rs <= to_logic(sig);

      read(text_line, sig, ok);
      assert ok
        report "Read 'clk' failed for line: " & text_line.all
        severity failure;
      stim_clk <= to_logic(sig);

      read(text_line, sig, ok);
      assert ok
        report "Read 'mosi' failed for line: " & text_line.all
        severity failure;
      stim_mosi <= to_logic(sig);

      wait_time := step * 1 ns;
      wait for wait_time - last_time;
      last_time := wait_time;
    end loop;
    wait for 3601 * 1000 ms;  -- this is an arbitrary large time, simulation is terminated by some other means
  end process;

end architecture str;

-------------------------------------------------------------------------------
