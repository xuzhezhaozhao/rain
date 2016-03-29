#include <stdio.h>

typedef struct {
	int nerr;
} parser_state;

#include "parse.tab.c"


int main(int argc, char *argv[])
{
	FILE *fp = fopen(argv[1], "rb");

	yylineno = 1;
	yyrestart(fp);

	parser_state p;
	yyparse(&p);
	
	return 0;
}
