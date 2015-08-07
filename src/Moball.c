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

/* Change the connection settings to your configuration. */
const char* const COM_PORT = "//dev//ttyUSB0";
const int BAUD_RATE = 115200;


int main()
{
	VN_ERROR_CODE errorCode;
	Vn100 vn100;
	//VnYpr ypr;
	VnQuaternion quaternion;
	int i;

	errorCode = vn100_connect(
		&vn100,
		COM_PORT,
		BAUD_RATE);

	/* Make sure the user has permission to use the COM port. */
	if (errorCode == VNERR_PERMISSION_DENIED) {

		printf("Current user does not have permission to open the COM port.\n");
		printf("Try running again using 'sudo'.\n");

		return 0;
	}
	else if (errorCode != VNERR_NO_ERROR)
	{
		printf("Error encountered when trying to connect to the sensor.\n");

		return 0;
	}

	//printf("Yaw, Pitch, Roll\n");
	printf("Quaternion x, Quaternion y, Quaternion z, Quaternion w \n");

	for (i = 0; i < 1000; i++)
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

	errorCode = vn100_disconnect(&vn100);

	if (errorCode != VNERR_NO_ERROR)
	{
		printf("Error encountered when trying to disconnect from the sensor.\n");

		return 0;
	}

	return 0;
}
