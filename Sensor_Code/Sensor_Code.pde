/**
 * \file
 *
 *
 * \section DESCRIPTION
 * This code makes the waspmote take measurements, go to sleep, and listen for input commands repeatedly.
 * It can be compiled and flashed onto a waspmote pro V1.2 using the Waspmote pro IDE v04 (w/ Waspmote pro API v017)
 * Be sure that both the switches next to the board are set to the left (ON), before flashing the code.
 * For some time this program will allow the waspmote to listen to input commands.

 * Commands have the form STR&<command>:<args>!,...,<command>:<args>!END&
 * For example to sync the clock to the day that I wrote this and request all data from the
 * corresponding file for that day I would send the following command to the waspmote:
 * SRT&CLKS:15:08:19:04:18:58:10!RQFL:15-08-19,D3f5,0,-1!END&
 * And if I wanted to do nothing
 * SRT&END&
 *
 * Clock Sync commmands have the following form:
 * CLKS:<year>:<month>:<date>:<day of week>:<hour>:<minute>:<second>!
 *
 * File request commmands have the following form:
 * RQFL:<filename>,<transfer-key>,<firstbyte>,<#bytes to read>!
 * Note that filename cannot be more than 8 characters and its .ext must be no more than 3.
 *
 * It is possible that this project will eventually use a different sensor interface all together
 * if that is the case much of this code should still be salvagable as long as the protocol mentioned
 * above is maintained. If a different sensor board will be used a few slight changes may need to be made
 * to the code flashed onto the sensor board, but it should not require a large overhaul since the code
 * on the sensor board is written in a dialect of C similar to what is used for arduinos. Of course
 * if you are to connect sensors directly to the onboard computer then this code largely useless, save for
 * the setup for creating new threads.
 * Library.
 */



#include <WaspSensorGas_v20.h>
#include <WaspFrame.h>
#include <stdlib.h>
#include <WaspRTC.h>



char* USB_START_PATTERN= "SRT&";
char* USB_END_PATTERN = "END&";
char* USB_FILE_REQUEST_PATTERN = "RQFL:";
char* USB_CLOCK_SYNC_PATTERN = "CLKS:";
char* USB_READY_FOR_INPUT = "Waspmote ready for input...";
char USB_COMMAND_END_PATTERN = '!';
char EOT = 0x04;

int KEY_LENGTH = 4;
int NUM_POLLS_BTW_INPUT=2;
char * SLEEP_TIME = "00:00:00:02";

// buffer to write into Sd File
char toWrite[200];

int32_t numBytes;

// variables to define the file lines to be read
int startLine;
int endLine;

// define variable
uint8_t sd_answer;

//Measurement Variables
float pressureVal;
float humidityVal;

//A key for all CSV files created (Edit appropriately as sensors are added);
char* tableheader = "Entry, Date(YY:MM:SS), Time (HH:MM:SS), Pressure (kPa), Humidity (%RH)";

//The entry number, increments as new entries are added
unsigned long entryNum=0;

//A few declarations just because I didn't want to define these at the beginning of the file
void parseInput(unsigned long timeout);
void writeFileOverUSB(char*file, uint32_t start, int32_t numBytes);
void answerFileRequest(char*key, char*file, uint32_t start, int32_t numBytes);


//Creates a new file. If addTableHeader is true then it automatically appends the table header
void createFile(char*file, bool addTableHeader=true){
  sd_answer = SD.create(file);

  if( sd_answer == 1 ){ 
    USB.printf("%s created\n", file);
    if(addTableHeader)writeline(file,tableheader);
  }
  else{
    USB.printf("%s not created\n", file);
  }
}
//Writes the value of the current entry to the "entry" file on the SD card so that if 
//the board loses power it always knows what entry it is on.
void saveEntryNum(){
  char entryStr[20];
  sprintf(entryStr, "%lu", entryNum);
  SD.writeSD("entry",entryStr,SD.indexOf("entry","entry=",0)+6);
}

//Increments the entrynum and saves it the the SD card
void incrementEntry(){
  entryNum++;
  saveEntryNum();
}

//The main function for the program
void setup()
{
  // open USB port
  USB.ON();
  USB.println(F("Sensor Code: Moball"));

  // Set SD ON
  SD.ON();

  //Allows us to read and set the clock
  RTC.ON();

  //if it doesn't already exist create the file "log"
  int fileFound=SD.isFile("log");
  if(fileFound != 1){
   createFile("log",false);
  }

  //if it doesn't already exist create the file "entry" and add a couple lines to it
  fileFound=SD.isFile("entry");
  if(fileFound != 1){
    createFile("entry",false);
    writeline("entry", "#Do NOT CHANGE THIS!");
    writeline("entry", "entry=0");
  }
  //Initialize entryNum to the value that it finds in "entry"
  char* entryStr = SD.cat("entry", SD.indexOf("entry","entry=",0)+6, 20);
  entryNum = strtoul(entryStr,NULL, 0);
}

