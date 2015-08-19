

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

unsigned long entryNum=0;

void parseInput(unsigned long timeout);
void writeFileOverUSB(char*file, uint32_t start, int32_t numBytes);
void answerFileRequest(char*key, char*file, uint32_t start, int32_t numBytes);

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
void saveEntryNum(){
  char entryStr[20];
  sprintf(entryStr, "%lu", entryNum);
  SD.writeSD("entry",entryStr,SD.indexOf("entry","entry=",0)+6);
}

void incrementEntry(){
  entryNum++;
  saveEntryNum();
}

void setup()
{
  // open USB port
  USB.ON();
  USB.println(F("Sensor Code: Moball"));

  // Set SD ON
  SD.ON();
  //createDir("/data");

  RTC.ON();

  createFile("log",false);

  int fileFound=SD.isFile("entry");
  if(fileFound != 1){
    createFile("entry",false);
    writeline("entry", "#Do NOT CHANGE THIS!");
    writeline("entry", "entry=0");
  }
  char* entryStr = SD.cat("entry", SD.indexOf("entry","entry=",0)+6, 20);
  entryNum = strtoul(entryStr,NULL, 0);
}

void loop()
{
  //Create a file following the 8.3 filename format (8 characters).(3 character extention)
  char filename[13];
  sprintf(filename,"%02u-%02u-%02u",RTC.year, RTC.month, RTC.date);
  createFile(filename);
  for(int i=0; i < 1; i++){  
    memset(toWrite, 0x00, sizeof(toWrite) );
    takeMeasurements(toWrite);
    USB.println(toWrite);
    writeline(filename, toWrite); 
    incrementEntry();
    SD.OFF();
    USB.println();
    USB.println();

    PWR.deepSleep("00:00:00:02", RTC_OFFSET, RTC_ALM1_MODE2,ALL_OFF);// Sleep

    SD.ON(); // sets the corresponding pins as inputs
    //USB.flush();
    delay(100);
    USB.println(USB_READY_FOR_INPUT);
    parseInput(10000);
  }
}

void writeFileOverUSB(char*file, char &checksum,uint32_t start=0, int32_t numBytes=-1){
  int fileFound=SD.isFile(file);
  if(fileFound != 1){
    USB.printf( "File %s not found", file);
    return;
  }
  if(numBytes == -1){
    numBytes = SD.getFileSize(file);
  }
  uint32_t len = (uint32_t)numBytes;

  char* dataRead;
  uint32_t finish = start+len;
  for( uint32_t i=start; i<finish; i += 127 ){  
    //Read from SD card
    dataRead = SD.cat(file, i, 127); //Max bytes that can be read at once
    for(int j=0;j < strlen(dataRead);j++){
      checksum ^= dataRead[j];
      //USB.printf("CHECKSUM,%i,%i\n",checksum,dataRead[j]);
    }
    USB.printf("%s",dataRead);
  }
}

void answerFileRequest(char*key, char*file, uint32_t start=0, int32_t numBytes=-1){
  char checksum =0;
  USB.printf("%s0",key);
  writeFileOverUSB(file, checksum,start, numBytes);
  //USB.printf("%c", EOT);
  USB.printf("%s%c",key, checksum);
}

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
    char val = USB.read();
    if(val != ',' && val != USB_COMMAND_END_PATTERN){
      readBuffer[len++] = val;
    }
    else{
      readBuffer[len++] = '\0';
      switch(argIndex){
      case 0:
        strncpy(file, readBuffer, len );
        break;
      case 1:
        strncpy(key, readBuffer, len );
        break;
      case 2:
        strncpy(startStr, readBuffer, len );
        start = atoi(startStr);
        break;
      case 3:
        strncpy(bytesStr, readBuffer, len );
        bytes = atoi(bytesStr);
        break;
      }
      len =0;
      argIndex++;
      if(val == USB_COMMAND_END_PATTERN){
        answerFileRequest(key, file,start,bytes);
        return;
      }
    }
  }
  USB.println(readBuffer);
  //SRT&RQFL:13-01-11,sdfd,0,-1!
}
//SRT&CLKS:15:08:13:05:14:15:00!RQFL:15-08-13,sdfd,0,-1!END&

