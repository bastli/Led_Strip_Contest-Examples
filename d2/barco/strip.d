module barco.strip;
import std.format;
import std.string;
import std.range;
import std.conv;
import std.traits;
import std.typecons;

///Number of LEDS in a strip
enum LED_COUNT=112;
///Number of strips in total
enum STRIP_COUNT=15;

/**
 * A struct for managing colors.
 * 
 * Allows for neat things like:
 * ---
 * Color c=Color.RED+Color.BLUE*0.25;
 * ---
 */

struct Color{
	float r,g,b;
	
	///Predefined colors
	static immutable Color BLACK=Color(0f,0f,0f);
	///ditto
	static immutable Color WHITE=Color(1f,1f,1f);
	///ditto
	static immutable Color RED=Color(1f,0f,0f);
	///ditto
	static immutable Color GREEN=Color(0f,1f,0f);
	///ditto
	static immutable Color BLUE=Color(0f,0f,1f);
	///ditto
	static immutable Color YELLOW=RED+GREEN;
	///ditto
	static immutable Color VIOLET=RED+BLUE;
	///ditto
	static immutable Color CYAN=GREEN+BLUE;
	
	/**
	 * Do a bounded operation on a.
	 * 
	 * Params:
	 * 	a = The lefthandside
	 * 	b = The righthandside. Must be a numeric type
	 * Returns:
	 * 	An ubyte containing the bounded result of the operation
	 */
	private static final float opSingleColor(string op, T)(in float a, in T b)if(isNumeric!T){
		mixin("auto res=a"~op~"b;");
		if(res>1f){
			return 1f;
		}
		else if(res<0f){
			return 0f;
		}
		return cast(float)res;
	}
	unittest{
		assert(opSingleColor!("+")(1f,0.1f)==1f);
		assert(opSingleColor!("+")(0.1f,1f)==1f);
		assert(opSingleColor!("*")(0.6f,2)==1f);
		assert(opSingleColor!("-")(0.1f,0.2f)==0f);
		assert(opSingleColor!("-")(0f,1f)==0f);
		assert(opSingleColor!("+")(0.1f,0.6f)==0.7f);
	}
	Color opBinary(string op)(in Color c2)const{
		return Color(
			opSingleColor!(op)(r,c2.r),
			opSingleColor!(op)(g,c2.g),
			opSingleColor!(op)(b,c2.b)
		);
	}
	Color opBinary(string op, T)(in T skalar) const if(isNumeric!T){
		return Color(
			opSingleColor!(op)(r,skalar),
			opSingleColor!(op)(g,skalar),
			opSingleColor!(op)(b,skalar)
		);
	}
	void opOpAssign(string op)(in Color c2){
		r=opSingleColor!(op)(r,c2.r);
		g=opSingleColor!(op)(g,c2.g);
		b=opSingleColor!(op)(b,c2.b);
	}
	void opOpAssign(string op, T)(in T skalar) if(isNumeric!T){
		r=opSingleColor!(op)(r,skalar);
		g=opSingleColor!(op)(g,skalar);
		b=opSingleColor!(op)(b,skalar);
	}
	string toString() const{
		return format("[%f, %f, %f]", r,g,b);
	}
	static Color hsv(float h, float s, float v){
		h *= 360;
		auto hi = cast(int)(h/60);
		auto f = (h/60 - hi);
		auto p = v * (1-s);
		auto q = v*(1-s*f);
		auto t = v*(1-s*(1-f));
		if(hi == 1){
			return Color(q,v,p);
		}
		else if(hi == 2){
			return Color(p,v,t);
		}
		else if(hi == 3){
			return Color(p,q,v);
		}
		else if(hi == 4){
			return Color(t,p,v);
		}
		else if(hi == 3){
			return Color(v,p,q);
		}
		else{
			return Color(v,t,p);
		}
	}
}
///
unittest{
	Color white=Color.WHITE;
	white/=2;
	assert(white==Color(127,127,127));
	assert(white/2==Color(127/2,127/2,127/2));
	assert(Color.WHITE+Color.WHITE==Color.WHITE);
}

struct Color8b {
	align(1):
	ubyte r,g,b;	

