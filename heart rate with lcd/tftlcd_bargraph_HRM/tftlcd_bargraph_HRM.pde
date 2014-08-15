/*
Most of this code shamelessly ripped off from various examples...
 Notable sources: 
 
 Adafruit Logger Shield example - http://www.ladyada.net/make/logshield/index.html
 Adafruit 2.8" TFT Touch Shield example - http://www.ladyada.net/products/tfttouchshield/
 Use your mind! - Arduino heart rate data logger - http://home.comcast.net/~useyourmind/site/?/page/Arduino_heart_rate_data_logger/
 RMCM01 Polar Heart Rate Monitor OEM Module Datasheet - http://www.sparkfun.com/datasheets/Wireless/General/RMCM01.pdf
 
 */
//Generic Stuff
long previousMillis = 0;
uint16_t gfxBarXCoord = 0;
//End Generic Declarations

//HRM Stuff
const int HRpin = 0; //Interrupt 0 is Pin 2
int BPM = 0; //Beats per minute (Global declaration)
volatile long lastpulsetime = 0;
volatile long pulsetime = 0;
volatile int diff1 = 0;
volatile int diff2 = 0;
volatile int diff3 = 0;
volatile int diff4 = 0;
volatile int diff5 = 0;
//End HRM Declarations

//SD Card Stuff
#include <SD.h>
#include <SPI.h>
// The chip select pin for the SD card on the shield
#define SD_CS 5 
File logfile;
char filename[] = "HRM00000.CSV";

/************* HARDWARE SPI ENABLE/DISABLE */
// we want to reuse the pins for the SD card and the TFT - to save 2 pins. this means we have to
// enable the SPI hardware interface whenever accessing the SD card and then disable it when done
int8_t saved_spimode;

void disableSPI(void) {
  saved_spimode = SPCR;
  SPCR = 0;
}

void enableSPI(void) {
  SPCR = saved_spimode; 
}
/******************************************/
//End SD Card Declarations

//TFT Variables
#include "TFTLCD.h"
//#define RESETINT 2000 // Time to wait before clearing screen (ms)...
#define UPDATEINT 1000 // How long to wait before updating the screen (ms). Lower value will update more frequently.

//Touchscreen stuff...
// The control pins can connect to any pins but we'll use the 
// analog lines since that means we can double up the pins
// with the touch screen (see the AdafrTFT paint example)
#define LCD_CS A3    // Chip Select goes to Analog 3
#define LCD_CD A2    // Command/Data goes to Analog 2
#define LCD_WR A1    // LCD Write goes to Analog 1
#define LCD_RD A0    // LCD Read goes to Analog 0

// you can also just connect RESET to the arduino RESET pin
#define LCD_RESET A4

/* For the 8 data pins:
 Note: The original pin assignments definitely do NOT match the Adafruit 2.8" TFTLCD Shield!
 Redone to match shield properly just for reference, TFTLCD.h seems to still work anyway so meh...
 
 Duemilanove/Diecimila/UNO/etc ('168 and '328 chips) microcontoller:
 D1 connects to digital pin 8
 D2 connects to digital pin 9
 D3 connects to digital pin 10
 D4 connects to digital pin 11
 D5 connects to digital pin 4
 D6 connects to digital pin 13
 D7 connects to digital pin 6
 D8 connects to digital pin 7
 
 */

// Color definitions
#define	BLACK           0x0000
#define	BLUE            0x001F
#define	RED             0xF800
#define	GREEN           0x07E0
#define CYAN            0x07FF
#define MAGENTA         0xF81F
#define YELLOW          0xFFE0 
#define WHITE           0xFFFF

TFTLCD tft(LCD_CS, LCD_CD, LCD_WR, LCD_RD, LCD_RESET);


//End TFT UI Variables


