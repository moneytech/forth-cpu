-- Richard James Howe.
--  This file is the top level of the project.
--  It presents an interface between the CPU,
--  RAM, and all the I/O modules.
--
-- @author         Richard James Howe.
-- @copyright      Copyright 2013 Richard James Howe.
-- @license        LGPL      
-- @email          howe.rj.89@googlemail.com
library ieee,work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
    generic
    (
        clk_freq:   positive := 100000000 -- Hz
    );
    port
    (
        clk:        in  std_logic := 'X';  -- clock
        -- Buttons
        btnu:       in  std_logic                    :=            'X';  -- button up
        btnd:       in  std_logic                    :=            'X';  -- button down
        btnc:       in  std_logic                    :=            'X';  -- button centre
        btnl:       in  std_logic                    :=            'X';  -- button left
        btnr:       in  std_logic                    :=            'X';  -- button right
        -- Switches
        sw:         in  std_logic_vector(7 downto 0) := (others => 'X'); -- switches
        -- Simple LED outputs
        an:         out std_logic_vector(3 downto 0) := (others => '0'); -- anodes   7 segment display
        ka:         out std_logic_vector(7 downto 0) := (others => '0'); -- kathodes 7 segment display
        ld:         out std_logic_vector(7 downto 0) := (others => '0'); -- leds
        -- UART
        rx:         in  std_logic                    :=            'X';  -- uart rx 
        tx:         out std_logic                    :=            '0';  -- uart tx
        -- VGA
        red:        out std_logic_vector(2 downto 0) := (others => '0'); 
        green:      out std_logic_vector(2 downto 0) := (others => '0'); 
        blue:       out std_logic_vector(1 downto 0) := (others => '0'); 
        hsync:      out std_logic                    :=            '0';
        vsync:      out std_logic                    :=            '0'
    );
end;

architecture behav of top_level is

    signal rst: std_logic := '0';

    -- H2 IO interface signals.
    signal      cpu_io_wr:         std_logic;
    signal      cpu_io_din:        std_logic_vector(15 downto 0):= (others => '0');
    signal      cpu_io_dout:       std_logic_vector(15 downto 0):= (others => '0');
    signal      cpu_io_daddr:      std_logic_vector(15 downto 0):= (others => '0');
    -- CPU memory signals
    signal      cpu_pc:            std_logic_vector(12 downto 0):= (others => '0');
    signal      cpu_insn:          std_logic_vector(15 downto 0):= (others => '0');
    signal      cpu_dwe:           std_logic:= '0';   
    signal      cpu_din:           std_logic_vector(15 downto 0):= (others => '0');
    signal      cpu_dout:          std_logic_vector(15 downto 0):= (others => '0');
    signal      cpu_daddr:         std_logic_vector(12 downto 0):= (others => '0');
    -- VGA interface signals
    signal      R_internal:        std_logic:= '0';
    signal      G_internal:        std_logic:= '0';
    signal      B_internal:        std_logic:= '0';

    signal      clk25MHz:          std_logic:= '0';
    signal      clk50MHz:          std_logic:= '0';

    signal      vga_ram_a_dwe:     std_logic:= '0';
    signal      vga_ram_a_dout:    std_logic_vector(7 downto 0):= (others => '0');
    signal      vga_ram_a_din:     std_logic_vector(7 downto 0):= (others => '0');
    signal      vga_ram_a_addr:    std_logic_vector(11 downto 0):= (others => '0');

    signal      vga_ram_b_dwe:     std_logic:= '0';
    signal      vga_ram_b_dout:    std_logic_vector(7 downto 0):=  (others => '0');
    signal      vga_ram_b_din:     std_logic_vector(7 downto 0):=  (others => '0');
    signal      vga_ram_b_addr:    std_logic_vector(11 downto 0):= (others => '0');

    signal      vga_rom_addr:      std_logic_vector(11 downto 0):= (others => '0');
    signal      vga_rom_dout:      std_logic_vector(7 downto 0):=  (others => '0');

    signal      crx_oreg:          std_logic_vector(7 downto 0):=  (others => '0');
    signal      cry_oreg:          std_logic_vector(7 downto 0):=  (others => '0');
    signal      ctl_oreg:          std_logic_vector(7 downto 0):=  (others => '0');
    -- Basic IO register
    signal      an_c,an_n:         std_logic_vector(3 downto 0):=  (others => '0');
    signal      ka_c,ka_n:         std_logic_vector(7 downto 0):=  (others => '0');
    signal      ld_c,ld_n:         std_logic_vector(7 downto 0):=  (others => '0');

    signal      ocrx_c, ocrx_n:    std_logic_vector(7 downto 0):=  (others => '0');
    signal      ocry_c, ocry_n:    std_logic_vector(7 downto 0):=  (others => '0');
    signal      octl_c, octl_n:    std_logic_vector(7 downto 0):=  (others => '0');

    signal      txt_addr_c, txt_addr_n: std_logic_vector(11 downto 0):= (others => '0');
    signal      txt_din_c, txt_din_n:   std_logic_vector(7 downto 0) := (others => '0');
