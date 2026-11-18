library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm is
  port (clk                     : in  std_logic;
        reset                   : in  std_logic;
        adc_data_ready          : in  std_logic;
        adc_data_request        : out std_logic;
        dac_conv_data           : out std_logic;
        rom_address             : out std_logic_vector(4 downto 0);
        delay_line_address      : out std_logic_vector(4 downto 0);
        delay_line_sample_shift : out std_logic;
        accu_ctrl               : out std_logic;
        buff_oe                 : out std_logic);
end entity fsm;

architecture behav of fsm is
  type state is (init, wait_data, req_data, wait_adc, update_delay_line, calcul, store_res, send_data);
  signal current_state : state;
  signal next_state    : state;
  signal counter       : std_logic_vector(4 downto 0);
begin

  p_seq: process (clk, reset)
  begin
    if reset = '1' then
      current_state <= init;
      counter <= (others => '0');  -- Réinitialisation propre
    elsif clk'event and clk = '1' then
        current_state <= next_state;

        if current_state = calcul then
          if unsigned(counter) < 31 then
            --counter <= std_logic_vector(resize(unsigned(counter) + 1, counter'length));
	    counter <= std_logic_vector(unsigned(counter) + 1);
          else
            counter <= (others => '0');
          end if;
        end if;
    end if;
  end process;

  p_comb: process (adc_data_ready, current_state, counter)
  begin
    -- Initialisation des sorties à zéro
    adc_data_request <= '0';
    dac_conv_data <= '0';
    rom_address <= (others => '0');
    delay_line_address <= (others => '0');
    delay_line_sample_shift <= '0';
    accu_ctrl <= '0';
    buff_oe <= '0';

    case current_state is
      when init =>
        next_state <= wait_data;

      when wait_data =>
        if adc_data_ready = '1' then
          next_state <= req_data;
        else
          next_state <= wait_data;
        end if;

      when req_data =>
        adc_data_request <= '1';
        next_state <= wait_adc;

      when wait_adc =>
        if adc_data_ready = '1' then
          next_state <= update_delay_line;
        else
          next_state <= wait_adc;
        end if;

      when update_delay_line =>
        delay_line_sample_shift <= '1';
        next_state <= calcul;

      when calcul =>
        rom_address <= counter;
        delay_line_address <= counter;

        if unsigned(counter) = 0 then
          accu_ctrl <= '1';
        end if;

        if unsigned(counter) >= 31 then
          next_state <= store_res;
        else
          next_state <= calcul;
        end if;

      when store_res =>
        buff_oe <= '1';
        next_state <= send_data;

      when send_data =>
        dac_conv_data <= '1';
        next_state <= wait_data;
    end case;
  end process;

end architecture behav;