void loop()
{
  //Create a file following the 8.3 filename format (8 characters).(3 character extention)
  char filename[13];
  sprintf(filename,"%02u-%02u-%02u",RTC.year, RTC.month, RTC.date);//It is simply today's date
  createFile(filename);
  for(int i=0; i < NUM_POLLS_BTW_INPUT; i++){  
    memset(toWrite, 0x00, sizeof(toWrite) );
    takeMeasurements(toWrite); //Take measurements of the environment and write a line of CSV data to "toWrite"
    USB.println(toWrite);
    writeline(filename, toWrite); //Write the CSV data to the file for today on the SD card
    incrementEntry(); //Increment the entry to keep track of the order of writing
    SD.OFF();//Turn off the SD card otherwise it will break when we put the board to sleep
    USB.println();
    USB.println();

    PWR.deepSleep(SLEEP_TIME, RTC_OFFSET, RTC_ALM1_MODE2,ALL_OFF);// Go to sleep for the time you designated in SLEEP_TIME

    SD.ON(); // sets the corresponding pins as inputs
    //USB.flush();
    delay(100);
  }
  USB.println(USB_READY_FOR_INPUT);
   parseInput(10000);//parse command input from the serial line
}

//Reads data from the SD cards and sends it over usb
void writeFileOverUSB(char*file, char &checksum,uint32_t start=0, int32_t numBytes=-1){
  int fileFound=SD.isFile(file);
  if(fileFound != 1){
    USB.printf( "File %s not found", file);
    return;
  }
  if(numBytes == -1){
    numBytes = SD.getFileSize(file)-start; //If we've gotten a -1 then just read until the end
  }
  uint32_t len = (uint32_t)numBytes;

  char* dataRead;
  uint32_t finish = start+len;
  for( uint32_t i=start; i<finish; i += 127 ){  
    //Read the file from SD card
    dataRead = SD.cat(file, i, 127); //Max bytes that can be read at once
    for(int j=0;j < strlen(dataRead);j++){
      checksum ^= dataRead[j];//Accumilate the value of the checksum using XOR
    }
    USB.printf("%s",dataRead); //output the next 127 bytes of the file
  }
}

//Answers a file request for the following data with the following key and the following file
void answerFileRequest(char*key, char*file, uint32_t start=0, int32_t numBytes=-1){
  char checksum =0;
  USB.printf("%s0",key);//send the key followed by a zero, this is how the board will know where the file data begins
  writeFileOverUSB(file, checksum,start, numBytes);//write the actually file data and accumilate the checksum
  USB.printf("%s%c",key, checksum);//write the key again followed by the checksum.
}

//Reads input from the serial line
//Starts reading commands when it encounters "STR&"
//Pushes the parsing to parseFileRequest() if it encounters RQFL:
//Pushes the parsing to parseClockSync() if it encounters CLKS:
//Stops listening if it encounters "END&" or if its timout has passed
void parseInput(unsigned long timeout=0){
  int startBytes=0;
  int endBytes=0;
  int fileRequestBytes=0;
  int clockSyncBytes=0;
  bool listening_to_commands = false;
  unsigned long time = millis();
  while(timeout == 0 || millis()-time < timeout )  {
    if(USB.available() > 0){
      char val = USB.read();           
      if(!listening_to_commands){
        if(val == USB_START_PATTERN[startBytes]){
          startBytes++;
          if(startBytes ==strlen(USB_START_PATTERN)){
            listening_to_commands = true;
          }
        }
        else{
          startBytes =0;
        }
      }
      else{
        if(val == USB_FILE_REQUEST_PATTERN[fileRequestBytes]){
          fileRequestBytes++;
          clockSyncBytes =0;
          endBytes=0;
          if(fileRequestBytes ==strlen(USB_FILE_REQUEST_PATTERN)){
            parseFileRequest();
            fileRequestBytes = 0;
          }
        }else if(val == USB_CLOCK_SYNC_PATTERN[clockSyncBytes]){
            clockSyncBytes++;
            fileRequestBytes=0;
            endBytes=0;
            if(clockSyncBytes ==strlen(USB_CLOCK_SYNC_PATTERN)){
              clockSyncBytes = 0;
              parseClockSync();
            }
          }else if(val == USB_END_PATTERN[endBytes]){
              endBytes++;
              fileRequestBytes=0;
              clockSyncBytes =0;
              if(endBytes ==strlen(USB_END_PATTERN)){
                break;
              }
        }
      }
    }
    if (millis() < time)time = millis();
  }
}

