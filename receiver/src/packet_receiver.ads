with DW1000.Driver; use DW1000.Driver;

package Packet_Receiver
  with SPARK_Mode => On
is

   protected Packets_Info
   is

      procedure Packet_Received (RSSI      : in Float;
                                 Data_Rate : in DW1000.Driver.Data_Rates);

      procedure Config_Changed;

      procedure Reset (Average_RSSI       : out Float;
                       Nb_Packets         : out Natural;
                       Data_Rate          : out DW1000.Driver.Data_Rates;
                       Was_Config_Changed : out Boolean);

   private

      RSSI_Sum          : Float      := 0.0;
      Count             : Natural    := 0;
      Changed           : Boolean    := False;
      Last_Data_Rate    : Data_Rates := Data_Rate_110k;

   end Packets_Info;


private

   task Radio_Task;

end Packet_Receiver;
