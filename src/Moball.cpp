//============================================================================
// Name        : Moball.cpp
// Author      : Caltech
// Version     :
// Copyright   : Your copyright notice
// Description : Hello World in C++, Ansi-style
//============================================================================

#include <stdio.h>
#include <unistd.h>
#include "vectornav.h"
#include "WaspmoteController.h"


/* Change the connection settings to your configuration. */
const char* const PORT0 = "//dev//ttyUSB0";
const char* const PORT1 = "//dev//ttyUSB1";
const int BAUD_RATE = 115200;
VnQuaternion quaternion;
VN_ERROR_CODE errorCode;
Vn100 vn100;





int initVectorNav(const char* PORT){
	errorCode = vn100_connect(
		&vn100,
		PORT,
		BAUD_RATE);

	/* Make sure the user has permission to use the COM port. */
	if (errorCode == VNERR_PERMISSION_DENIED) {

		printf("Current user does not have permission to open the COM port.\n");
		printf("Try running again using 'sudo'.\n");

		return 1;
	}
	else if (errorCode != VNERR_NO_ERROR)
	{
		printf("Error encountered when trying to connect to the sensor.\n");

		return 1;
	}
	return 0;
}

int closeVectorNav(){
	errorCode = vn100_disconnect(&vn100);

	if (errorCode != VNERR_NO_ERROR)
	{
		printf("Error encountered when trying to disconnect from the sensor.\n");

		return 1;
	}
	return 0;


}



int main()
{

	//VnYpr ypr;
	const char* WASPPORT = PORT1;
	if(initVectorNav(PORT0) != 0)return 1;

	int i;
	WaspmoteController *waspContHandle;
	waspContHandle = new WaspmoteController(WASPPORT);
	//startWaspmoteThread();





	//printf("Yaw, Pitch, Roll\n");
	printf("Quaternion x, Quaternion y, Quaternion z, Quaternion w \n");

	for (i = 0; i < 1; i++)
	{

		/* Query the YawPitchRoll register of the VN-100. Note this method of
		   retrieving the attitude is blocking since a serial command will be
		   sent to the physical sensor and this program will wait until a
		   response is received. */

		//errorCode = vn100_getYawPitchRoll(&vn100, &ypr);
		errorCode = vn100_getQuaternion(&vn100, &quaternion);

		//printf("  %+#7.2f %+#7.2f %+#7.2f\n", ypr.yaw, ypr.pitch, ypr.roll);
		printf("  %+#7.2f %+#7.2f %+#7.2f %+#7.2f\n", quaternion.x, quaternion.y, quaternion.z, quaternion.w);

		/* Wait for 1 second before we query the sensor again. */
		usleep(2000);

	}
	closeVectorNav();


	while(1){

	}

	return 0;
}
