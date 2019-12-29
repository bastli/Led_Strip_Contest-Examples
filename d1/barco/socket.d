module barco.socket;
import barco.strip;
import std.socket;

enum STRIP_SERVER="10.6.66.10";
enum STRIP_PORT=1337;


/**
 * Maintains a Socket connection to the BarcoStrips
 * 
 */
class BarcoSocket{
	Socket sock;
	Address addr;
	
	/**
	 * Sets up the Socket using the given address.
	 * Params
	 * 	addr =	The adress to use.
	 */
	this(Address addr){
		sock=new UdpSocket(AddressFamily.INET);
		this.addr=addr;
	}
	
	/**
	 * Sets up the Socket using the hardcoded adress.
	 */
	this(){
		this(new InternetAddress(STRIP_SERVER, STRIP_PORT));
	}
	
	/**
	 * Sends the raw buffer to the socket.
	 * Params:
	 * 	buf =	The buffer to send;
	 * Returns:
	 * 	The bytes sent on sucess
	 */
	private ptrdiff_t send(void[] buf){
		return sock.sendTo(buf, SocketFlags.NONE, this.addr);
	}
	
	/**
	 * Sends a packet for every strip in the StripArray.
	 * Params:
	 * 	sa =	The StripArray to update.
	 * Returns:
	 * 	The total bytes sent on sucess
	 */
	ptrdiff_t send(in ref StripArray sa){
		ptrdiff_t pd=0;
		foreach(const ref s;sa.strips){
			pd+=send(s);
		}
		return pd;
	}
	
	/**
	 * Sends a packet for a single strip.
	 * Params:
	 * 	s =	The Strip to update.
	 * Returns:
	 * 	The bytes sent on sucess
	 */
	ptrdiff_t send(in ref Strip s){
		return send((cast(StripBuffer)s).buf);
	}
	
	///Closes the socket.
	void close(){
		sock.close();
	}
}
