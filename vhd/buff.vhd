------------------------------buff.vhd-----------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity buff is
  port(buff_in  : in  std_logic_vector(7 downto 0);
       buff_oe  : in  std_logic;
       clk      : in  std_logic;
       reset    : in  std_logic;
       buff_out : out std_logic_vector(7 downto 0)) ;
end buff;

architecture a of buff is
begin
  p_buff : process (clk, reset)
  begin
    if reset = '1' then
      buff_out <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (buff_oe = '1') then
        buff_out <= buff_in;
      end if;
    end if;
  end process p_buff;
end a;

