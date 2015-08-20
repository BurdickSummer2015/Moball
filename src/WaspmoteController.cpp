/**
 * \file
 *
 *
 * \section DESCRIPTION
 * This controller creates a new thread to listen for when the waspmote is ready for input.
 * When the waspmote is ready it sends commands to either Sync the clock on the board with
 * the clock on the waspmote or it sends a command to request a file from the waspmote's
 * SD card. In the latter case when the file is sent the controller reads it and writes it to
 * a file. Eventually instead of writing the data to a file it will send the file wirelessly
 * to a server.
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



#include "WaspmoteController.h"
#include <iostream>
#include <ctime>
#include <climits>


#include <stdio.h>    // Standard input/output definitions /* defines FILENAME_MAX */
#include <unistd.h>   // UNIX standard function definitions
#include <vector>
#include <stdlib.h>
#include <fstream>
#ifdef WINDOWS
    #include <direct.h>
    #define GetCurrentDir _getcwd
#else
    #include <unistd.h>
    #define GetCurrentDir getcwd
 #endif
#include <sys/types.h>
#include <sys/stat.h>
#include "simple_serial.h"



char* InputReadyPattern = "Waspmote ready for input..."; //The pattern that the waspmote outputs when it is ready to recieve commands
char toWrite[200];//A buffer for writing commands
time_t lastSyncTime = (time_t)time(0);//The last time that the board synced its clock with the clock on the waspmote
time_t lastRequestTime = (time_t)time(0);//The last time that the board requested a file from the waspmote
const time_t SYNC_FREQ = (time_t)30; //How often the board should syncronize the waspmotes clock with its clock in seconds
const time_t REQ_FREQ = (time_t)10; //How often the board should request files from thewaspmote in seconds

//Returns a sync clock command as a string with inputted data
std::string syncClockCommand(struct tm *tstruct){
	char buff[50];
	char date[20];
	char time[20];
	//sprintf(buff, "CLKS:%02u:%02u:%02u:%02u:%02u:%02u:%02u!", year, month, date, dw, hour, minute ,second);
	//strftime(buff, sizeof(buff), "CLKS:%y:%m:%d:0%u:%X!", tstruct);
	strftime(date, sizeof(date), "CLKS:%y:%m:%d:", tstruct);
	strftime(time, sizeof(time), ":%X!", tstruct);
	sprintf(buff, "%s%02u%s",date, tstruct->tm_wday+1,time );
	std::string ret(buff);
	return ret;
}

//Returns a request file command as a string with inputted data
std::string requestFileCommand(const char*filename, const char*key, unsigned long start, long numBytes){
	char buff[50];
	sprintf(buff, "RQFL:%s,%s,%lu,%li!", filename, key, start, numBytes);
	std::string ret(buff);
	return ret;
}
/*
void gen_random_str(char *s, const int len) {
    static const char alphanum[] =
        "0123456789"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "abcdefghijklmnopqrstuvwxyz";

    for (int i = 0; i < len; ++i) {
        s[i] = alphanum[rand() % (sizeof(alphanum) - 1)];
    }

    s[len] = 0;
}
char * get_key(){

}*/


//Listens for the file transfer key and reads file data until the next time the key appears.
//As file data is revieved creates a simple one byte checksum using XOR on each byte.
//After recieving the the second key, recieves the waspmote's computed checksum.
//If the computed and recieved checksums match then it outputs the data
int readWaspmoteFile(std::string &filestr,int fd,const char* key){
	char checksum =0;
	char c;
	unsigned int keybytes=0;
	bool readingfile = false;
	unsigned int keylen = strlen(key);

	while(1){
		c = read_byte_blocking(fd);//Get the next byte from the waspmote's output
		if(!readingfile){
			if(c == key[keybytes]){
				keybytes++;
			}else
			if(keybytes == keylen && c == '0'){//Start reading the file if we have encountered the key and the a 0
				readingfile = true;
				keybytes = 0;
				printf("\nReading file...\n");
			}
		}else{
			filestr.push_back(c);//Add the next byte to the file string
			checksum ^= c;//Incorperate the next byte into the checksum
			if(c == key[keybytes]){
				keybytes++;
			}else
			if(keybytes == keylen){
				//Undo the additions to the checksum created by the key and recieved checksum
				checksum ^= c;
				for(int i= 0; i<keylen;i++){
					checksum ^= key[i];
				}
				filestr.erase(filestr.size()-(keylen+1));//Erase the last few lines of the file string since they are the key followed by the checksum
				if(checksum == c){//Check to make sure that the checksum we recieved is the same as the one we computed
					std::cout << "File transfer successful!"<<std::endl;
					return 0;
				}else{
					std::cout << "Error with file transfer: Checksum mismatch("<< checksum << "," << c << ")" << std::endl;
					lastRequestTime -=REQ_FREQ;
					return 1;
				}
			}else{
				keybytes == 0;//If the character does not match the next character in the key then start looking for the 1st character again
			}

		}
	}
}
//A structure for a command that can be queued and sent to the waspmote
struct waspmoteCommand{
	std::string str;//The string format of the command. This is what the waspmote reads.
	std::string file;//For file requests: the name of the file
	std::string key;//For file requests: a 'unique' key that specifies the beginning and end of a file transfer
	unsigned long start;//For file requests: the byte that the waspmote should start reading from
	signed long numBytes;//For file requests: the number of bytes that should be read from the waspmote
};

