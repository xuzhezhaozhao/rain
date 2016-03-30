#include "node.h"
#include "tstring.h"

#include "y.tab.h"
#include "lex.yy.h"
/* old bison does not have yyparse prototype in y.tab.h */
int yyparse(parser_state*);

void node_parse_init(parser_state *p) {
	p->nerr = 0;
	p->lval = NULL;
	p->fname = NULL;
	p->lineno = 1;
}

int node_parse_file(parser_state *p, const char *fname) {
	FILE *fp = fopen(fname, "rb");
	if (fp == NULL) {
		perror("fopen");
		return 0;
	}
	p->fname = fname;
	int r = node_parse_input(p, fp, fname) ;
	fclose(fp);
	return r;
}

int node_parse_input(parser_state *p, FILE *f, const char *fname) {
	yyrestart(f);
	int n = yyparse(p);
	if (0 == n && 0 == p->nerr) {
		return 0;
	}
	return 1;
}

int node_parse_string(parser_state *p, const char *prog) {
	p->fname = "-e";
	yy_scan_string(prog);
	int n = yyparse(p);
	if (0 == n && 0 == p->nerr) {
		return 0;
	}
	return 1;
}

void node_parse_free(parser_state *p) {
	/* TODO */
}

void dump_node(node *node, int indent) {
	/* TODO */
	
}
