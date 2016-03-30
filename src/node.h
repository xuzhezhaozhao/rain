#ifndef RAIN_NODE_H_
#define RAIN_NODE_H_

#include <stdio.h>

typedef struct parser_state {
	int nerr;
	void *lval;
	const char *fname;
	int lineno;
} parser_state;

typedef enum {
	/* TODO */
	NODE_NUMBER,
	NODE_STR,
	NODE_NIL,

} node_type;

#define NODE_HEADER node_type type; const char *fname; int lineno

typedef struct node {
	NODE_HEADER;
} node;

/* TODO  下面定义具体的 node 类型 */

typedef struct node_block {
	NODE_HEADER;
	int len;
	node *children;
} node_block;

void node_parse_init(parser_state*);
void node_parse_free(parser_state*);
int node_parse_file(parser_state*, const char*);
int node_parse_input(parser_state*, FILE* in, const char*);
int node_parse_string(parser_state*, const char*);

void dump_node(node *, int);

#endif
