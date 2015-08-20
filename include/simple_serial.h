
#ifndef _SIMPLE_SERIAL_H_
#define _SIMPLE_SERIAL_H_

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

int serialport_init(const char* serialport, int baud);
int serialport_close( int fd );
int serialport_writebyte( int fd, unsigned char b);
int serialport_write(int fd, const char* str);
int serialport_read_until(int fd, char* buf, char until, int buf_max, int timeout);
int serialport_flush(int fd);
char read_byte_blocking(int fd);

#endif /* _SIMPLE_SERIAL_H_ */