std::vector<waspmoteCommand> commandQueue; //A Queue that holds commands that will be sent to the waspmote



//For some reason this screws things up
/*
const int KEY_LENGTH = 4;
static const char alphanum[] =
		"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const char* gen_random_key() {
	std::string str;
	for (int i = 0; i < KEY_LENGTH; i) {
		str.push_back(alphanum[rand() % (sizeof(alphanum) - 1)]);
	}
	return (const char*)str.c_str();
}
*/



char* keys[] = {"D3f5", "df45", "pwc5", "39df", "Ekgl"}; //A list of preset keys (for some reason randomly generating them was causing problems)
int keyIndex = 0;//An index that indicates which key is the next key in line

//Get the size of the file at the specified path
std::ifstream::pos_type filesize(const char* filepath)
{
	std::cout << "FILE PATH:" <<filepath<<std::endl;
	struct stat statbuf;
	if (stat(filepath, &statbuf) == -1) {
		return -1;
	}
    return statbuf.st_size;
}
//Make a directory
void make_directory(char * path){
	struct stat st = {0};
	if (stat(path, &st) == -1) {
		mkdir(path, 0777);
	}
}
//Get the path of the directory that this executable exists in
char * getExecutablePath(){
	 char cCurrentPath[FILENAME_MAX];
	 if (!GetCurrentDir(cCurrentPath, sizeof(cCurrentPath))){
		 //return errno;
	 }
	 cCurrentPath[sizeof(cCurrentPath) - 1] = '\0'; /* not really required */
	 return cCurrentPath;
}

//Takes the name of a file and returns the full path to where it will be stored on the onboard computer
char* filenameToPath(const char* file){
	char* filepath =getExecutablePath();
	sprintf(filepath, "%s/wsp_data/",filepath); //create a string that holds the path to the wsp_data directory
	make_directory(filepath); //Make the wsp_data directory if it does not exist
	sprintf(filepath, "%s%s",filepath, file);//append the filename to the path
	return filepath;
}

//Consdier changing this to how many bytes have been moved over wifi
long numBytesExported(const char * filename){
	return (long)filesize(filenameToPath(filename));
}

//Write data to the onboard computer
void writeDataToFile(struct waspmoteCommand &command,std::string str){
	std::ofstream file; //open in constructor
	if( file ){
		char * path= filenameToPath(command.file.c_str());
		file.open(path, std::ios::app);
		file << str;
		file.close();
		std::cout<< "Writing data to:"<<path;
	}
}



//This can either be how data is written to the board or how it is exported over wifi
void exportData(struct waspmoteCommand &command,std::string str){
	std::cout <<str;
	writeDataToFile(command, str);
}

