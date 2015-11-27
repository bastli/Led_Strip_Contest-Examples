#include "util.h"
#include "strips.h"
#include "socket.h"
#include <math.h>
#ifndef M_PIl
	#define M_PIl 3.141592653589793238462643383279502884L
#endif
#include <stdint.h>
#include <unistd.h>

static const double k=5*2*M_PIl/LED_COUNT;
static const double omega=5*2*M_PIl/LED_COUNT;

uint8_t wavefunction(double amplitude, double x, double t, double offset){
	return (uint8_t)(amplitude*(sin(k*x+t*omega+offset)+1)/2);
}

int main(int argc, char **argv){
	Strip s;
	Socket sock;
	unsigned int i;
	socket_start();
	socket_open(&sock);
	double t=0;

	strip_zero(&s);

	while(1){
		for(i=0; i<LED_COUNT; i++){
			s.leds[i].r=wavefunction(255,i,t,0);
			s.leds[i].g=wavefunction(255,i,t,1);
		}

		for(i=0; i<STRIP_COUNT; i++){
			s.index=(unsigned char)i;
			strip_update(&sock, &s);
		}
		t+=0.2;
		Barco_sleep_ms(30);
	}
	socket_close(&sock);
	socket_stop();
	return 0;
}