//Parses a file request (RQFL:) and answers it if possible
void parseFileRequest(){
  char readBuffer[30];
  int len =0;
  char file[13];
  char key[10];
  char startStr [10];
  unsigned int start;
  char bytesStr[10];
  int32_t bytes;
  int argIndex =0;
  while(USB.available() > 0) {
    char val = USB.read();//read the next byte
    if(val != ',' && val != USB_COMMAND_END_PATTERN){//We got data
      readBuffer[len++] = val;
    }
    else{//We got a ',' or a '!'
      readBuffer[len++] = '\0';
      switch(argIndex){
      case 0:
        strncpy(file, readBuffer, len );//grab the name of the file from the read buffer
        break;
      case 1:
        strncpy(key, readBuffer, len );//grab the key from the read buffer
        break;
      case 2:
        strncpy(startStr, readBuffer, len );//grab the starting byte from the read buffer
        start = atoi(startStr);
        break;
      case 3:
        strncpy(bytesStr, readBuffer, len );//grab the number of bytes to be read from the read buffer
        bytes = atoi(bytesStr);
        break;
      }
      len =0;
      argIndex++;
      if(val == USB_COMMAND_END_PATTERN){//We got a '!' so stop reading
        answerFileRequest(key, file,start,bytes);
        return;
      }
    }
  }
  USB.println(readBuffer);
  //SRT&RQFL:13-01-11,sdfd,0,-1!
}
//SRT&CLKS:15:08:13:05:14:15:00!RQFL:15-08-13,sdfd,0,-1!END&

//Parses a clock sync (CLKS:) and sets the clock to the inputted time
void parseClockSync(){
  char readBuffer[30];
  int len =0;
  while(USB.available() > 0) {
    char val = USB.read();//read the next byte
    if(val != USB_COMMAND_END_PATTERN){//We got data
      readBuffer[len++] = val;
    }else{
      readBuffer[len++] = '\0';
      if(val == USB_COMMAND_END_PATTERN){//We got a '!' 
        char filename[13];
        char currentTime[30];
        sprintf(currentTime, "%02u:%02u:%02u:%02u:%02u:%02u:%02u",RTC.year, RTC.month, RTC.date, RTC.day, RTC.hour, RTC.minute, RTC.second);
        if(strcmp(currentTime,readBuffer)!=0){ //If the current time and the inputed time are not the same
          int err = RTC.setTime(readBuffer); //Set the time to the inputted time

          //genrate a message incorperating the next entryNum that will keep a record of the fact that a sync was done
          char* mesg="Successful Sync";
          if(err == 1)mesg = "Failed Sync";
          sprintf(filename,"%02u-%02u-%02u",RTC.year, RTC.month, RTC.date);
          sprintf(toWrite, "#%lu %s %s  ->  %s", entryNum, mesg, currentTime, readBuffer);
  
          writeline("log", toWrite);//Write the message to the log
          writeline(filename, toWrite);//Write the message to the file for today's date
          incrementEntry();//Increment the entry
        }else{
          //If the current time and inputed time are the same, then keep a record of the fact that it tried, but don't change anything
          sprintf(toWrite, "#Sync was attempted at %s but was unecessary", currentTime);
          writeline("log", toWrite);
        }
        return;
      }
    }
  }
  //SRT&CLKS:15:08:13:05:14:15:00!
}





void sensePressure(){
  // Turn on the atmospheric pressure sensor and wait for stabilization and
  // sensor response time
  SensorGasv20.setSensorMode(SENS_ON, SENS_PRESSURE);
  delay(20); 

  // Read the sensor
  pressureVal = SensorGasv20.readValue(SENS_PRESSURE);

  // Turn off the atmospheric pressure sensor
  SensorGasv20.setSensorMode(SENS_OFF, SENS_PRESSURE);

}


void senseHumidity(){
  // Read the sensor
  humidityVal = SensorGasv20.readValue(SENS_HUMIDITY);

}


void takeMeasurements(char*outputStr){
  // Turn on the sensor board
  SensorGasv20.ON();

  sensePressure();
  senseHumidity();


  // Turn off the sensor board
  SensorGasv20.OFF();


  //write the measurements to strings
  char pressureStr[10];
  char humidityStr[10];
  Utils.float2String(pressureVal, pressureStr, 5);
  Utils.float2String(humidityVal, humidityStr, 5);

  // Print the result through the USB
  USB.printf("Pressure:%s kPa \n",pressureStr);
  USB.printf("Humidity:%s %s \n",humidityStr, "%RH");

  //Generate a line of CSV data for the measurements
  sprintf(outputStr, "%lu,%02u/%02u/%02u,%02u:%02u:%02u", entryNum,RTC.year, RTC.month, RTC.date, RTC.hour, RTC.minute, RTC.second);
  sprintf(outputStr, "%s,%s,%s",outputStr, pressureStr, humidityStr);

}

//Writes a line to the end of the designated file on the SD card
void writeline(char*file, char*data){
  USB.println(file);
  sd_answer = SD.appendln(file, data);
  if( sd_answer == 1 ){
    USB.printf("Appended line to file: %s", file);
  }else {
    USB.printf("Append failed to file: %s", file);
  }
}


//Creates a directory on the SD card
void createDir(char*path){
  // create path
  sd_answer = SD.mkdir(path);

  if( sd_answer == 1 ){ 
    USB.printf("path created: %s", path);
  }else{
    USB.printf("mkdir failed: %s", path);
  }
}


