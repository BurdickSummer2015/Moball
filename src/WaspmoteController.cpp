#include "WaspmoteController.h"
#include <iostream>
#include <boost/asio.hpp>

#include <boost/asio.hpp>

class SimpleSerial
{
public:
    /**
     * Constructor.
     * \param port device name, example "/dev/ttyUSB0" or "COM4"
     * \param baud_rate communication speed, example 9600 or 115200
     * \throws boost::system::system_error if cannot open the
     * serial device
     */
    SimpleSerial(std::string port, unsigned int baud_rate)
    : io(), serial(io,port)
    {
        serial.set_option(boost::asio::serial_port_base::baud_rate(baud_rate));
    }

    /**
     * Write a string to the serial device.
     * \param s string to write
     * \throws boost::system::system_error on failure
     */
    void writeString(std::string s)
    {
        boost::asio::write(serial,boost::asio::buffer(s.c_str(),s.size()));
    }

    /**
     * Blocks until a line is received from the serial device.
     * Eventual '\n' or '\r\n' characters at the end of the string are removed.
     * \return a string containing the received line
     * \throws boost::system::system_error on failure
     */
    std::string readLine()
    {
        //Reading data char by char, code is optimized for simplicity, not speed
        using namespace boost;
        char c;
        std::string result;
        for(;;)
        {
            asio::read(serial,asio::buffer(&c,1));
            switch(c)
            {
                case '\r':
                    break;
                case '\n':
                    return result;
                default:
                    result+=c;
            }
        }
    }
    char readByte(){
    	using namespace boost;
    	char c;
    	asio::read(serial,asio::buffer(&c,1));
    	return c;
    }




private:
    boost::asio::io_service io;
    boost::asio::serial_port serial;
};

char* InputReadyPattern = "Waspmote ready for input...";

void* startRoutine(void *threadarg)
{
	using namespace std;
	struct thread_data *my_data;
	my_data = (struct thread_data *) threadarg;

	SimpleSerial serial("/dev/ttyUSB1",115200);
    int inputReadyBytes = 0;
    char c;
	while(my_data->loop){

		c = serial.readByte();
		cout << c;
		if(c == InputReadyPattern[inputReadyBytes]){
			inputReadyBytes++;
		}else{
			inputReadyBytes = 0;
		}
		if(inputReadyBytes >= strlen(InputReadyPattern)){
			cout << "WOOOOOOOT";
			serial.writeString("SRT&CLKS:15:08:13:05:14:15:00!RQFL:15-08-13,sdfd,0,-1!END&");
		}

		//loop();
	}
	pthread_exit(NULL);
}



WaspmoteController::WaspmoteController(){
	waspmoteThreadData = {(char*)"Waspmote",0,true};
	int errorCode = pthread_create(&waspmoteThread, NULL, startRoutine, &waspmoteThreadData);
	if (errorCode != 0){
		std::cout << "DELTE";
		delete this;
	}
}
WaspmoteController::~WaspmoteController(){
	waspmoteThreadData.loop = false;
}

int WaspmoteController::getError(){
	return waspmoteThreadData.error;
}

/*
void startWaspmoteThread(){
waspmoteThreadData = {(char*)"Waspmote",0,true};
	int errorCode = pthread_create(&waspmoteThread, NULL, startRoutine, &waspmoteThreadData);
	if (errorCode != 0){
		std::cout << "ERROR";
	}
}*/
