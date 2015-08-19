#include "WaspmoteController.h"
#include <iostream>
#include <ctime>
//#include <boost/asio.hpp>

//#include <boost/asio.hpp>
//#include "SimpleSerial.h"


// arduino-serial-lib -- simple library for reading/writing serial ports
//
// 2006-2013, Tod E. Kurt, http://todbot.com/blog/
//


#include <stdio.h>    // Standard input/output definitions
#include <unistd.h>   // UNIX standard function definitions
#include <fcntl.h>    // File control definitions
#include <errno.h>    // Error number definitions
#include <termios.h>  // POSIX terminal control definitions
#include <string.h>   // String function definitions
#include <sys/ioctl.h>
#include <vector>
#include <stdlib.h>

// uncomment this to debug reads
//#define SERIALPORTDEBUG

// takes the string name of the serial port (e.g. "/dev/tty.usbserial","COM1")
// and a baud rate (bps) and connects to that port at that speed and 8N1.
// opens the port in fully raw mode so you can send binary data.
// returns valid fd, or -1 on error
int serialport_init(const char* serialport, int baud)
{
    struct termios toptions;
    int fd;

    //fd = open(serialport, O_RDWR | O_NOCTTY | O_NDELAY);
    fd = open(serialport, O_RDWR | O_NONBLOCK );

    if (fd == -1)  {
        perror("serialport_init: Unable to open port ");
        return -1;
    }

    //int iflags = TIOCM_DTR;
    //ioctl(fd, TIOCMBIS, &iflags);     // turn on DTR
    //ioctl(fd, TIOCMBIC, &iflags);    // turn off DTR

    if (tcgetattr(fd, &toptions) < 0) {
        perror("serialport_init: Couldn't get term attributes");
        return -1;
    }
    speed_t brate = baud; // let you override switch below if needed
    switch(baud) {
    case 4800:   brate=B4800;   break;
    case 9600:   brate=B9600;   break;
#ifdef B14400
    case 14400:  brate=B14400;  break;
#endif
    case 19200:  brate=B19200;  break;
#ifdef B28800
    case 28800:  brate=B28800;  break;
#endif
    case 38400:  brate=B38400;  break;
    case 57600:  brate=B57600;  break;
    case 115200: brate=B115200; break;
    }
    cfsetispeed(&toptions, brate);
    cfsetospeed(&toptions, brate);

    // 8N1
    toptions.c_cflag &= ~PARENB;
    toptions.c_cflag &= ~CSTOPB;
    toptions.c_cflag &= ~CSIZE;
    toptions.c_cflag |= CS8;
    // no flow control
    toptions.c_cflag &= ~CRTSCTS;

    //toptions.c_cflag &= ~HUPCL; // disable hang-up-on-close to avoid reset

    toptions.c_cflag |= CREAD | CLOCAL;  // turn on READ & ignore ctrl lines
    toptions.c_iflag &= ~(IXON | IXOFF | IXANY); // turn off s/w flow ctrl

    toptions.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG); // make raw
    toptions.c_oflag &= ~OPOST; // make raw

    // see: http://unixwiz.net/techtips/termios-vmin-vtime.html
    toptions.c_cc[VMIN]  = 0;
    toptions.c_cc[VTIME] = 0;
    //toptions.c_cc[VTIME] = 20;

    tcsetattr(fd, TCSANOW, &toptions);
    if( tcsetattr(fd, TCSAFLUSH, &toptions) < 0) {
        perror("init_serialport: Couldn't set term attributes");
        return -1;
    }

    return fd;
}

//
int serialport_close( int fd )
{
    return close( fd );
}

//
int serialport_writebyte( int fd, unsigned char b)
{
    int n = write(fd,&b,1);
    if( n!=1)
        return -1;
    return 0;
}

//
int serialport_write(int fd, const char* str)
{
    int len = strlen(str);
    int n = write(fd, str, len);
    if( n!=len ) {
        perror("serialport_write: couldn't write whole string\n");
        return -1;
    }
    return 0;
}

//
int serialport_read_until(int fd, char* buf, char until, int buf_max, int timeout)
{
    char b[1];  // read expects an array, so we give it a 1-byte array
    int i=0;
    do {
        int n = read(fd, b, 1);  // read a char at a time
        if( n==-1) return -1;    // couldn't read
        if( n==0 ) {
            usleep( 1 * 1000 );  // wait 1 msec try again
            timeout--;
            continue;
        }
#ifdef SERIALPORTDEBUG
        printf("serialport_read_until: i=%d, n=%d b='%c'\n",i,n,b[0]); // debug
#endif
        buf[i] = b[0];
        i++;
    } while( b[0] != until && i < buf_max && timeout>0 );

    buf[i] = 0;  // null terminate the string
    return 0;
}

//
int serialport_flush(int fd)
{
    sleep(2); //required to make flush work, for some reason
    return tcflush(fd, TCIOFLUSH);
}