void setup(void) {
  Serial.begin(9600);
  tft.reset();
  uint16_t identifier = tft.readRegister(0x0);
  if (identifier == 0x9325) {
    Serial.println("Found ILI9325");
  } 
  else if (identifier == 0x9328) {
    Serial.println("Found ILI9328");
  } 
  else {
    Serial.print("Unknown driver chip ");
    Serial.println(identifier, HEX);
    while (1); //Locks device, for obvious reasons...
  }  
  tft.initDisplay();
  tft.setRotation(1);
  tft.fillScreen(BLACK);
  gfxBarXCoord = 0;
  //Set up logger file...
  enableSPI();
  if (!SD.begin(SD_CS)) {
    error("Card failed, or not present");    // don't do anything more:
  }
  Serial.println("card initialized.");
  for (uint8_t i = 0; i < 100; i++) {
    filename[6] = i/10 + '0';
    filename[7] = i%10 + '0';
    if (! SD.exists(filename)) {
      // only open a new file if it doesn't exist
      logfile = SD.open(filename, FILE_WRITE); 
      break;  // leave the loop!
    }
  }
  if (! logfile) {
    error("couldnt create file");
  }
  //Write header to logfile
  logfile.println("Milliseconds,BPM"); //Just recording the milliseconds and beats per minute, no averages or anything yet...
  logfile.close();
  disableSPI();
  pinMode(HRpin, INPUT);
  attachInterrupt(HRpin, HRpulse, RISING);
  interrupts();
}

void loop(void) {
  unsigned long currentMillis = millis();
  if(currentMillis - previousMillis > UPDATEINT) {
    // save the last time fired...
    previousMillis = currentMillis;   
    //No point recording anything until we have a BPM to record...
    if (BPM != 0) {
      drawBPMGraph();
      storeToSDCard();
    }
  }
}

void storeToSDCard()
{
  enableSPI();
  logfile = SD.open(filename, FILE_WRITE); 
  //Store value and time offset to SD card
  logfile.print(millis());
  logfile.print(", ");
  logfile.println(BPM);
  logfile.close();
  //End storage code.
  disableSPI();
}

void drawBPMGraph()
{
  //Depending on sample rate we will want to vary what is plotted where, how, etc.. ie sampling per second but plotting every 10, you
  //would want a highest, lowest and average value in different colours.
  //Sticking to basics for the moment, lets assume a single column per sample (average BPM derived from five samples in rolling buffer)
  int y = map(BPM, 0, 220, 0, tft.height());
  tft.drawLine(gfxBarXCoord, (tft.height() - y), gfxBarXCoord, tft.height(), GREEN); //Draws bars...
  tft.setCursor(300, 20);
  tft.setTextSize(1);
  tft.setTextColor(MAGENTA);
  tft.fillRect(299, 19, 19, 9, BLACK);
  tft.setCursor(300, 20);
  tft.println(BPM);

  if (gfxBarXCoord == tft.width())
  {
    resetDisplay();
  }
  gfxBarXCoord++; // Decrement counter
}

void resetDisplay()
{
  tft.fillScreen(BLACK); //Clear display
  gfxBarXCoord = 0;
}

void HRpulse() //Fired every time a pulse is received from the RMCM01 Module, from external interrupt 0 (Digital pin 2)
{
  pulsetime = millis(); //Set pulsetime to current millis, on a RTC enabled device this would be set as a datetime instead
  rollBuffer(); //five value buffer, could probably be better implemented in an array or something but this works fine for now
  diff1 = pulsetime - lastpulsetime;  //Calculate time between this pulse and last pulse in milliseconds
  if (diff5 != 0) {
    BPM = 60000 / ((diff1 + diff2 + diff3 + diff4 + diff5)/5); //Make a mean average!
  }
  lastpulsetime = pulsetime; //Move original time of pulse to lastpulse as we are now done...
}

void rollBuffer() //Rolls the buffer values along in a FILO approach.
{
  diff5 = diff4;
  diff4 = diff3;
  diff3 = diff2;
  diff2 = diff1;
  diff1 = 0;
}

void error(char *str) //Displays errors on serial console then locks device.
{
  Serial.print("error: ");
  Serial.println(str);
  noInterrupts(); //Stops all interrupt activity too...
  while(1);
}






