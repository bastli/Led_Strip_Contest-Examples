import barco.strip;
import barco.socket;
import std.math;
import std.stdio;
import std.range;
import std.algorithm;
import std.random;
import std.format;
import std.typecons;
import std.path;
import std.socket;
import core.thread;
import std.traits;
//import mir.ndslice;



/**
 * Returns a floating-point number drawn from a _normal (Gaussian)
 * distribution with mean $(D mu) and standard deviation $(D sigma).
 * If no random number generator is specified, the default $(D rndGen)
 * will be used as the source of randomness.
 *
 * Note that this function uses two variates from the uniform random
 * number generator to generate a single normally-distributed variate.
 * It is therefore an inefficient means of generating a large number of
 * normally-distributed variates.  If you wish to draw many variates
 * from the _normal distribution, it is better to use the range-based
 * $(D normalDistribution) instead.
 */
auto normal(T1, T2)(T1 mu, T2 sigma)
    if (isNumeric!T1 && isNumeric!T2)
{
    return normal!(T1, T2, Random)(mu, sigma, rndGen);
}

/// ditto
auto normal(T1, T2, UniformRNG)(T1 mu, T2 sigma, UniformRNG rng)
    if (isNumeric!T1 && isNumeric!T2 && isUniformRNG!UniformRNG)
{
    import std.math;

    static if (isFloatingPoint!(CommonType!(T1, T2)))
    {
        alias T = CommonType!(T1, T2);
    }
    else
    {
        alias T = double;
    }

    immutable T _r1 = uniform01!T(rng);
    immutable T _r2 = uniform01!T(rng);

    return sqrt(-2 * log(1 - _r2)) * cos(2 * PI * _r1) * sigma + mu;
}


auto distance(Tuple!(int,int) a){
	enum xd = 70.0;
	enum yd = 1.0;
	return a[0]^^2*xd + a[1]^^2*yd;
}

float line_distance(Vector x, Vector p1, Vector p2){
	 return abs((p2.y-p1.y)*x.x - (p2.x-p1.x)*x.y + p2.x*p1.y - p2.y*p1.x)/(sqrt((p2.y-p1.y)^^2 + (p2.x - p1.x)^^2));
}


struct Image(T=float){
	enum w = STRIP_COUNT;
	enum h = LED_COUNT;
	T[h][w] board;
	
	int wrap(int x){
		return (x+10*w)%w;
	}
	
	auto byPixel(){
		return board[].map!((ref a)=>a[]).joiner;
	}
	
	void set(T v){
		byPixel().each!((ref p)=>p=v);
	}
	
	auto neighbourhood_map(Range)(uint i, uint j, Range r){
		return r.map!(a=>tuple((i+a[0]+w)%w,(j+a[1]))).filter!(a=>(a[1]>=0 && a[1]<h));
	}
	
	auto neighbourhood(Range)(uint i, uint j, Range r){
		ref get(Tuple!(uint,uint) a){
			return board[a[0]][a[1]];
		}
		return neighbourhood_map(i,j,r).map!get;
	}
	
	enum defaultNeighbourhood = [tuple(-1,-1), tuple(-1,0), tuple(-1,1), tuple(0,-1), tuple(0,1), tuple(1,-1), tuple(1,0), tuple(1,1)];
	
	
	auto neighbourhood(uint i, uint j){
		return neighbourhood(i,j,defaultNeighbourhood);
	}
	
	auto line(Vector a, Vector b){
		int x0 = cast(int)(min(a.x,b.x));
		int x1 = cast(int)(ceil(max(a.x,b.x)));
		int y0 = cast(int)(min(a.y,b.y));
		int y1 = cast(int)(ceil(max(a.y,b.y)));
		return cartesianProduct(iota(x0,x1),iota(y0,y1))
			.filter!(a=>a[1]>=0 && a[1]<h)
			.map!(x=>Vector(wrap(x[0]),x[1]))
			.map!(x=>tuple(x, 1-line_distance(x, a, b)))
			.filter!(a=>a[1]>0)
		;
	}
	
	auto indices(){
		return cartesianProduct(iota(0,w),iota(0,h));
	}
	
	ref opIndex(Vector p){
		return opIndex(cast(size_t)p.x,cast(size_t)p.y);
	}
	ref opIndex(size_t x, size_t y){
		return board[x][y];
	}
}

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

