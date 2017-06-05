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
