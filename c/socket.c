#include "socket.h"
#include <string.h>
#ifdef _WIN32
	#include <winsock2.h>
#else
	#include <sys/socket.h>
	#include <unistd.h>
	#include <sys/types.h>
	#include <arpa/inet.h>
	#include <netinet/in.h>
	#define SOCKET_ERROR -1
#endif

RETURN_CODE socket_start(void){
	#ifdef _WIN32
		WSADATA wsa;
		if (WSAStartup(MAKEWORD(2,2),&wsa) != 0){
			return RETURN_ERROR;
		}
	#endif
	return RETURN_OK;
}
RETURN_CODE socket_stop(void){
	return RETURN_OK;
}
RETURN_CODE socket_open_data(Socket *sock, const char *addr, uint16_t port){
	sock->socket=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if(sock->socket==SOCKET_ERROR){
		return RETURN_ERROR;
	}
	memset((void*)&sock->addr, 0, sizeof(sock->addr));
	
	sock->addr.sin_family=AF_INET;
	sock->addr.sin_port=htons(port);
	#ifdef _WIN32
		sock->addr.sin_addr.S_un.S_addr = inet_addr(addr);
	#else
		if(inet_aton(addr , &sock->addr.sin_addr) == 0){
			close(sock->socket);
			return RETURN_ERROR;
		}
	#endif
	return RETURN_OK;
}

RETURN_CODE socket_open(Socket *sock){
	return socket_open_data(sock, STRIP_SERVER, STRIP_PORT);
}

RETURN_CODE socket_close(Socket *socket){
	int ret;
	#ifdef _WIN32
		ret=closesocket(socket->socket);
	#else
		ret=close(socket->socket);
	#endif
	return (ret==0) ? RETURN_OK : RETURN_ERROR;
}


size_t socket_send(const Socket *sock, const Socket_Message msg){
	return sendto(sock->socket, msg.msg, msg.length, 0, (struct sockaddr *)&sock->addr, sizeof(sock->addr));
}