void parseClockSync(){
  char readBuffer[30];
  int len =0;
  //char clockStr[40];  
  while(USB.available() > 0) {
    char val = USB.read();
    //USB.print(val,BYTE);
    if(val != USB_COMMAND_END_PATTERN){
      readBuffer[len++] = val;
    }else{
      readBuffer[len++] = '\0';
     // strncpy(clockStr, readBuffer, len );
      if(val == USB_COMMAND_END_PATTERN){
        char filename[13];
        char currentTime[30];
        sprintf(currentTime, "%02u:%02u:%02u:%02u:%02u:%02u:%02u",RTC.year, RTC.month, RTC.date, RTC.day, RTC.hour, RTC.minute, RTC.second);
        if(strcmp(currentTime,readBuffer)!=0){
          int err = RTC.setTime(readBuffer);
          char* mesg="Successful Sync";
          if(err == 1)mesg = "Failed Sync";
          sprintf(filename,"%02u-%02u-%02u",RTC.year, RTC.month, RTC.date);
          sprintf(toWrite, "#%lu %s %s  ->  %s", entryNum, mesg, currentTime, readBuffer);
  
          writeline("log", toWrite);
          writeline(filename, toWrite);
          incrementEntry();
        }else{
          sprintf(toWrite, "#Sync was attempted at %s but was unecessary", currentTime);
          writeline("log", toWrite);
        }

        
        return;
      }
    }
  }
  USB.println(readBuffer);
  USB.println("FIN");
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

  char pressureStr[10];
  char humidityStr[10];
  Utils.float2String(pressureVal, pressureStr, 5);
  Utils.float2String(humidityVal, humidityStr, 5);

  // Print the result through the USB
  USB.printf("Pressure:%s kPa \n",pressureStr);
  USB.printf("Humidity:%s %s \n",humidityStr, "%RH");

  sprintf(outputStr, "%lu,%02u/%02u/%02u,%02u:%02u:%02u", entryNum,RTC.year, RTC.month, RTC.date, RTC.hour, RTC.minute, RTC.second);
  sprintf(outputStr, "%s,%s,%s",outputStr, pressureStr, humidityStr);

}
void writeline(char*file, char*data){
  USB.println(file);
  sd_answer = SD.appendln(file, data);
  if( sd_answer == 1 ){
    USB.printf("Appended line to file: %s", file);
  }else {
    USB.printf("Append failed to file: %s", file);
  }
}



void createDir(char*path){
  // create path
  sd_answer = SD.mkdir(path);

  if( sd_answer == 1 ){ 
    USB.printf("path created: %s", path);
  }else{
    USB.printf("mkdir failed: %s", path);
  }

}

/*
//Turn on everything that has been turned off by sleepFor()
void wake(){
  SD.ON();
  RTC.ON();
  delay(100);
}*/

/*
int dynamicSetWatchdog(int seconds){
  if(seconds >= 8){
    PWR.setWatchdog(WTD_ON,WTD_8S);
    seconds -= 8;
  }else
    if(seconds >= 4){
      PWR.setWatchdog(WTD_ON,WTD_4S);
      seconds -=4;
    }else
      if(seconds >= 2){
        PWR.setWatchdog(WTD_ON,WTD_2S);
        seconds -=2;
      }else
        if(seconds >= 1){
          PWR.setWatchdog(WTD_ON,WTD_1S);
          seconds -=1;
        }
  return seconds;
}
*/
/*
//Turn off everything for some number of seconds to conserve power
void sleepFor(int seconds){
  while(1){
    seconds = dynamicSetWatchdog(seconds);
    PWR.sleep(ALL_OFF);
    if( intFlag & WTD_INT){
      // clear flags
      intFlag &= ~(WTD_INT);
      if(seconds == 0){
        intCounter = 0;
        intArray[WTD_POS] = 0;
        USB.print(RTC.getTime());
        wake();
        break;
      }
    }
  }
}
*/

