import barco.strip;
import barco.socket;
import std.math;
import std.stdio;
import std.range;
import std.algorithm;
import std.socket;
import std.random;
import std.container : SList;
import std.conv;
import core.thread;



static const double k=5*2*PI/LED_COUNT;
static const double omega=5*2*PI/LED_COUNT;

ubyte wavefunction(double amplitude, double x, double t, double offset){
	auto r=amplitude*(sin(k*x+t*omega+offset)+1)/2;
	return cast(ubyte)(r);
}

auto gauss(float x, float mu, float sigma){
	return exp(-((x-mu)/(sqrt(2.0)*sigma))^^2)/(sqrt(2*PI)*sigma);
}
auto trigauss(float x, float mu, float sigma){
	return gauss(x,mu,sigma)+gauss(x+1,mu,sigma)+gauss(x-1,mu,sigma);
}

auto leuchtturm(Color c, float offset, float phase, float sigma=1.0/15){
	return (c*trigauss(offset, phase, sigma)).repeat(LED_COUNT);
}

void do_leuchtturm(Color c=Color.YELLOW*0.1, uint i=10, float step=0.01, uint msecs=20){
	foreach(a; 0..i){
		foreach(phase; iota(0,1,step)){
			foreach(ii, ref s; sa){
				s.set(leuchtturm(c, 1.0*ii/15, phase));
				//writeln(s.toTerm());
			}
			Thread.sleep(dur!"msecs"(msecs));
			sock.send(sa);
		}
	}
}

void sleep_ms(int s){
	Thread.sleep(dur!"msecs"(s));
}

void do_epilepsy(float fs, Color a, Color b=Color.BLACK, float dur=3){
	foreach(i; 0..(cast(int)(dur*fs))){
		foreach(ii,ref s; sa){
			s.set(a.repeat(LED_COUNT));
		}
		sock.send(sa);
		sleep_ms(cast(int)(1000/fs/2));
		foreach(ii,ref s; sa){
			s.set(b.repeat(LED_COUNT));
		}
		sock.send(sa);
		sleep_ms(cast(int)(1000/fs/2));
	}
}

// l: wavelength
// t: temperature
float blackbody_spec(float l, float t){
	//float a = 1.191043e-16 / pow(l, 5); // 1.191043e-16 = 2 * h * c^2
	//float b = exp(0.0143877688f/(l*t)); // 0.0143877687 == h * c / k_B
	float a = 1.191043e-16 / pow(l, 5); // 1.191043e-16 = 2 * h * c^2
	float b = exp(0.0143877688f/(l*t)); // 0.0143877687 == h * c / k_B
	return a / (b-1);
}

Color heat_map_blackbody(float a, float t_max,float max_br=1f){
	float r = blackbody_spec(650e-9, a*t_max);
	float g = blackbody_spec(530e-9, a*t_max);
	float b = blackbody_spec(470e-9, a*t_max);
	float max = fmax(fmax(r,g),b);
	return Color(r/max, g/max, b/max) * max_br;
}

Color heat_map_blackbody_normalize(float t, float max_br=1f){
	float r = blackbody_spec(650e-9, t);
	float g = blackbody_spec(530e-9, t);
	float b = blackbody_spec(470e-9, t);
	float max = fmax(fmax(r,g),b);
	return Color(r/max, g/max, b/max) * max_br;
}

Color heat_map_flame(float a, float max_br=1f){
	a = fmin(1, 3*a);
	float red = (pow(a,2.2)*max_br);
	float green = (pow(a*0.85f,2.2)*max_br);
	float blue = (pow(a*0.28f,2.2)*(max_br));
	
	return Color(red, green, blue);
}


Color heat_map_flame_grad(float inten, float grad, Color a, Color b, float max_br=1f){
	inten = fmin(1, 3*inten);
	//Color c =  Color(1f, 0.9f, 0.3f) * (grad) + Color(1f,0.7f,0.05f) * (1-grad);
	Color c =  a * (grad) + b * (1-grad);
	c = c * inten;
	c.r = (pow(c.r,2.2));
	c.g = (pow(c.g,2.2));
	c.b = (pow(c.b,2.2));
	return c * max_br;
}

Color heat_map_blue(float a, ubyte max_br){
	a = fmin(1, a*3);
	return Color(
		cast(ubyte)(a*3f*(max_br>>2)),
		cast(ubyte)(a*3f*(max_br>>4)),
		cast(ubyte)(a*max_br)
		);
}

struct Spark {
	int str;
	float y, vel, dmp; // position, velociy, damping
}

