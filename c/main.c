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
	s.index=0;
	for(i=0; i<LED_COUNT; i++){
		s.leds[i].r=s.leds[i].g=s.leds[i].b=wavefunction(255,i,0,0);
	}
	socket_start();
	
	socket_open(&sock);
	strip_update(&sock, &s);
	socket_close(&sock);
	
	socket_stop();
	return 0;
}
