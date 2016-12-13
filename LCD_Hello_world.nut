/*
 LiquidCrystal Library - Hello World

 Demonstrates the use a 16x2 LCD display.  The LiquidCrystal
 library works with all LCD displays that are compatible with the
 Hitachi HD44780 driver. There are many of them out there, and you
 can usually tell them by the 16-pin interface.

 This sketch prints "Hello World!" to the LCD
 and shows the time.

  The circuit:
 * LCD RS pin to digital pin 12
 * LCD Enable pin to digital pin 11
 * LCD D4 pin to digital pin 5
 * LCD D5 pin to digital pin 4
 * LCD D6 pin to digital pin 3
 * LCD D7 pin to digital pin 2
 * LCD R/W pin to ground
 * LCD VSS pin to ground
 * LCD VCC pin to 5V
 * 10K resistor:
 * ends to +5V and ground
 * wiper to LCD VO pin (pin 3)

 Library originally added 18 Apr 2008
 by David A. Mellis
 library modified 5 Jul 2009
 by Limor Fried (http://www.ladyada.net)
 example added 9 Jul 2009
 by Tom Igoe
 modified 22 Nov 2010
 by Tom Igoe
 2016.11.29 -- Ported to Esquilo by Leeland Heins

 This example code is in the public domain.

 */
 
require("GPIO");

// Load the libary.
dofile("sd:/LiquidCrystal.nut");

// Instantiate our object.
local lcd = LiquidCrystal(0x00, 12, 0, 11, 5, 4, 3, 2, 0, 0, 0, 0);

// set up the LCD's number of columns and rows: 
lcd.begin(16, 2, 0);
// Print a message to the LCD.
lcd.clear();
lcd.home();
lcd.print("hello, world!");
while (true) {
    lcd.setCursor(0, 1);
    local mils = millis() / 1000;
    lcd.print(mils.tostring());
}

