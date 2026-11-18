library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

library modelsim_lib;
  use modelsim_lib.util.all;

library lib_RTL;
  --library lib_SYNTH;

entity bench_filter is
end entity; -- bench_filter

architecture arch of bench_filter is

  component filter
    port (filter_in   : in  std_logic_vector(7 downto 0);
          clk         : in  std_logic;
          reset       : in  std_logic;
          adc_eocb    : in  std_logic;
          adc_convstb : out std_logic;
          adc_rdb     : out std_logic;
          adc_csb     : out std_logic;
          dac_wrb     : out std_logic;
          dac_csb     : out std_logic;
          dac_ldacb   : out std_logic;
          dac_clrb    : out std_logic;
          filter_out  : out std_logic_vector(7 downto 0));
  end component;

  signal CLK   : std_logic := '0';
  signal RESET : std_logic;
  --    signal uC_Config  : std_logic_vector(15 downto 0);
  signal Filter_In                             : std_logic_vector(7 downto 0) := "00000000";
  signal Filter_Out                            : std_logic_vector(7 downto 0);
  signal ADC_eocb                              : std_logic;
  signal ADC_convstb                           : std_logic;
  signal ADC_rdb                               : std_logic;
  signal ADC_csb                               : std_logic;
  signal DAC_wrb                               : std_logic;
  signal DAC_csb                               : std_logic;
  signal DAC_ldacb                             : std_logic;
  signal DAC_clrb                              : std_logic;
  signal Buff_OE                               : std_logic;
  signal ADC_convstb_delayed, ADC_eocb_delayed : std_logic;
  signal Accu_out                              : std_logic_vector(20 downto 0);
  type tab_rom is array (0 to 31) of std_logic_vector(7 downto 0);
  constant filter_rom : tab_rom :=
    (0   => "00001101" , 1 => "00010101" , 2 => "00011111" , 3 => "00101100" ,
      --  0x0D               0x15               0x1F               0x2C
      4  => "00111100" , 5 => "01001101" , 6 => "01100001" , 7 => "01110101" ,
      --  0x3C               0x4D               0x61               0x75
      8  => "10001010" , 9 => "10011111" , 10 => "10110011" , 11 => "11000101" ,
      --  0x8A               0x9F               0xB3               0xC5
      12 => "11010100" , 13 => "11100001" , 14 => "11101001" , 15 => "11101110" ,
      --  0xD4               0xE1               0xE9               0xEE
      16 => "11101110" , 17 => "11101001" , 18 => "11100001" , 19 => "11010100" ,
      --  0xEE               0xE9               0xE1               0xD4
      20 => "11000101" , 21 => "10110011" , 22 => "10011111" , 23 => "10001010" ,
      --  0xC5               0xB3               0x9F               0x8A
      24 => "01110101" , 25 => "01100001" , 26 => "01001101" , 27 => "00111100" ,
      --  0x75               0x61               0x4D               0x3C
      28 => "00101100" , 29 => "00011111" , 30 => "00010101" , 31 => "00001101") ;
  --  0x2C               0x1F               0x15               0xD

begin

  DUT: filter
    port map (
      clk         => CLK,
      reset       => RESET,
      adc_eocb    => ADC_eocb,
      adc_convstb => ADC_convstb,
      adc_rdb     => ADC_rdb,
      adc_csb     => ADC_csb,
      dac_wrb     => DAC_wrb,
      dac_csb     => DAC_csb,
      dac_ldacb   => DAC_ldacb,
      dac_clrb    => DAC_clrb,
      filter_out  => Filter_Out,
      filter_in   => Filter_In);

  CLK   <= not(CLK) after 10 ns;
  RESET <= '1', '0' after 45 ns;



      

  -- purpose: time constraints verification 
  -- type   : combinational
  -- inputs : ADC_convstb
  -- outputs: 

  verif_time: process
    variable t : time;
  begin -- process verif_time
    wait on ADC_convstb;
    if ADC_convstb'event and ADC_convstb = '0' then
      t := ADC_rdb'last_event;
      assert t >= (30 ns) report "new conversion starts 30 ns after a read" severity warning;
      wait on ADC_convstb;
      t := ADC_convstb_delayed'last_event;
      assert t >= (20 ns) report "a conversion pulse is at least 20 ns" severity warning;
      wait on ADC_eocb;
      t := ADC_convstb_delayed'last_event;
      assert (t <= (420 ns) and t >= (120 ns)) report "eoc is enabled between 120 ns and 420 ns after a start conversion" severity warning;
      wait on ADC_eocb;
      t := ADC_eocb_delayed'last_event;
      assert (t <= (110 ns) and t >= (70 ns)) report "eoc pulse is at least 70 ns and at most 110 ns" severity warning;

    end if;

   end process verif_time;

    

  -- observation de signaux internes

  spy_process: process
  begin -- process spy_process
    init_signal_spy("/bench_filter/DUT/Accu_out", "accu_out", 1, - 1);
    init_signal_spy("/bench_filer/DUT/Buff_OE", "buff_oe", 1, - 1);

    wait;
      end process spy_process;
 

  Filter_in_rep_impuls: process
    variable j : natural range 0 to 31;
  begin -- process Filter_in_rep_impuls
    --wait until enable='1';
    for i in 0 to 31 loop

      wait until ADC_eocb = '0';
      j := i;
      if i = 0 then
        Filter_in <= "10000001";

      else
        Filter_in <= (others => '0');
      end if;
      wait until buff_OE = '1';
      -- Completer le assert avec la ROM des coefficients fournie
      --  assert (Accu_out(7 downto 0)= ?? )  report "error rep_impul" severity error;
    end loop; -- i
  end process Filter_in_rep_impuls;

  -- Test le bon fonctionnement du CNA;

  process_ADC: process (ADC_Convstb)
  begin
    if ADC_Convstb'event and ADC_Convstb = '0' then
      ADC_eocb <= '1', '0' after 300 ns, '1' after 400 ns;
    end if;
    end process;  -- process_ADC


end architecture; -- arch

--NB: les deux process suivant sont donnes "en l'etat" comme reference
--    de l'access aux fichiers en lecture/ecriture
--    leur fonctionnement n'est pas garanti


--LECTURE: process
-- variable L: line;	-- le type LINE est un pointeur
-- file ENTREES: text open READ_MODE is "entrees.dat";	-- fichier spécifié
-- variable A: std_logic_vector(7 downto 0);	 -- variables à lire
--begin

-- wait on ADC_rdb='0' and ADC_csb='0';
-- readline(ENTREES, L);	-- lecture d'une nouvelle ligne dans le fichier
-- read(L, A);	-- lecture dans la ligne du 1er symbole => BIT
-- Filter_in <= A;	-- utilisation pour la simulation
--end process LECTURE;
----

      
--ECRITURE: process
-- variable L: line;
-- file SORTIES: text open WRITE_MODE is "sorties.dat";
--begin
--  wait on DAC_wrb='0' and DAC_csb='0';
--  if DAC_ldacb='0' and DAC_clrb='1' then
--    write(L, Filter_Out);	-- écriture de S dans la ligne
--    writeline(SORTIES, L); -- écriture de la ligne dans le fichier
-- else
--   write("00000000", Filter_Out);	-- écriture de S dans la ligne
--    writeline(SORTIES, L); -- écriture de la ligne dans le fichier
--  end if;
--end process ECRITURE;



