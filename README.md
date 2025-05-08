# ADS1115-I2C-Master
This module is an I2C master that reads from ADS1115 IC.
https://www.ti.com/lit/ds/symlink/ads1115.pdf

The hardware im using for this project is the maxII 240 CPLD. This hardware has really small resource so this I2C master is designed to take as little resources as possible. This means that I omitted some of the functionalities of a typical I2C master and only used the bare minimum, which is to establish a connection with the ADS1115 and read from it. With some modification, this I2C master can read from multiple address' and if youre interested in doing that and need help just email me.

This project has 3 modules: The the I2C_ADS1115 which is the top module connects the modules together, the I2C_MASTER which is the state machine that does the I2C stuff, and the ADS_FREQ which is the sub for the PLL since the max2 cpld doesnt have the PLL IP.