	string toString() const{
		return format("[%d, %d, %d]", r,g,b);
	}
	void opAssign(Color c){
		/*auto cc = convert_to_8bit(c);
		this.red=cc.red;
		this.green=cc.green;
		this.blue=cc.blue;*/
		this = convert_to_8bit(c);
	}
}

Color8b convert_to_8bit(Color c) {
	ubyte red = cast(ubyte)(c.r * 245f + 10);
	ubyte green = cast(ubyte)(c.g * 245f + 10);
	ubyte blue = cast(ubyte)(c.b * 245f + 10);

	return Color8b(red, green, blue);
	
}
/**
 * A container for a Color.
 * 
 */
struct LED{
	static private immutable string TermRepresentation="*";
	
	align (1):
	Color8b color;
	alias c=color;
	
	string toString() const{
		return c.toString();
	}
	
	/**
	 * Print an Representation of the LED in Truecolor with Escape sequences
	 */
	string toTerm() const{
		return format("\x1b[38;2;%d;%d;%dm"~TermRepresentation~"\x1b[0m", c.r,c.g,c.b);
	}
}

/**
 * A representation of an actual strip.
 * 
 * It contains an index and LED_COUNT struct LEDs.
 */
struct Strip{
	align (1):
	private ubyte _index;
	 
	LED[LED_COUNT] leds;
	
	@property void index(ubyte i)
	in{
		assert(i<STRIP_COUNT, "Strip index "~to!string(i)~" out of bounds");
	}
	body{
		_index=i;
	}
	
	@property ubyte index(){
		return _index;
	}
	
	/**
	 * Get a escape-sequenced representation of the strip.
	 * 
	 * Returns:
	 * 	A string containing the representation
	 */
	string toTerm() const{
		Appender!string app=appender!string();
		toTerm(app);
		return app.data;
	}
	
	/**
	 * Writes the escape-sequenced representation of the strip in app.
	 * 
	 * Params:
	 * 	app = The stringappender to add the representation to
	 */
	void toTerm(ref Appender!string app) const{
		static char[2] buf;
		app~=sformat(buf, "%02d", _index);
		app~=": ";
		foreach(const ref l; leds){
			app~=l.toTerm();
		}
	}
	
	/**
	 * Sets the colorvalues of the LEDs to the ones given in range
	 * 
	 * Params:
	 * 	range = A range containing colors
	 */
	void set(T)(T range) if(isInputRange!T && is(ElementType!T : Color))
	in{
		static if(!isInfinite!T){
			assert(range.length>=LED_COUNT);
		}
	}
	body{
		foreach(ref l; leds){
			l.color=convert_to_8bit(range.front);
			range.popFront();
		}
	}
	///
	unittest{
		Strip s;
		auto r=Color.BLUE.only.cycle;
		s.set(r);
		foreach(const ref led; s.leds){
			assert(led.color==Color.BLUE);
		}
	}
}

/**
 * A struct containing all of STRIP_COUNT strips
 * 
 * Make sure to initialize it with StripArray.initialize()
 */
struct StripArray{
	Strip[STRIP_COUNT] strips;
	mixin Proxy!strips;
	
	/**
	 * Initialize the array.
	 * 
	 * Mainly sets the index of every strip.
	 * 
	 */
	void initialize(){
		for(ubyte i=0; i<strips.length; i++){
			strips[i].index=i;
		}
	}
	
	/**
	 * Generates an escape-sequenced representation.
	 * 
	 * If resetcursor is true, the cursor gets reset after the sequences.
	 * Params:
	 * 	resetcursor = Move cursor to beginning after output
	 * Returns:
	 * 	A string containing all sequences
	 */
	string toTerm(bool resetcursor=true) const{
		Appender!string app=appender!string();
		if(resetcursor){
			app~="\033[s";
		}
		foreach(const ref s; strips){
			s.toTerm(app);
			app~="\n";
		}
		if(resetcursor){
			app~="\033[u";
		}
		return app.data;
	}
}
/**
 * Cheap serialization of the buffer.
 */
union StripBuffer{
	Strip data;
	char[Strip.sizeof] buf;
}
///
unittest{
	StripBuffer sb;
	static assert(__traits(compiles,"void[] buf=cast(void[])sb.buf;"));
	static assert(StripBuffer.sizeof==1+3*LED_COUNT);
}
