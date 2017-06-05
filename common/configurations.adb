with DW1000.Driver; use DW1000.Driver;

package body Configurations
is

   type Preamble_Codes_Array is
     array (Positive range 1 .. 7, DW1000.Driver.PRF_Type)
     of DW1000.Driver.Preamble_Code_Number;


   type PRF_Config_Array is
     array (EVB1000.S1.Bit)
     of DW1000.Driver.PRF_Type;


   type Data_Rate_Config_Array is
     array (EVB1000.S1.Bit,
            EVB1000.S1.Bit)
     of DW1000.Driver.Data_Rates;


   type Channels_Config_Array is
     array (EVB1000.S1.Bit,
            EVB1000.S1.Bit,
            EVB1000.S1.Bit)
     of DW1000.Driver.Channel_Number;

   Preamble_Codes : constant Preamble_Codes_Array :=
     (1 => (PRF_16MHz => 1,
            PRF_64MHz => 9),
      2 => (PRF_16MHz => 3,
            PRF_64MHz => 10),
      3 => (PRF_16MHz => 5,
            PRF_64MHz => 11),
      4 => (PRF_16MHz => 7,
            PRF_64MHz => 17),
      5 => (PRF_16MHz => 4,
            PRF_64MHz => 12),
      6 => (PRF_16MHz => 1,    --  Channel 6 not used
            PRF_64MHz => 9),
      7 => (PRF_16MHz => 8,
            PRF_64MHz => 18));


   PRF_Config : constant PRF_Config_Array :=
     (0 => PRF_16MHz,
      1 => PRF_64MHz);


   Data_Rate_Config : constant Data_Rate_Config_Array :=
     (0 => (0 => Data_Rate_110k,
            1 => Data_Rate_850k),
      1 => (0 => Data_Rate_6M8,
            1 => Data_Rate_6M8));


   Channel_Config : constant Channels_Config_Array :=
     (0 => (0 => (0 => 1,
                  1 => 2),
            1 => (0 => 3,
                  1 => 4)),
      1 => (0 => (0 => 5,
                  1 => 7),
            1 => (0 => 7,
                  1 => 7)));

   procedure Get_Switches_Config
     (Config : out DecaDriver.Core.Configuration_Type)
   is
      Switches : EVB1000.S1.Switch_Bit_Array;

      Channel   : DW1000.Driver.Channel_Number;
      PRF       : DW1000.Driver.PRF_Type;
      Data_Rate : DW1000.Driver.Data_Rates;

   begin

      EVB1000.S1.Read_All (Switches);

      Data_Rate := Data_Rate_Config (Switches (3),
                                     Switches (4));

      PRF       := PRF_Config       (Switches (5));

      Channel   := Channel_Config   (Switches (6),
                                     Switches (7),
                                     Switches (8));

      Config := DecaDriver.Core.Configuration_Type'
        (Channel             => Channel,
         PRF                 => PRF,
         Tx_Preamble_Length  => PLEN_1024,
         Rx_PAC              => PAC_32,
         Tx_Preamble_Code    => Preamble_Codes (Positive (Channel), PRF),
         Rx_Preamble_Code    => Preamble_Codes (Positive (Channel), PRF),
         Use_Nonstandard_SFD => False,
         Data_Rate           => Data_Rate,
         PHR_Mode            => Standard_Frames,
         SFD_Timeout         => 1024 + 64 + 1);

   end Get_Switches_Config;

end Configurations;
