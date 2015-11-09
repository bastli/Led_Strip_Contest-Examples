#pragma once
#include <stdint.h>
#include <stdlib.h>
#include "util.h"
#ifdef _WIN32
	#include <winsock2.h>
#else
	#include <arpa/inet.h>
#endif

#define STRIP_SERVER "10.6.66.10"
#define STRIP_PORT 1337

typedef struct _Socket{
	int socket;
	struct sockaddr_in addr;
} Socket;


/**
 * Do some preliminary work to setup sockets
 * 
 * On windows, this function calls WSAStartup();
 * @return RETURN_ERROR on error, RETURN_OK on success
 */
extern RETURN_CODE socket_start(void);

/**
 * Cleanup sockets
 * 
 * On windows, this function calls WSACleanup();
 * @return RETURN_ERROR on error, RETURN_OK on success
 */
extern RETURN_CODE socket_stop(void);

/**
 * Opens a socket to addr:port
 * @param addr A string using the form "255.255.255.255"
 * @param port The port number
 * @return RETURN_ERROR on error, RETURN_OK on success
 */
extern RETURN_CODE socket_open_data(Socket *sock, const char *addr, uint16_t port);

/**
 * Opens a socket to the strips
 * @return RETURN_ERROR on error, RETURN_OK on success
 */
extern RETURN_CODE socket_open(Socket *sock);

/**
 * Closes the socket.
 * @return RETURN_ERROR on error, RETURN_OK on success
 */
extern RETURN_CODE socket_close(Socket *socket);

///Represent the message as a pointer and length.
typedef struct _Socket_Message{
	char *msg;
	size_t length;
}Socket_Message;

/**
 * Sends msg to sock
 * @param sock The socket to use
 * @param msg The message to send
 * @return -1 on error, the number of bytes sent otherwise
 */
extern size_t socket_send(const Socket *sock, const Socket_Message msg);
