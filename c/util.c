#include "util.h"
#ifdef _WIN32
	#include <synchapi.h>
#else
	#include <time.h>
	#include <stdlib.h>
	#include <unistd.h>
#endif

RETURN_CODE Barco_sleep_ms(long ms){
	#ifdef _WIN32
		Sleep(ms);
	#else
		struct timespec ts;
		ts.tv_sec=0;
		ts.tv_nsec=1000*1000;
		while(ms-->0){
			if(nanosleep(&ts, NULL)!=0){
				return RETURN_ERROR;
			}
		}
	#endif
	return RETURN_OK;
}