begin
------- TEMPORARY ASSIGNMENTS -------------------------------------------------
    rst     <=  '0';
    red     <=  R_internal & R_internal & R_internal;
    green   <=  G_internal & G_internal & G_internal;
    blue    <=  B_internal & B_internal;
-------------------------------------------------------------------------------
-- The Main components
-------------------------------------------------------------------------------

    -- The CPU:
    h2_instance: entity work.h2
    port map(
        clk     =>  clk,
        rst     =>  rst,
        pco     =>  cpu_pc, 
        insn    =>  cpu_insn,  

        io_wr   =>  cpu_io_wr,
        io_din  =>  cpu_io_din,
        io_dout =>  cpu_io_dout,
        io_daddr=>  cpu_io_daddr,

        dwe     =>  cpu_dwe,
        din     =>  cpu_din,
        dout    =>  cpu_dout,
        daddr   =>  cpu_daddr
            );

    -- RAM for the CPU
    mem_h2_instance: entity work.mem_h2
    port map(
        a_clk => clk,
        a_dwe => '0',
        a_addr => cpu_pc,
        a_din => X"0000",
        a_dout => cpu_insn,

        b_clk => clk,
        b_dwe => cpu_dwe,
        b_addr => cpu_daddr,
        b_din => cpu_dout,
        b_dout => cpu_din
            );