void populateCommandQueue(){
	time_t t = time(0);   // get time now
	const char* key = keys[keyIndex++];//gen_random_key();
	if(keyIndex >= 5)keyIndex = 0; //Reset the key index when we get to the end of the preset kyes
	struct tm * now = localtime( & t );
	char filename[13];
	unsigned long start = 0;

	struct tm * prev = localtime( & lastRequestTime);
	//generates a filename after the date of the previously written file
	//we don't use the current date because that could cause cause us to miss data recorded around midnight
	strftime(filename, sizeof(filename), "%y-%m-%d", prev);
	std::cout <<"FILE NAME:" << filename<<std::endl;
	start = numBytesExported(filename);//get the length of the file stored locally
	if(start == ULONG_MAX)start = 0;//If for some reason it can't get the length just start at 0;
	int numBytes = -1;//-1 indicated that we will just get all availiable data

	time_t elapseSync = abs(t-lastSyncTime);//The time since the last time we synced the clocks
	std::cout << "CLKS_COUNTDOWN:" << SYNC_FREQ-elapseSync << std::endl;
	time_t elapseRequest = abs(t-lastRequestTime);//The time since we last requested data from the waspmote
	std::cout << "FLRQ_COUNTDOWN:" << REQ_FREQ-elapseRequest << std::endl;

	//If it has been long enough add a clock sync command to the queue
	if(elapseSync >= SYNC_FREQ){
		commandQueue.push_back((struct waspmoteCommand)
				{syncClockCommand(now), "", "", 0, 0});
		lastSyncTime = t;
	}
	//If it has been long enough add a file request command to the queue
	if(elapseRequest >= REQ_FREQ){
		commandQueue.push_back((struct waspmoteCommand)
				{requestFileCommand(filename, key, start, numBytes),filename,key,start,numBytes});
		lastRequestTime = t;
	}

}



//This is the main function for the thread generated by this controller
void* startRoutine(void *threadarg)
{
	using namespace std;
	struct thread_data *my_data;
	my_data = (struct thread_data *) threadarg;

	int fd = serialport_init(my_data->port,115200);//Open the serial port
    int inputReadyBytes = 0;
    char c;

	while(my_data->loop){
		c = read_byte_blocking(fd); // read one byte from the waspmote
		std::cout << c;
		//Listen for when the waspmote says that it is ready
		if(c == InputReadyPattern[inputReadyBytes]){
			inputReadyBytes++;//Increment so that we test for the next byte in the pattern
		}else{
			inputReadyBytes = 0;//start listening from the beginning if the character doesn't match the next character in the pattern
		}
		//When it is ready send any queued commands
		if(inputReadyBytes >= strlen(InputReadyPattern)){
			printf("\n");
			commandQueue.clear();//Clear the command queue
			populateCommandQueue();//Generate a set of commands and add them to the queue

			//Put all the commands in the commands queue into one string
			sprintf(toWrite, "SRT&");
			for(int i=0; i < commandQueue.size(); i++){
				sprintf(toWrite, "%s%s", toWrite, (char *)commandQueue[i].str.c_str());
			}
			sprintf(toWrite, "%s%s", toWrite,"END&");
			printf("Sending message to waspmote:\n%s",toWrite);
			usleep(100000);//Wait a fraction of a second before sending to be sure the waspmote is ready
			serialport_write(fd, toWrite);
			for(int i=0; i < commandQueue.size(); i++){
				if(strlen(commandQueue[i].key.c_str()) > 0){
					std::string filestr;
					int err = readWaspmoteFile(filestr,fd,commandQueue[i].key.c_str());
					//if we got data from the waspmote and the checksums match then export the data to somewhere safe
					if(err == 0){
						exportData(commandQueue[i],filestr);
						printf("\n\n");
					}
				}
			}
			inputReadyBytes = 0;//Make sure we set this to zero so we wait again for the next inputReadyPattern
		}
	}
	serialport_close(fd);//Safely close the serial port
	pthread_exit(NULL); //kill the thread
}

//Constructor for waspmote  controller. Parameter port is the name of the port that the waspmote is connected to
//e.g "/dev/ttyUSB0"
WaspmoteController::WaspmoteController(const char* port){
	srand(time(0));
	waspmoteThreadData = {(char*)"Waspmote",0,true, port};
	int errorCode = pthread_create(&waspmoteThread, NULL, startRoutine, &waspmoteThreadData);
	if (errorCode != 0){
		std::cout << "Waspmote Thread could not be created. Self Destructing.";
		delete this;
	}
}
//Destructor for the controller
WaspmoteController::~WaspmoteController(){
	waspmoteThreadData.loop = false; //safely kill the thread by ending the loop
}

//Not used, but may be useful for checking for errors in this thread from the main thread
int WaspmoteController::getError(){
	return waspmoteThreadData.error;
}
