import barco.strip;
import barco.socket;
import std.math;
import std.stdio;
import std.range;
import std.algorithm;
import std.socket;
import core.thread;


static const double k=5*2*PI/LED_COUNT;
static const double omega=5*2*PI/LED_COUNT;

ubyte wavefunction(double amplitude, double x, double t, double offset){
	auto r=amplitude*(sin(k*x+t*omega+offset)+1)/2;
	return cast(ubyte)(r);
}

void main(){
	StripArray sa;
	sa.initialize();
	
	BarcoSocket sock=new BarcoSocket();
	
	double t=0;
	double off=0;
	immutable double ampl=255;
	auto r=iota(0,LED_COUNT).map!(a=>Color(wavefunction(ampl,a,t,off),wavefunction(ampl,a,t,off+1)));

	while(true){
		t+=1;
		if(t*omega>k*LED_COUNT){
			t=0;
		}
		foreach(i,ref s; sa){
			off=i*0.5;
			s.set(r);
		}
		sock.send(sa);
		Thread.sleep(dur!"msecs"(30));
	}
}