void do_leuchtturm(Color c=Color.YELLOW*0.075, uint i=10, float step=0.01, uint msecs=20){
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

Color freezemap(float f){
	Color c = Color.BLACK;
	auto coff = 1e-2;
	if(f > coff){
		c += Color.BLUE*((f-coff)*2);
	}
	c += Color.WHITE*(f^^2);
	return c*0.25;
}

void blit(in Image!Color img, ref StripArray sa){
	foreach(i,ref s; sa){
		s.set(img.board[i][]);
	}
}
void blit(T)(in Image!T img, ref StripArray sa, Color function(T) cmap){
	foreach(i,ref s; sa){
		s.set(img.board[i][].map!(a=>cmap(a)));
	}
}

void do_freeze(float fs, float p0=0.005, float bleed=0.005){
	Image!float img;
	foreach(ref f; img.byPixel()){
		f = (uniform(0.0,1.0) < p0) ? 1 : 0;
	}
	
	while(true){
		float diff=0;
		foreach(a; img.indices()){
			auto i = a[0];
			auto j = a[1];
			foreach(tpl, idx; zip(img.defaultNeighbourhood, img.neighbourhood_map(i,j,img.defaultNeighbourhood))){
				float *p = &img[idx[0],idx[1]];
				auto fac = bleed/distance(tpl);
				auto pn = clamp(*p+img[i,j]*fac, 0, 1);
				diff += abs(*p-pn);
				*p = pn;
			}
		}
		
		if(diff < 1e-2){
			break;
		}
		img.blit(sa, &freezemap);
		
		sock.send(sa);
		sleep_ms(cast(int)(1000/fs));
	}
}

struct Vector{
	float x,y;
	Vector opBinary(string op)(in Vector b) const{
		Vector v;
		mixin("v.x = this.x "~op~" b.x;");
		mixin("v.y = this.y "~op~" b.y;");
		return v;
	}
	Vector opBinary(string op)(in float b) const{
		Vector v;
		mixin("v.x = this.x "~op~" b;");
		mixin("v.y = this.y "~op~" b;");
		return v;
	}
	float norm()const{
		return x^^2+y^^2;
	}
}
struct Particle{
	Vector p,v;
	Vector function(Particle) a;
	Color c;
	Color function(Particle) color_transition;
	bool function(Particle) outscoped;
	
	Vector get_a(){
		if(a is null){
			return Vector(0,0);
		}
		return a(this);
	}
	
	bool step(){
		p = p + v;
		v = v + get_a();
		if(!(color_transition is null)){
			c = color_transition(this);
		}
		if(outscoped !is null){
			return !outscoped(this);
		}
		return true;
	}
}

import std.container;
struct Particles{
	SList!Particle system;
	size_t _length=0;
	void opOpAssign(string op="~")(Particle p){
		system.insert(p);
		_length++;
	}
	
	void step(){
		foreach(ref p; system[]){
			if(!p.step()){
				remove(p);
			}
		}
	}
	auto length()const{
		return _length;
	}
	
	void remove(Particle p){
		_length--;
		system.linearRemoveElement(p);
	}
	
	auto particles(){
		return system[];
	}
}

void blit(Particles System, ref StripArray sa){
	foreach(ref s; sa){
		s.set(Color.BLACK.repeat(LED_COUNT));
	}
	foreach(p; System.particles){
		p.p.x = (p.p.x + STRIP_COUNT) % STRIP_COUNT;
		sa.strips[cast(int)p.p.x].leds[cast(int)clamp(p.p.y,0,LED_COUNT-1)].c = convert_to_8bit(p.c);
	}
}

auto modulo(T)(T value, T m) {
    auto mod = value % m;
    if (value < 0) {
        mod += m;
    }
    return mod;
}

void blit(string op="=")(Particles System, ref Image!Color img){
	foreach(p; System.particles){
		p.p.x = modulo(p.p.x, STRIP_COUNT);
		mixin("img.board[cast(int)p.p.x][cast(int)clamp(p.p.y,0,LED_COUNT-1)] "~op~" p.c;");
	}
}

void blit_smooth(string op="=")(Particles System, ref Image!Color img){
	foreach(p; System.particles){
		p.p.x = (p.p.x + STRIP_COUNT*10) % STRIP_COUNT;
		foreach(pp,w; img.line(p.p,p.p-p.v)){
			mixin("img[cast(int)pp.x,cast(int)pp.y] "~op~" p.c*w;");
		}
	}
}

void do_fireworks(int num=100, float p0=0.01){
	Particles System;
	Particles Systemb;
	
	void add_sparks(Vector p, Vector v, Color c, float v0=0.1, int sparks=10){
		foreach(dir; iota(0,2*PI,2*PI/sparks)){
			auto x = cos(dir)*v0;
			auto y = sin(dir)*v0*5;
			Systemb ~= Particle(p, v+Vector(x,y), p=>Vector(0,0.005/(1)), c, (p)=>p.c*0.95);
		}
	}
	
	void add_firework(int x0){
		if(num-- > 0){
			System ~= Particle(Vector(x0,LED_COUNT),Vector(normal(0,0.05/2),0),p=>Vector(0,-0.01), Color.WHITE*0.25, p=>p.c + Color.WHITE*normal(0,0.3));
		}
	}
	
	Image!Color img;
	img.byPixel.each!((ref p)=>p=Color.BLACK);
	
	while(num > 0 || System.length + Systemb.length > 0){
		System.step();
		Systemb.step();
		//sa.strips.each!((ref a)=>a.set(Color.BLACK.repeat(LED_COUNT)));
		if(uniform(0.0,1.0) < p0){
			add_firework(uniform(0,STRIP_COUNT));
		}
		
		foreach(p; System.particles){
			if(p.p.y < 50 && uniform(1,50)>p.p.y){ //|| p.p.y >= img.h*0.75){
				add_sparks(p.p, p.v*0.25, Color.hsv(uniform(0.0,1.0),1,1), uniform(0.01,0.1), uniform(5,30));
				System.remove(p);
				continue;
			}
		}
		
		foreach(p; Systemb.particles){
			if(p.p.y >= img.h || p.c.norm() < 1e-6){
				Systemb.remove(p);
				continue;
			}
		}
		
		img.byPixel.each!((ref p) => p *= 0.9);
		blit_smooth!"+="(System, img);
		blit_smooth!"+="(Systemb, img);
		blit(img, sa);
		//blit(System, img);
		//blit(Systemb, sa);
		sock.send(sa);
		sleep_ms(10);
	}
}

Color blinkymap(Complex!float f){
	return blinkymap_inner(f)*0.5;
}

Color blinkymap_inner(Complex!float f){
	
	if(f.re < 0){
		return Color.BLACK;
	}
	else if(f.re < 1){
		float v = f.re*2;
		if(v > 1){
			v = 2-v;
		}
		return Color.hsv(f.im,1,v);
	}
	return Color.BLACK;
}

void sleep_fs(float fs){
	sleep_ms(cast(int)(1000/fs));
}

import std.complex;

void do_blinky(float delegate() hue=()=>uniform(0.0,1.0), float dur=60, float fs=100, float step=0.01, float p0 = 0.005){
	Image!(Complex!float) img;
	img.byPixel.each!((ref p)=>(p=-1));
	foreach(i; 0..(cast(int)(dur*fs))){
		foreach(ref p; img.byPixel){
			if(p.re >= 0){
				p.re += step;
				if(p.re > 1){
					p = -1;
				}
			}
			else{
				if(uniform(0.0,1.0) < p0){
					p.re = step;
					p.im = hue();
				}
			}
		}
		blit(img, sa, &blinkymap);
		sock.send(sa);
		sleep_fs(fs);
	}
}

void do_matrix(float dur=60, float fs=100, float p0=0.05){
	Particles system;
	
	void add(){
		system ~= Particle(Vector(uniform(0,15), 0), Vector(0,uniform(0.1,0.3)), (p)=>Vector(0,0), Color.GREEN*uniform(0.2,0.4)+Color.WHITE*0.25);
	}
	
	Image!Color img;
	
	foreach(ii; 0..(cast(int)(dur*fs))){
		system.step();
		if(uniform(0.0,1.0) < p0){
			add();
		}
		foreach(ref p; system.particles){
			if(p.p.y > img.h){
				system.remove(p);
			}
		}
		
		foreach(ref p; img.byPixel){
			p*=0.99;
			p.r=0;
			p.b=0;
		}
		blit(system, img);
		blit(img, sa);
		sock.send(sa);
		
		sleep_fs(fs);
	}
}


BarcoSocket sock;
StripArray sa;
void main(string[] args){
	sa.initialize();
	sock=new BarcoSocket(new InternetAddress(args[1], STRIP_PORT));
	
	switch(baseName(args[0])){
		case "leuchtturm":
			do_leuchtturm();
		break;
		case "freeze":
			do_freeze(100);
		break;
		case "fireworks":
			do_fireworks();
		break;
		case "blinky":
			do_blinky();
		break;
		case "christmas":
			do_blinky(()=>0.1);
		break;
		case "matrix":
			do_matrix();
		break;
		default:
		
		break;
	}
}