-------------------------------------------------------------------------------
-- IO
-------------------------------------------------------------------------------

  -- Xilinx Application Note:
  -- It seems like it buffers the clock correctly here, so no need to
  -- use a DCM.
            
  --Clock divider /2. 
  clk50MHz <= '0' when rst = '1' else
              not clk50MHz when rising_edge(clk);

  --Clock divider /2. Pixel clock is 25MHz
  clk25MHz <= '0' when rst = '1' else
              not clk25MHz when rising_edge(clk50MHz);
  --

   io_nextState: process(clk,rst)
   begin
       if rst='1' then
           an_c   <=  (others => '0');
           ka_c   <=  (others => '0');
           ld_c   <=  (others => '0');

           ocrx_c <= (others => '0');
           ocry_c <= (others => '0');
           octl_c <= (others => '0');

           txt_addr_c <= (others => '0');
           txt_din_c  <= (others => '0');
       elsif rising_edge(clk) then
           an_c <= an_n;
           ka_c <= ka_n;
           ld_c <= ld_n;

           ocrx_c <= ocrx_n;
           ocry_c <= ocry_n;
           octl_c <= octl_n;

           txt_addr_c <= txt_addr_n;
           txt_din_c  <= txt_din_n;
       end if;
   end process;



  io_select: process(
      cpu_io_wr,
      cpu_io_dout,
      cpu_io_daddr,

      an_c,
      ka_c,
      ld_c,

      ocrx_c,
      ocry_c,
      octl_c,

      txt_addr_c,
      txt_din_c,

      sw,
      rx,
      btnu,
      btnd,
      btnl,
      btnr,
      btnc
  )
  begin
      -- Outputs
      an <= an_c;
      ka <= ka_c;
      ld <= ld_c;
      crx_oreg <= ocrx_c;
      cry_oreg <= ocry_c;
      ctl_oreg <= octl_c;

      vga_ram_a_addr <= txt_addr_c;
      vga_ram_a_din  <= txt_din_n; -- CHECK

      -- Register defaults
      an_n <= an_c;
      ka_n <= ka_c;
      ld_n <= ld_c;

      ocrx_n <= ocrx_c;
      ocry_n <= ocry_c;
      octl_n <= octl_c;

      txt_addr_n <= txt_addr_c;
      txt_din_n  <= txt_din_c;

      cpu_io_din <= (others => '0');

      vga_ram_a_dwe <= '0';

      if cpu_io_wr = '1' then
          -- Write output.
          case cpu_io_daddr(3 downto 0) is
                when "0000" => -- LEDs 7 Segment displays.
                    an_n <= cpu_io_dout(3 downto 0);
                    ka_n <= cpu_io_dout(15 downto 8);
                when "0001" => -- LEDs, next to switches.
                    ld_n <= cpu_io_dout(7 downto 0);
                when "0010" => -- VGA, cursor registers.
                    ocrx_n <= cpu_io_dout(7 downto 0);
                    ocry_n <= cpu_io_dout(15 downto 8);
                when "0011" => -- VGA, control register.
                    octl_n <= cpu_io_dout(7 downto 0);
                when "0100" => -- VGA update address register.
                    txt_addr_n <= cpu_io_dout(11 downto 0);
                when "0101" => -- VGA, update register, write out, CHECK.
                    txt_din_n  <= cpu_io_dout(7 downto 0);
                    vga_ram_a_dwe <= '1';
                when "0110" =>
                when "0111" =>
                when "1000" =>
                when "1001" =>
                when "1010" =>
                when "1011" =>
                when "1100" =>
                when "1101" =>
                when "1110" =>
                when "1111" =>
                when others =>
            end case;
      else
          -- Get input.
          case cpu_io_daddr(3 downto 0) is
                when "0000" => cpu_io_din <=
                            "0000000000" & rx & btnu & btnd & btnl & btnr & btnc;
                when "0001" => cpu_io_din <=
                            "00000000" & sw;
                when "0010" => cpu_io_din <= (others => '0');
                            -- VGA, Read VGA text buffer.
                            cpu_io_din <= X"00" & vga_ram_a_dout;
                when "0011" => cpu_io_din <= (others => '0');
                when "0100" => cpu_io_din <= (others => '0');
                when "0101" => cpu_io_din <= (others => '0');
                when "0110" => cpu_io_din <= (others => '0');
                when "0111" => cpu_io_din <= (others => '0');
                when "1000" => cpu_io_din <= (others => '0');
                when "1001" => cpu_io_din <= (others => '0');
                when "1010" => cpu_io_din <= (others => '0');
                when "1011" => cpu_io_din <= (others => '0');
                when "1100" => cpu_io_din <= (others => '0');
                when "1101" => cpu_io_din <= (others => '0');
                when "1110" => cpu_io_din <= (others => '0');
                when "1111" => cpu_io_din <= (others => '0');
                when others => cpu_io_din <= (others => '0');
            end case;
      end if;
  end process;

  uart_loop: entity work.uart_top port map(
      clock_y3 => clk,
      user_reset => rst,
      usb_rs232_rxd => rx,
      usb_rs232_txd => tx
    );
  
  U_VGA : entity work.vga80x40 port map (
    reset       => rst,
    clk25MHz    => clk25MHz,
    TEXT_A      => vga_ram_b_addr,
    TEXT_D      => vga_ram_b_dout,
    FONT_A      => vga_rom_addr,
    FONT_D      => vga_rom_dout,
    ocrx        => crx_oreg,
    ocry        => cry_oreg,
    octl        => ctl_oreg,
    R           => R_internal,
    G           => G_internal,
    B           => B_internal,
    hsync       => hsync,
    vsync       => vsync
  );

  U_TEXT: entity work.mem_text port map (
    a_clk  => clk25MHz,
    a_dwe  => vga_ram_a_dwe,
    a_addr => vga_ram_a_addr,
    a_din  => vga_ram_a_din,
    a_dout => vga_ram_a_dout,

    b_clk  => clk25MHz,
    b_dwe  => vga_ram_b_dwe,
    b_addr => vga_ram_b_addr,
    b_din  => vga_ram_b_din,
    b_dout => vga_ram_b_dout
    );
  U_FONT: entity work.mem_font port map (
    a_clk => clk25MHz,
    a_addr => vga_rom_addr,
    a_dout => vga_rom_dout
  );
     
--  vga_ram_a_dwe  <= '0';
  vga_ram_b_dwe  <= '0';
  vga_ram_b_din  <= (others => '0');
--  vga_ram_a_din  <= (others => '0');
--  vga_ram_a_addr <= (others => '0');

--  crx_oreg    <= std_logic_vector(TO_UNSIGNED(40, 8));
--  cry_oreg    <= std_logic_vector(TO_UNSIGNED(20, 8));
--  ctl_oreg    <= "11110010";

-------------------------------------------------------------------------------
end architecture;