char read_byte_blocking(int fd){
	char c;
	char* b = &c;
	while(1){
		int n = read(fd, b, 1);  // read a char at a time
		if( n==0 || n == -1 ) { // 0 no data, -1 error
			usleep( 1 * 1000 );  // wait 1 msec try again
		}else{
			break;
		}
	}
	return c;

}


char* InputReadyPattern = "Waspmote ready for input...";
char toWrite[100];

//Sets the inputed char* to a Clock Sync request with the following data
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

//Sets the inputed char* to a file request with the following data
std::string requestFileCommand(char*filename, const char*key, unsigned long start, long numBytes){
	std::cout<<"KEEEE:"<<key<<std::endl;
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



int readWaspmoteFile(std::string &filestr,int fd,const char* key){
	std::cout<<"KEY:"<<key<<std::endl;
	char checksum =0;
	char c;
	unsigned int keybytes=0;
	bool readingfile = false;
	unsigned int keylen = strlen(key);

	while(1){
		c = read_byte_blocking(fd);
		if(!readingfile){
			if(c == key[keybytes]){
				keybytes++;
			}else
			if(keybytes == keylen && c == '0'){
				readingfile = true;
				keybytes = 0;
				printf("\nReading file...\n");
			}
		}else{

			filestr.push_back(c);
			checksum ^= c;
			//printf("CHECKSUM:%i,%i\n",checksum, c);
			if(c == key[keybytes]){
				keybytes++;
			}else
			if(keybytes == keylen){
				checksum ^= c;
				//printf("CHECKSUM:%i,%i\n",checksum, c);
				for(int i= 0; i<keylen;i++){
					checksum ^= key[i];
					//printf("CHECKSUM:%i,%i\n",checksum, key[i]);
				}


				filestr.erase(filestr.size()-(keylen+1));
				printf("CHECK:%i,%i",checksum, c);
				if(checksum == c){
					return 0;
				}else{
					return 1;
				}
			}

		}
	}
}
struct waspmoteCommand{
	std::string str;
	const char * key;

};
std::vector<waspmoteCommand> commandQueue;
int commandQueueLen = 0;



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

time_t lastSyncTime = (time_t)0;
time_t lastRequestTime = (time_t)0;
const time_t SYNC_FREQ = (time_t)60;
const time_t REQ_FREQ = (time_t)1;

char* keys[] = {"D3f5", "df45", "pwc5", "39df", "Ekgl"};
int keyIndex = 0;

void populateCommandQueue(){

	char* filename = "15-08-18";



	int start = 0;
	int numBytes = -1;
	time_t t = time(0);   // get time now
	const char* key = keys[keyIndex++];//gen_random_key();
	if(keyIndex >= 5){
		keyIndex = 0;
	}


	std::cout << "KEYoo:" << key << std::endl;
	//rand();
	struct tm * now = localtime( & t );
	time_t elapseSync = abs(t-lastSyncTime);
	std::cout << "CLKS_COUNTDOWN:" << SYNC_FREQ-elapseSync << std::endl;
	time_t elapseRequest = abs(t-lastRequestTime);
	std::cout << "FLRQ_COUNTDOWN:" << REQ_FREQ-elapseRequest << std::endl;
	std::cout << "KEYoi:" << key << std::endl;

	std::cout << "KEYyr:" << key << std::endl;

	if(elapseSync >= SYNC_FREQ){
		commandQueue.push_back((struct waspmoteCommand)
				{syncClockCommand(now),""});
		lastSyncTime = t;
	}
	if(elapseRequest >= REQ_FREQ){
		std::cout << "KEYii:" << key << std::endl;
		commandQueue.push_back((struct waspmoteCommand)
				{requestFileCommand(filename, key, start, numBytes),key});
		lastRequestTime = t;
	}

}

void* startRoutine(void *threadarg)
{
	using namespace std;
	struct thread_data *my_data;
	my_data = (struct thread_data *) threadarg;

	int fd = serialport_init(my_data->port,115200);
    int inputReadyBytes = 0;
    char c;

	while(my_data->loop){
		c = read_byte_blocking(fd); // read one byte from the waspmote
		std::cout << c;
		//Listen for when the waspmote says that it is ready
		if(c == InputReadyPattern[inputReadyBytes]){
			inputReadyBytes++;
		}else{
			inputReadyBytes = 0;
		}
		//When it is ready send any queued commands
		if(inputReadyBytes >= strlen(InputReadyPattern)){
			std::cout<<std::endl;
			commandQueue.clear();//Clear the command queue
			populateCommandQueue();
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
				if(strlen(commandQueue[i].key) > 0){
					std::string filestr;
					int err = readWaspmoteFile(filestr,fd,commandQueue[i].key);
					cout <<filestr;
					if(err == 0){
						cout << "File read successfully";
					}else{
						cout << "Error while reading file";
					}

				}
			}

			inputReadyBytes = 0;//Make sure we set this to zero so we wait again for the next inputReadyPattern

		}
	}
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
WaspmoteController::~WaspmoteController(){
	waspmoteThreadData.loop = false; //safely kill the thread by ending the loop
}

int WaspmoteController::getError(){
	return waspmoteThreadData.error;
}
