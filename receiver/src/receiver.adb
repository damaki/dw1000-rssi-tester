-------------------------------------------------------------------------------
--  Copyright (c) 2017 Daniel King
--
--  Permission is hereby granted, free of charge, to any person obtaining a
--  copy of this software and associated documentation files (the "Software"),
--  to deal in the Software without restriction, including without limitation
--  the rights to use, copy, modify, merge, publish, distribute, sublicense,
--  and/or sell copies of the Software, and to permit persons to whom the
--  Software is furnished to do so, subject to the following conditions:
--
--  The above copyright notice and this permission notice shall be included in
--  all copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
--  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
--  DEALINGS IN THE SOFTWARE.
-------------------------------------------------------------------------------
with Ada.Real_Time;   use Ada.Real_Time;
with Configurations;
with DecaDriver.Core; use DecaDriver.Core;
with DecaDriver.Rx;
with DW1000.Driver;   use DW1000.Driver;
with EVB1000.LCD;
with EVB1000.LED;
with Packet_Receiver;

procedure Receiver
is
   Packets_Per_Second : constant array (DW1000.Driver.Data_Rates) of Natural :=
     (Data_Rate_110k => 64,
      Data_Rate_850k => 200,
      Data_Rate_6M8  => 250);

   Current_Config : DecaDriver.Core.Configuration_Type;
   New_Config     : DecaDriver.Core.Configuration_Type;

   Next_Update_Time : Ada.Real_Time.Time;

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

      Line_1 : String := ("Ch" & Channel_Number_Str (Positive (Current_Config.Channel))
                          & ' ' & PRF_Str (Current_Config.PRF)
                          & ' ' & Data_Rate_Str (Current_Config.Data_Rate));

      Average_RSSI       : Float;
      Nb_Packets         : Natural;
      Data_Rate          : DW1000.Driver.Data_Rates;
      Was_Config_Changed : Boolean;

      PLR : Natural;

   begin

      Packet_Receiver.Packets_Info.Reset
        (Average_RSSI,
         Nb_Packets,
         Data_Rate,
         Was_Config_Changed);

      if Nb_Packets = 0 or Was_Config_Changed then
         EVB1000.LCD.Driver.Put
           (Text_1 => Line_1,
            Text_2 => "---% ---- dBm");

      else
         PLR := (Nb_Packets * 100) / Packets_Per_Second (Data_Rate);

         EVB1000.LCD.Driver.Put
           (Text_1 => Line_1,
            Text_2 => (Natural'Image (PLR) & "% "
                       & Integer'Image (Integer (Average_RSSI - 0.5)) & " dBm"));

      end if;

   end Update_LCD;

begin

   Configurations.Get_Switches_Config (Current_Config);

   DecaDriver.Core.Driver.Initialize
     (Load_Antenna_Delay  => True,
      Load_XTAL_Trim      => True,
      Load_UCode_From_ROM => True);

   DecaDriver.Core.Driver.Configure (Current_Config);

   DecaDriver.Core.Driver.Configure_LEDs
     (Tx_LED_Enable    => False,
      Rx_LED_Enable    => True,
      Rx_OK_LED_Enable => False,
      SFD_LED_Enable   => False,
      Test_Flash       => False);

   DecaDriver.Rx.Receiver.Set_FCS_Check_Enabled (True);

   DecaDriver.Rx.Receiver.Start_Rx_Immediate;

   Next_Update_Time := Ada.Real_Time.Clock;

   loop
      Update_LCD;

      Configurations.Get_Switches_Config (New_Config);

      if New_Config /= Current_Config then
         --  Configuration switches have changed. Apply new configuration.
         Current_Config := New_Config;

         DecaDriver.Core.Driver.Force_Tx_Rx_Off;
         DecaDriver.Core.Driver.Configure (New_Config);
         DecaDriver.Rx.Receiver.Start_Rx_Immediate;

         Packet_Receiver.Packets_Info.Config_Changed;
      end if;

      Next_Update_Time := Next_Update_Time + Seconds (1);
      delay until Next_Update_Time;

      EVB1000.LED.Toggle_LED (1);

   end loop;

end Receiver;
