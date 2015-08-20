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
#include <pthread.h>

struct thread_data{
   char* thread_id;
   int error;
   bool loop;
   const char* port;
};

class WaspmoteController{
private:
	thread_data waspmoteThreadData; //Shared data between main thread and this
	pthread_t waspmoteThread; //The thread identifier
public:
	WaspmoteController(const char*); //Constructor
	~WaspmoteController();//Destructor
	int getError();
};

/*
void startWaspmoteThread();
thread_data waspmoteThreadData;
pthread_t waspmoteThread;
*/
