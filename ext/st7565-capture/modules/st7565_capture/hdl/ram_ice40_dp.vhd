-------------------------------------------------------------------------------
-- sysMEM EBR ice40 BlockRAM, dual-ported
-- From to Appendix A of MemoryUsageGuideforiCE40Devices.pdf
--
-- 
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ram_ice40_dp is
  generic (
    addr_width : natural := 9;          --512x8
    data_width : natural := 8
    );
  port (
    write_en : in std_logic;
    waddr    : in std_logic_vector (addr_width - 1 downto 0);
    wclk     : in std_logic;

    raddr : in std_logic_vector (addr_width - 1 downto 0);
    rclk  : in std_logic;

    din  : in  std_logic_vector (data_width - 1 downto 0);
    dout : out std_logic_vector (data_width - 1 downto 0)
    );
end ram_ice40_dp;

architecture rtl of ram_ice40_dp is
  type mem_type is array ((2** addr_width) - 1 downto 0) of std_logic_vector(data_width - 1 downto 0);
  signal mem : mem_type;

begin
  process (wclk)                                  -- Write memory.
  begin
    if (wclk'event and wclk = '1') then
      if (write_en = '1') then
        mem(to_integer(unsigned(waddr))) <= din;  -- Using write address bus.
      end if;
    end if;
  end process;

  process (rclk)                                 -- Read memory.
  begin
    if (rclk'event and rclk = '1') then
      dout <= mem(to_integer(unsigned(raddr)));  -- Using read address bus.
    end if;
  end process;

end rtl;
