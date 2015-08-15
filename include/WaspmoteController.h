//#include <stdio.h>
//#include <unistd.h>
#include <pthread.h>

struct thread_data{
   char* thread_id;
   int error;
   bool loop;
};

class WaspmoteController{
private:
	thread_data waspmoteThreadData; //Shared data between main thread and this
	pthread_t waspmoteThread; //The thread identifier
public:
	WaspmoteController(); //Constructor
	~WaspmoteController();//Destructor
	int getError();
};

/*
void startWaspmoteThread();
thread_data waspmoteThreadData;
pthread_t waspmoteThread;
*/
