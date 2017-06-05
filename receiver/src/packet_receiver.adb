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
with Configurations;
with DecaDriver;               use DecaDriver;
with DecaDriver.Rx;            use DecaDriver.Rx;
with DW1000.Reception_Quality;
with DW1000.Types;
with EVB1000.LED;

package body Packet_Receiver
with SPARK_Mode => On
is

   protected body Packets_Info
   is

      procedure Packet_Received (RSSI      : in Float;
                                 Data_Rate : in DW1000.Driver.Data_Rates)
      is
      begin
         if Count > 0 and Data_Rate /= Last_Data_Rate then
            Changed := True;
         end if;

         Last_Data_Rate := Data_Rate;
         RSSI_Sum       := RSSI_Sum + RSSI;
         Count          := Count + 1;
      end Packet_Received;


      procedure Config_Changed
      is
      begin
         Changed  := True;
      end Config_Changed;


      procedure Reset (Average_RSSI       : out Float;
                       Nb_Packets         : out Natural;
                       Data_Rate          : out DW1000.Driver.Data_Rates;
                       Was_Config_Changed : out Boolean)
      is
      begin
         Was_Config_Changed := Changed;
         Nb_Packets         := Count;
         Data_Rate          := Last_Data_Rate;

         if Count > 0 then
            Average_RSSI := RSSI_Sum / Float (Count);
         else
            Average_RSSI := 0.0;
         end if;

         RSSI_Sum     := 0.0;
         Count        := 0;
         Changed      := False;
      end Reset;

   end Packets_Info;


   task body Radio_Task
   is
      Frame        : DW1000.Types.Byte_Array (1 .. 127);
      Frame_Length : DecaDriver.Frame_Length_Number;
      Frame_Info   : DecaDriver.Rx.Frame_Info_Type;
      Frame_Status : DecaDriver.Rx.Rx_Status_Type;
      Overrun      : Boolean;

      RSSI         : Float;
      Data_Rate    : DW1000.Driver.Data_Rates;

   begin

      loop
         DecaDriver.Rx.Receiver.Wait
           (Frame      => Frame,
            Length     => Frame_Length,
            Frame_Info => Frame_Info,
            Status     => Frame_Status,
            Overrun    => Overrun);

         DecaDriver.Rx.Receiver.Start_Rx_Immediate;

         if Overrun or Frame_Status /= No_Error then
            EVB1000.LED.Toggle_LED (3);
         end if;

         if Frame_Status = No_Error then
            EVB1000.LED.Toggle_LED (4);

            RSSI := DecaDriver.Rx.Receive_Signal_Power (Frame_Info);

            case Frame_Info.RX_FINFO_Reg.RXBR is
            when 2#00# =>
               Data_Rate := Data_Rate_110k;

            when 2#01# =>
               Data_Rate := Data_Rate_850k;

            when others =>
               Data_Rate := Data_Rate_6M8;

            end case;

            Packets_Info.Packet_Received (RSSI, Data_Rate);
         end if;
      end loop;
   end Radio_Task;

end Packet_Receiver;
