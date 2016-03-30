#ifndef RAIN_TSTRING_H_
#define RAIN_TSTRING_H_

typedef struct TString {
	int len;
	char buf[0];
} TString;

#endif
