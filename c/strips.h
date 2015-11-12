#pragma once
#include "util.h"
#include "socket.h"
#include <stdint.h>

#define ALIGN(SIZE) __attribute__((aligned(SIZE)))

///Holds the colour-values
typedef struct _LED{
	uint8_t r;
	uint8_t g;
	uint8_t b;
}ALIGN(1) LED;

#define LED_COUNT 112
#define STRIP_COUNT 15

///Holds the index and the various LED datas
typedef struct _Strip{
	uint8_t index;
	LED leds[LED_COUNT];
}ALIGN(1) Strip;

/**
 * Manipulate the Data in-place
 * 
 * Allows for things like:
 * ```C
 * 	union Strip_Buffer buf;
 * 	buf.data.index=0;
 * 	memset((void*)buf.data.leds, 0xFF, sizeof(buf.data.leds));
 * 	socket_send(sock, (Socket_Message){buf.buf, sizeof(buf.buf)});
 * ```
 * 
 */
union Strip_Buffer{
	Strip data;
	char buf[sizeof(Strip)];
};

/**
 * Updates the Strip_Buffer to socket
 * 
 * @param sock The socket to send the update to
 * @param buf The buffer to update
 * @return RETURN_ERROR on error, RETURN_OK on success
 */
extern RETURN_CODE strip_update_buffer(Socket *sock, union Strip_Buffer *buf);

/**
 * Updates the Strip to socket
 * 
 * @param sock The socket to send the update to
 * @param strip The strip to update
 * @return RETURN_ERROR on error, RETURN_OK on success
 */
extern RETURN_CODE strip_update(Socket *sock, Strip *strip);

/**
 * Zeroes all the LEDs
 * 
 * @param strip The strip to zero
 * @return RETURN_ERROR on error, RETURN_OK on success
 */
extern RETURN_CODE strip_zero(Strip *strip);

