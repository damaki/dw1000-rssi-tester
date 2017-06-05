with Ada.Real_Time;    use Ada.Real_Time;
with Configurations;
with DecaDriver.Core;  use DecaDriver.Core;
with DecaDriver.Tx;
with DW1000.Driver;    use DW1000.Driver;
with DW1000.Types;     use DW1000.Types;
with EVB1000_Tx_Power;
with EVB1000.LCD;

procedure Transmitter
is

   Inter_Frame_Period : constant
     array (DW1000.Driver.Data_Rates)
     of Ada.Real_Time.Time_Span :=
       (Data_Rate_110k => Microseconds (12500), --  80 pkt/s
        Data_Rate_850k => Microseconds (4000),  --  250 pkt/s
        Data_Rate_6M8  => Microseconds (3125)); --  320 pkt/s

   Tx_Packet      : DW1000.Types.Byte_Array (1 .. 125);

   Current_Config : DecaDriver.Core.Configuration_Type;
   New_Config     : DecaDriver.Core.Configuration_Type;

   Next_Tx_Time   : Ada.Real_Time.Time;

   procedure Update_LCD
   is

      Channel_Number_Str : constant array (Positive range 1 .. 7) of Character :=
        (1 => '1',
         2 => '2',
         3 => '3',
         4 => '4',
         5 => '5',
         6 => '6',
         7 => '7');

      PRF_Str : constant array (PRF_Type) of String (1 .. 5) :=
        (PRF_16MHz => "16MHz",
         PRF_64MHz => "64MHz");

      Data_Rate_Str : constant array (Data_Rates) of String (1 .. 4) :=
        (Data_Rate_110k => "110K",
         Data_Rate_850k => "850K",
         Data_Rate_6M8  => "6.8M");

   begin

      EVB1000.LCD.Driver.Put
        (Text_1 => ("Ch" & Channel_Number_Str (Positive (Current_Config.Channel))
                    & ' ' & PRF_Str (Current_Config.PRF)
                    & ' ' & Data_Rate_Str (Current_Config.Data_Rate)),
         Text_2 => "");

   end Update_LCD;


   procedure Build_Packet
   is
   begin

      Tx_Packet (1) := Bits_8 (Data_Rates'Pos (Current_Config.Data_Rate));
      Tx_Packet (2) := Bits_8 (PRF_Type'Pos (Current_Config.PRF));
      Tx_Packet (3) := Bits_8 (Current_Config.Channel);
      Tx_Packet (4 .. 5) := (others => 0);

      for I in 1 .. (Tx_Packet'Length / 5) loop
         Tx_Packet (I * 5 .. I * 5 + 4) := Tx_Packet (1 .. 5);
      end loop;

   end Build_Packet;

begin

   Configurations.Get_Switches_Config (Current_Config);

   DecaDriver.Core.Driver.Initialize
     (Load_Antenna_Delay  => False,
      Load_XTAL_Trim      => True,
      Load_UCode_From_ROM => True);

   DecaDriver.Core.Driver.Configure (Current_Config);

   DecaDriver.Tx.Transmitter.Configure_Tx_Power
     (EVB1000_Tx_Power.Manual_Tx_Power_Table
        (Positive (Current_Config.Channel), Current_Config.PRF));

   DecaDriver.Core.Driver.Configure_LEDs
     (Tx_LED_Enable    => True,
      Rx_LED_Enable    => False,
      Rx_OK_LED_Enable => False,
      SFD_LED_Enable   => False,
      Test_Flash       => True);

   Update_LCD;

   Next_Tx_Time := Ada.Real_Time.Clock;

   loop

      --  Check if the configuration has changed.
      Configurations.Get_Switches_Config (New_Config);

      if New_Config /= Current_Config then
         --  Configuration has changed. Use new configuration.
         Current_Config := New_Config;
         DecaDriver.Core.Driver.Configure (New_Config);

         DecaDriver.Tx.Transmitter.Configure_Tx_Power
           (EVB1000_Tx_Power.Manual_Tx_Power_Table
              (Positive (Current_Config.Channel), Current_Config.PRF));

         Build_Packet;

         DecaDriver.Tx.Transmitter.Set_Tx_Data
           (Data   => Tx_Packet,
            Offset => 0);
         DecaDriver.Tx.Transmitter.Set_Tx_Frame_Length
           (Length => Tx_Packet'Length,
            Offset => 0);

         Update_LCD;

      end if;

      delay until Next_Tx_Time;

      Next_Tx_Time := Next_Tx_Time + Inter_Frame_Period (Current_Config.Data_Rate);

      DecaDriver.Tx.Transmitter.Start_Tx_Immediate (Rx_After_Tx => False);
      DecaDriver.Tx.Transmitter.Wait_For_Tx_Complete;

   end loop;

end Transmitter;
