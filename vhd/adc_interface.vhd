------------------------------adc_interface.vhd----------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity adc_interface is
  port(clk                 : in  std_logic;
       reset               : in  std_logic;
       adc_data_request    : in  std_logic;
       adc_eocb            : in  std_logic;
       adc_data_ready      : out std_logic;
       adc_convstb         : out std_logic;
       adc_rdb             : out std_logic;
       adc_csb             : out std_logic;
       adc_write_conv_data : out std_logic

       );
end adc_interface;
architecture a of adc_interface is
  type state is (init, wait_data_request, convst, eoc_wait, rd, rd_wr);
  signal current_state                                : state;
  signal next_state                                   : state;

begin
  p_seq : process(clk, reset)
  begin

    if reset = '1' then
      current_state     <= init;
    elsif clk'event and clk = '1' then
        current_state     <= next_state;
    end if;
  end process p_seq;


  p_comb : process ( adc_data_request, adc_eocb, current_state)
    --  le front montant de la requête lance la conversion 

  begin

    case current_state is
      when init =>
        adc_data_ready      <= '0';
        adc_convstb         <= '0';
        adc_rdb             <= '0';
        adc_csb             <= '0';
        adc_write_conv_data <= '0';
	      next_state <= wait_data_request;

      when wait_data_request =>
        adc_data_ready      <= '1';
        adc_convstb         <= '1';
        adc_rdb             <= '1';
        adc_csb             <= '1';
        adc_write_conv_data <= '0';

        if adc_data_request = '1' then
          next_state <= convst;
        else
          next_state <= wait_data_request;
        end if;

      when convst =>
        adc_data_ready      <= '0';
        adc_convstb         <= '0';
        adc_rdb             <= '1';
        adc_csb             <= '1';
        adc_write_conv_data <= '0';

	      next_state <= eoc_wait;

      when eoc_wait =>
        adc_data_ready      <= '0';
        adc_convstb         <= '1';
        adc_rdb             <= '1';
        adc_csb             <= '1';
        adc_write_conv_data <= '0';

        if adc_eocb = '0' then
          next_state <= rd;
        else
          next_state <= eoc_wait;
        end if;

      when rd =>
        adc_data_ready      <= '0';
        adc_convstb         <= '1';
        adc_rdb             <= '0';
        adc_csb             <= '0';
        adc_write_conv_data <= '0';

	      next_state <= rd_wr;

      when rd_wr =>
        adc_data_ready      <= '0';
        adc_convstb         <= '1';
        adc_rdb             <= '0';
        adc_csb             <= '0';
        adc_write_conv_data <= '1';

	      next_state <= wait_data_request;

    end case;


  end process p_comb;

end a;


