-------------------------------------------------------------------------------
-- Title      : st7565_capture
-- Project    : LOA Project - HDL Part
-------------------------------------------------------------------------------
-- File       : template_fsm.vhd
-- Author     : Carl Treudler
-- Company    :
-- Created    : 2021-02
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

use work.bus_pkg.all;
use work.st7565_capture_pkg.all;
use work.reset_pkg.all;

entity st7565_capture is
  generic (
    RESET_IMPL : reset_type := none);
  port (
    capture_in : in  st7565_capture_in_type;
    addr       : out std_logic_vector(9 downto 0);
    d          : out std_logic_vector(15 downto 0);
    we         : out std_logic;
    reset      : in  std_logic;
    clk        : in  std_logic);

end entity st7565_capture;

-------------------------------------------------------------------------------
architecture behavioral of st7565_capture is

  type st7565_capture_state_type is (odd, even, inc);

  type input_sync_type is array (0 to 2) of st7565_capture_in_type;

  constant input_sync_type_initial : input_sync_type :=
    (others =>
     (mosi => '0',
      cs_n => '1',
      sck  => '0',
      rs   => '0')
     );

  type st7565_capture_type is record
    state   : st7565_capture_state_type;
    input   : input_sync_type;
    addr    : std_logic_vector(9 downto 0);
    d       : std_logic_vector(15 downto 0);
    we      : std_logic;
    bit_cnt : unsigned(2 downto 0);
  end record;

  constant st7565_capture_type_initial : st7565_capture_type :=
    (state   => odd,
     input   => input_sync_type_initial,
     addr    => (others => '0'),
     d       => (others => '0'),
     we      => '0',
     bit_cnt => (others => '0'));

  signal r, rin : st7565_capture_type := st7565_capture_type_initial;
  signal sync   : input_sync_type     := input_sync_type_initial;


begin

  addr <= r.addr;
  d    <= r.d;
  we   <= r.we;

  -----------------------------------------------------------------------------
  -- Combinatorial part of FSM
  -----------------------------------------------------------------------------
  comb_proc : process(capture_in, r, reset, sync)
    variable v : st7565_capture_type;
  begin

    v    := r;
    v.we := '0';

    -- r.input(0) is synch stage, don't use
    v.input(0) := capture_in;
    -- r.input(1) is useable
    v.input(1) := r.input(0);
    -- r.input(2) is useable, for edge detection (e.g. comparison with cycle before)
    v.input(2) := r.input(1);

    if (r.input(1).cs_n = '0') and (r.input(1).sck = '1') and (r.input(2).sck = '0') then
      -- Chip Select active, rising edge sck
      v.d(15 downto 0) := r.d(14 downto 0) & r.input(1).mosi;
      v.bit_cnt        := r.bit_cnt + 1;
      -- set address
      if (r.bit_cnt = 7) and (r.input(1).rs = '0') then
        if v.d(7 downto 4) = x"b" then
          v.addr  := v.d(3 downto 0) & "000000";
          v.state := odd;
        end if;
      end if;
    end if;

    case r.state is
      when odd =>
        if (r.bit_cnt = 7) and (r.input(1).rs = '1') and (r.input(1).sck = '1') and (r.input(2).sck = '0') then
          v.state := even;
        end if;
      when even =>
        if (r.bit_cnt = 7) and (r.input(1).rs = '1') and (r.input(1).sck = '1') and (r.input(2).sck = '0')then
          v.we    := '1';
          v.state := inc;
        end if;
      when inc =>
        v.addr  := std_logic_vector(unsigned(v.addr) + 1);
        v.state := odd;
    end case;

    -- sync reset
    --if (RESET_IMPL = sync) then
    --  if reset = '1' then
    --    v := st7565_capture_type_initial;
    --  end if;
    --end if;

    --if (RESET_IMPL = sync) and (reset = '1') then
    --  v := st7565_capture_type_initial;
    --end if;

    rin <= v;
  end process comb_proc;

----------------------------------------------------------------------------
-- Sequential part of finite state machine (FSM)
----------------------------------------------------------------------------
  reset_async : if RESET_IMPL = async generate
    seq_proc : process(clk, reset)
    begin
      if reset = '1' then
        r <= st7565_capture_type_initial;  -- async reset
      elsif rising_edge(clk) then
        r <= rin;
      end if;
    end process seq_proc;
  end generate reset_async;

  reset_sync : if not (RESET_IMPL = async) generate
    seq_proc : process(clk)
    begin
      if rising_edge(clk) then
        r <= rin;
      end if;
    end process seq_proc;
  end generate reset_sync;

end architecture behavioral;
