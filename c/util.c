#include "util.h"
#include <time.h>
#include <stdlib.h>

RETURN_CODE Barco_sleep_ms(long ms){
	struct timespec ts;
	ts.tv_sec=0;
	ts.tv_nsec=1000*1000;
	while(ms-->0){
		if(nanosleep(&ts, NULL)!=0){
			return RETURN_ERROR;
		}
	}
	return RETURN_OK;
}
