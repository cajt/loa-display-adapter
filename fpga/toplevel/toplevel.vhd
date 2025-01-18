-------------------------------------------------------------------------------
-- Test using one ST7565 Capture module
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library work;
use work.hdlc_pkg.all;
use work.bus_pkg.all;
use work.reset_pkg.all;
use work.reset_gen_pkg.all;
use work.reg_file_pkg.all;
use work.fifo_sync_pkg.all;
use work.utils_pkg.all;
use work.uart_pkg.all;
use work.st7565_capture_pkg.all;

entity toplevel is
  generic (RESET_IMPL : reset_type := sync);
  port(
    mosi_p  : in std_logic;
    sck_p   : in std_logic;
    cs0_n_p : in std_logic;
    cs1_n_p : in std_logic;
    rs_p    : in std_logic;

    led0_p    : out std_logic;
    led1_p    : out std_logic;
    uart_rx_p : in  std_logic;
    uart_tx_p : out std_logic;
    uart2_rx_p : in  std_logic;
    uart2_tx_p : out std_logic;

    debug0_p : out std_logic;
    debug1_p : out std_logic;

    clk_p : in std_logic
    );
end toplevel;

architecture Behavioral of toplevel is
  component pll is
    port (
      clock_in : in std_logic;
      clock_out : out std_logic;
      locked : out std_logic
    );
  end component pll;

  signal reset : std_logic;
  signal reset_n : std_logic_vector(10 downto 0) := (others => '0'); 

  signal bus_to_master  : busmaster_in_type  := (data => (others => '0'));
  signal master_to_bus  : busmaster_out_type := (addr => (others => '0'), data => (others => '0'), re => '0', we => '0');
  signal reg_to_master  : busdevice_out_type := (data => (others => '0'));
  signal cap0_to_master : busdevice_out_type := (data => (others => '0'));
  signal cap1_to_master : busdevice_out_type := (data => (others => '0'));

  signal reg_out : std_logic_vector(15 downto 0);
  signal reg_in  : std_logic_vector(15 downto 0);

  signal led : std_logic := '0';
  signal clk : std_logic := '0';
  signal dbg : std_logic := '0';

  signal uart_rx    : std_logic := '0';
  signal uart_tx    : std_logic := '0';
  signal pll_locked : std_logic;

  signal capture_in : dual_st7565_capture_in_type;

begin
  led0_p <= led;                        -- blinking
  led1_p <= reg_out(0);

  debug0_p <= uart_rx;
  debug1_p <= uart_tx;
  -- debug1_p <= reset;

  reg_in(0) <= reg_out(0);
  reg_in(1) <= reg_out(1);
  reg_in(2) <= led;
  reg_in(15 downto 3) <= (others => '0');

  -- we combine the two sets of UART pins on signal level
  -- it is expected that both inputs are high on idle.
  uart_rx   <= uart_rx_p and uart2_rx_p;
  uart_tx_p <= uart_tx;
  uart2_tx_p <= uart_tx;

  capture_in.mosi  <= mosi_p;
  capture_in.cs0_n <= cs0_n_p;
  capture_in.cs1_n <= cs1_n_p;
  capture_in.sck   <= sck_p;
  capture_in.rs    <= rs_p;

  st7565_capture_module_1 : entity work.st7565_capture_module
    generic map (
      BASE_ADDRESS => 16#1000#,
      RESET_IMPL   => RESET_IMPL)
    port map (
      capture_in_p => capture_in,
      bus_o        => cap0_to_master,
      bus_i        => master_to_bus,
      reset        => reset,
      clk          => clk);

  -----------------------------------------------------------------------------
  -- Something blinking
  -----------------------------------------------------------------------------
  process(clk)
    variable cnt : integer range 0 to 15000000 := 0;
  begin
    if rising_edge(clk) then
      if cnt = 15000000 then
        cnt := 0;
        led <= not led;
      else
        cnt := cnt + 1;
      end if;
    end if;
  end process;


  -----------------------------------------------------------------------------
  -- HDLC Busmaster with UART
  -----------------------------------------------------------------------------
  hdlc_busmaster_with_support : entity work.hdlc_busmaster_with_support
    generic map (
      DIV_RX     => 3,
      DIV_TX     => 15,
      RESET_IMPL => RESET_IMPL)
    port map (
      rx    => uart_rx,
      tx    => uart_tx,
      bus_o => master_to_bus,
      bus_i => bus_to_master,
      reset => reset,
      clk   => clk);

  -----------------------------------------------------------------------------
  -- LOA Bus
  -- here we collect the data-outputs of the devices
  -----------------------------------------------------------------------------
  bus_to_master.data <= reg_to_master.data or
                        cap0_to_master.data;

  -----------------------------------------------------------------------------
  -- Input & output periphery register
  -----------------------------------------------------------------------------

st : entity work.peripheral_register
    generic map(
      BASE_ADDRESS => 16#0000#,
      RESET_IMPL   => RESET_IMPL)
    port map(
      dout_p => reg_out,
      din_p  => reg_in,
      bus_o  => reg_to_master,
      bus_i  => master_to_bus,
      reset  => reset,
      clk    => clk);

  -----------------------------------------------------------------------------
  -- PLL & Reset generator
  -----------------------------------------------------------------------------
  -- process(clk)
  -- begin
  --   if rising_edge(clk) then
  --     reset <= not pll_locked;
  --   end if;
  -- end process;


  -- this generates a long reset. Uses DFF initalized to '0' (ice40!)
  -- 
  process(clk)
  begin
    if rising_edge(clk) then
      reset_n <= reset_n (9 downto 0) & pll_locked;
    end if;
  end process;

  reset <= not reset_n(10);

  pll_inst : pll
  port map(
    clock_in => clk_p,
    clock_out => clk,
    locked => pll_locked
  );


end Behavioral;
