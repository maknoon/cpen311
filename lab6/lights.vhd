-- Implements a simple Nios II system for the DE-series board.
-- Inputs: SW7-0 are parallel port inputs to the Nios II system
--         CLOCK_50 is the system clock

LIBRARY ieee;
USE ieee.std_logic_unsigned.ALL;

     SW : IN STD_LOGIC_VECTOR (7 DOWNTO 0); 
     LEDR : OUT      STD_LOGIC_VECTOR (7 DOWNTO 0) 
    );


ARCHITECTURE lights_rtl OF lights IS 

  COMPONENT nios_system
        SIGNAL leds_export : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
     );

   BEGIN
          switches_export => SW(7 DOWNTO 0), 
          leds_export => LEDR(7 DOWNTO 0)