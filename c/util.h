#pragma once

typedef enum _RETURN_CODE{
	RETURN_ERROR=-1,
	RETURN_OK=0
} RETURN_CODE;

/**
 * Sleep for ms milliseconds.
 * 
 * @param ms The Millisecondes to sleep
 * @return RETURN_ERROR on error or on interrupt(see errno), RETURN_OK on success
 */
extern RETURN_CODE Barco_sleep_ms(long ms);
