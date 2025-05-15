# ADS1115-I2C-Master
This module is an I2C master that reads from ADS1115 IC.
https://www.ti.com/lit/ds/symlink/ads1115.pdf

This design works on a 50Mhz clock, and if your clock speed is anything else, then adjustments on the ADS_FREQ module must be made. The hardware used for this project is the maxII 240 CPLD which only has 240 LE. Because of this hardware limitations or to limit the amount of resources used, I omitted some functionalities that a typical I2C master would have and also designed it to configurate the ADS1115 in one constant setting. The functions I omitted from this I2C master is the "address switching" which controls the slave address, and the function to change the configuration register which controls the settings of the ads1115. To change to a prefered setting, the I2C_MASTER module code must be changed, specifically, the "slave_address" and the "register_config" must be changed or additional ports must be created in the module along with switching functions to allow for the picking of specific "slave_address" and "register_config".

This project has 3 modules: The the I2C_ADS1115 which is the top module connects the modules together, the I2C_MASTER which is the state machine and decides how this module interacts, and the ADS_FREQ which is the substitute for a PLL since the max2 cpld doesnt have the PLL IP. This project also includes the testbench module IA_TB.V.



