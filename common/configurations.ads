with DecaDriver.Core;
with EVB1000.S1;

package Configurations
is

   procedure Get_Switches_Config
     (Config : out DecaDriver.Core.Configuration_Type)
   with Global => (Input => EVB1000.S1.Switch_State),
   Depends => (Config => EVB1000.S1.Switch_State);

end Configurations;
