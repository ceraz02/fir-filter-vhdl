library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_1 is
  port(clk, reset, enable : in  std_logic;
       shift_in           : in  std_logic_vector (7 downto 0);
       shift_out          : out std_logic_vector (7 downto 0)
       );
end register_1;

architecture a of register_1 is
  signal register_signal : std_logic_vector(7 downto 0);

begin
  p_register : process (clk, reset)
  begin
    if reset = '1' then
      register_signal <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (enable = '1') then
        register_signal <= shift_in;
      end if;
    end if;
  end process p_register;

  shift_out <= register_signal;
end a;