void do_flame(float max_br=0.3f) {
	float[LED_COUNT+1][STRIP_COUNT] arr;
	foreach(i; 0..STRIP_COUNT){
		foreach(ii; 0..LED_COUNT){
			arr[i][ii] = 0.0f;
		}
	}
	auto spark_list = SList!Spark();

	int rotate = 0; 		// rotate flames to simulate wind  
	static immutable int MAX_ROT = 3;
	float activity = 0f; 	// vary flame activity over time
	//spark_list.insert(Spark(choice(iota(0,STRIP_COUNT)),LED_COUNT,-5f,0.5f));

	while(1){
		// activity
		activity = 0.1f * uniform(-1f, 1f) + 0.9f * activity;
		// calculate heat intensity arr
		foreach(i; 0..STRIP_COUNT){
			arr[i][LED_COUNT-1] = (0.3f + activity) * arr[i][LED_COUNT-1] + (0.7f + activity) * pow(uniform(0f, 1f), 3);
			//arr[i][LED_COUNT-1] = cast(float)((i%4) == 0);
		}
			// propagate intensity
		if(uniform(0f,1f) < 0.01f * (abs(rotate)+1)) { // make it more likely to change direction on outer values and more likely to stay on 0
			//rotate = clamp(rotate + choice(iota(-1,1)), -3, 3);
			rotate += clamp(choice(iota(-MAX_ROT,MAX_ROT))-rotate, -1, 1); // make it more likely to move towards 0
			rotate = clamp(rotate, -MAX_ROT, MAX_ROT);
		}
		foreach(i; 0..STRIP_COUNT){
			foreach(ii; 0..LED_COUNT-1){
				if(ii > 80){ // bottom
					float val = 1f * arr[i][ii];
					val += 0.05f * arr[(i+1)%STRIP_COUNT][ii];
					val += 0.05f * arr[(i-1+STRIP_COUNT)%STRIP_COUNT][ii];
					val += 4f * arr[i][ii+1];
					arr[i][ii] = val * 0.196; // damping is fideling factor
				}
				else{	// top
					int rot_idx = LED_COUNT/(abs(rotate)+1);
					if((ii%rot_idx) == 0){ // rotate at certain y-coordinates
						arr[i][ii] = arr[(i+STRIP_COUNT+clamp(rotate,-1,1))%STRIP_COUNT][ii+1] * 0.99f;
					}
					else {
						//arr[i][ii] = arr[i][ii+1] * 0.99f; // damping is fideling factor
						arr[i][ii] = pow(arr[i][ii+1], 1.01f) ; // damping is fideling factor
					}
				}
			}
		}
		
		// sparks
		if(uniform(0f,1f) < 0.02) {		// create new spark
			spark_list.insert(Spark(choice(iota(0,STRIP_COUNT)),cast(float)LED_COUNT,-0.05f,-0.03f));
		}

		//propagate sparks
		foreach(ref sp; spark_list){ 
			sp.y += sp.vel;
			sp.vel *= 1f - sp.dmp;
			if(sp.y < 0 || sp.y > LED_COUNT+1){
				spark_list.linearRemove(spark_list[].find(sp).take(1));
			}
		}

		// map to strips
		foreach(i, ref s; sa){
			Color[LED_COUNT] stripe;
			foreach(ii; 0..LED_COUNT){
				stripe[ii] = heat_map_flame_grad(
					arr[i][ii],
					//cast(float)ii / LED_COUNT ,//* 0.5f + 0.5f,
					min(1f, sqrt(sqrt(arr[i][ii]))),
					//Color.BLUE, 
					Color(1f, 0.9f, 0.3f), 
					Color(0.9f,0.4f,0.05f),
					//Color(0.9f,0.5f,0.15f), 
					
					//Color.RED,
					max_br * sqrt(cast(float)ii/60 + 0.0f) / sqrt(cast(float)LED_COUNT/60 + 0.0f),
					//max_br * exp(- cast(float)(LED_COUNT-ii) * 0.02),
					);
				foreach(ref sp; spark_list){
					if(i == cast(int)(sp.str) && ii == cast(int)(sp.y)){
						stripe[ii] = Color(1f,0.5f,0.05f) * 0.5 * max_br + stripe[ii];
					}
				}
			}
			s.set(stripe[]);
		}
		sock.send(sa);
		sleep_ms(4);

		// shift half pixel
		foreach(i, ref s; sa){
			foreach(ii; 0..LED_COUNT-1){
				s.leds[ii].color.r = (s.leds[ii].color.r>>1) + (s.leds[ii+1].color.r>>1);
				s.leds[ii].color.g = (s.leds[ii].color.g>>1) + (s.leds[ii+1].color.g>>1);
				s.leds[ii].color.b = (s.leds[ii].color.b>>1) + (s.leds[ii+1].color.b>>1);
			}
		}
		sock.send(sa);
		sleep_ms(5);
	}
}

void test_stripe_mapping(){
	foreach(i, ref s; sa){
		Color[LED_COUNT] stripe;
		foreach(ii; 0..LED_COUNT){
			if(ii  <  2 * (i+1)){
				stripe[ii] = Color.GREEN * 0.3 * ((ii+1)%2);
			}
			else{
				stripe[ii] = Color.BLACK;
			}
		}
		s.set(stripe[]);
	}
	sock.send(sa);
}

void test_map(float max_br=0.3f) {
	float[LED_COUNT+1][STRIP_COUNT] arr;
	foreach(i; 0..STRIP_COUNT){
		foreach(ii; 0..LED_COUNT){
			arr[i][ii] = (cast(float)ii)/LED_COUNT;
		}
	}
	auto spark_list = SList!Spark();

	// map to strips
	foreach(i, ref s; sa){
		Color[LED_COUNT] stripe;
		foreach(ii; 0..LED_COUNT){
			stripe[ii] = heat_map_blackbody(arr[i][ii], (i+1) * 1000f, max_br);
		}
		s.set(stripe[]);
	}
	sock.send(sa);
	//writeln(sa);
}

BarcoSocket sock;
StripArray sa;
void main(string[] args){
	sa.initialize();
	sock=new BarcoSocket(new InternetAddress(args[1], STRIP_PORT));
	//do_epilepsy(10, Color.WHITE*0.05);
	//test_map(0.1);
	//do_leuchtturm();
	//test_stripe_mapping();
	do_flame(args[2].to!float);
	//writeln(blackbody_spec(500e-9, 4000));
}
