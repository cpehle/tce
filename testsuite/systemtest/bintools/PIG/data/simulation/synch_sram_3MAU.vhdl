-------------------------------------------------------------------------------
-- Title      : synchronous static RAM
-- Project    : FlexDSP
-------------------------------------------------------------------------------
-- File       : synch_sram.vhdl
-- Author     : Jaakko Sertamo  <sertamo@vlad.cs.tut.fi>
-- Company    : 
-- Created    : 2003-11-14
-- Last update: 2006-04-05
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-- synchronous static random-access memory with bit write capability
-- - all the control signals are active low
--
-- architecture rtl is synthesizable
-- architecture simulation is for simulation purposes
-- - simulation model can be initialized with a file which containing the
--   the contents of the memory in textual bit-vectors which are mapped to ram
--   starting from the position 0
-------------------------------------------------------------------------------
-- Copyright (c) 2003 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2003-11-14  1.0      sertamo Created
-------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity synch_sram_3MAU is
  generic (
    -- pragma translate_off
    init          : boolean := true;
    INITFILENAME  : string  := "ram_init";
    trace         : boolean := true;
    TRACEFILENAME : string  := "dpram_trace";
    -- trace_mode 0: hex, trace_mode 1: integer, trace_mode 2: unsigned
    trace_mode    : natural := 0;
    -- pragma translate_on
    MAUW          : integer := 8;
    ADDRW         : integer := 11);
  port (
    clk      : in  std_logic;
    d        : in  std_logic_vector(3*MAUW-1 downto 0);
    addr     : in  std_logic_vector(ADDRW-1 downto 0);
    en_x     : in  std_logic;
    wr_x     : in  std_logic;
    bit_wr_x : in  std_logic_vector(3*MAUW-1 downto 0);
    q        : out std_logic_vector(3*MAUW-1 downto 0));
end synch_sram_3MAU;

architecture rtl of synch_sram_3MAU is

  type std_logic_matrix is array (natural range <>) of
    std_logic_vector (3*MAUW-1 downto 0);
  subtype word_line_index is integer range 0 to 2**ADDRW-1;
  signal  mem_r : std_logic_matrix (0 to 2**ADDRW-1);
  signal  line  : word_line_index;

  signal q_r : std_logic_vector(3*MAUW-1 downto 0);
  
begin  -- rtl
  line <= conv_integer (conv_integer(unsigned(addr))/3);

  -- purpose: read & write memory
  -- type   : sequential
  -- inputs : clk
  regs : process (clk)
  begin  -- process regs
    if clk'event and clk = '1' then     -- rising clock edge
      -- Memory read
      if (en_x = '0' and wr_x = '0') then
        -- bypass data to output register
        q_r
          <= (d and (not bit_wr_x)) or (mem_r(line) and bit_wr_x);
        mem_r(line)
          <= (d and (not bit_wr_x)) or (mem_r(line) and bit_wr_x);
      elsif (en_x = '0') then
        q_r <= mem_r(line);
      end if;
    end if;
  end process regs;

  q <= q_r;

end rtl;

-- pragma translate_off
library IEEE, STD;
use std.textio.all;
use IEEE.std_logic_textio.all;

architecture simulation of synch_sram_3MAU is

  type std_logic_matrix is array (natural range <>) of
    std_logic_vector (3*MAUW-1 downto 0);
  subtype word_line_index is integer range 0 to (2**ADDRW)/3-1;
  signal  word_line : word_line_index;

  signal mem_r : std_logic_matrix(0 to (2**ADDRW)/3-1);
  signal q_r   : std_logic_vector(3*MAUW-1 downto 0);

  signal initialized : boolean := false;

begin  -- simulate
  word_line <= conv_integer(conv_integer(unsigned(addr))/3);

  -- purpose: read & write + intialize memory from file
  -- type   : sequential
  -- inputs : clk
  regs_init : process (clk)
    -- input file
    file mem_init           : text;
    -- output file
    file mem_trace          : text;
    variable line_in        : line;
    variable line_out       : line;
    variable word_from_file : std_logic_vector(3*MAUW-1 downto 0);
    variable word_to_mem    : std_logic_vector(3*MAUW-1 downto 0);
    variable i              : natural;
    variable good           : boolean := false;
    
  begin  -- process regs

    if (init = true) then
      if (initialized = false) then
        file_open(mem_init, INITFILENAME, read_mode);
        i := 0;
        while (not endfile(mem_init) and i < mem_r'length) loop
          readline(mem_init, line_in);
          read(line_in, word_from_file, good);
          assert good
            report "Read error in memory initialization file"
            severity failure;
          mem_r(i) <= word_from_file;
          i        := i+1;
        end loop;
        assert (not good)
          report "Memory initialization succesful"
          severity note;
        initialized <= true;
      end if;
    end if;


    if clk'event and clk = '1' then     -- rising clock edge
      -- Memory write
      if (en_x = '0' and wr_x = '0') then
        -- bypass data to output register
        word_to_mem
          := (d and (not bit_wr_x)) or (mem_r(word_line) and bit_wr_x);
        mem_r(word_line) <= word_to_mem;

        -- trace memory to file
        if (trace = true) then
          file_open(mem_trace, TRACEFILENAME, write_mode);
          for i in mem_r'reverse_range loop
            if (i = word_line) then
              if (trace_mode = 0) then
                hwrite(line_out, word_to_mem);
              elsif (trace_mode = 1) then
                write(line_out, conv_integer(signed(word_to_mem)));
              else
                write(line_out, conv_integer(unsigned(word_to_mem)));
              end if;
            else
              if (trace_mode = 0) then
                hwrite(line_out, mem_r(i));
              elsif (trace_mode = 1) then
                write(line_out, conv_integer(signed(mem_r(i))));
              else
                write(line_out, conv_integer(unsigned(mem_r(i))));
              end if;
            end if;
            writeline(mem_trace, line_out);
          end loop;  -- i
          file_close(mem_trace);
        end if;

        -- Memory read
      elsif (en_x = '0') then
        q_r <= mem_r(word_line);
      end if;
    end if;
  end process regs_init;

  q <= q_r;
  
end simulation;

-- pragma translate_on
