#ifndef RAIN_NODE_H_
#define RAIN_NODE_H_

#include <stdio.h>
#include "tstring.h"

typedef struct parser_state {
	int nerr;
	void *lval;
	const char *fname;
	int lineno;
} parser_state;

typedef enum {
	NODE_NUMBER,
	NODE_INTEGER,
	NODE_FLOAT,
	NODE_STRING,
	NODE_NAME,
	NODE_NIL,
	NODE_BLOCK,
	NODE_ASGN,
	NODE_FUNCTIONCALL,
	NODE_BREAK,
	NODE_GOTO,
	NODE_DO,
	NODE_WHILE,
	NODE_REPEAT,
	NODE_IF,
	NODE_ELSEIF,
	NODE_ELSE,
	NODE_FORR,
	NODE_FOREXPLIST,
	NODE_FORIN,
	NODE_FUNC,
	NODE_LFUNC,
	NODE_LASGN,
	NODE_RETURN,
	NODE_LABEL,
	NODE_FUNCNAME,
	NODE_VARLIST,
	NODE_INDEX,
	NODE_DOT,
	NODE_NAMELIST,
	NODE_EXPLIST,
	NODE_FUNCTIONDEF,
	NODE_FUNCBODY,
	NODE_PARLIST,
	NODE_TABLECONSTRUCTOR,
	NODE_FIELDLIST,
	NODE_FIELD,
	NODE_FALSE,
	NODE_TRUE,
	NODE_PLUS,
	NODE_MINUS,
	NODE_MULT,
	NODE_DIV,
	NODE_POWER,
	NODE_MOD,
	NODE_EQ,
	NODE_NEQ,
	NODE_LT,
	NODE_LE,
	NODE_GT,
	NODE_GE,
	NODE_AND,
	NODE_OR,
	NODE_BAR,
	NODE_AMPER, 
	NODE_CONC,
	NODE_UMINUS,
	NODE_NOT,
	NODE_OPLEN,
	NODE_ELLIPS
} node_type;

#define NODE_HEADER node_type type; const char *fname; int lineno; struct node *parent

typedef struct node {
	NODE_HEADER;
} node;


typedef struct node_number {
	NODE_HEADER;
	int is_integer;
	union {
		double d;
		long long i;
	};
} node_number;

typedef struct node_string {
	NODE_HEADER;
	TString *ts;
} node_string;

typedef struct node_name {
	NODE_HEADER;
	TString *name;
} node_name;

typedef struct node_nil {
	NODE_HEADER;
} node_nil;

typedef struct node_block {
	NODE_HEADER;
	int len;
	int maxLen;
	node **stats;
} node_block;


typedef struct node_asgn {
	NODE_HEADER;
	node *varlist;
	node *explist;
} node_asgn;

typedef struct node_functioncall {
	NODE_HEADER;
	node *prefixexp;
	node *opt_name;
	node *args;
} node_functioncall;

typedef struct node_break {
	NODE_HEADER;
	node *dest;
} node_break;

typedef struct node_goto {
	NODE_HEADER;
	node *dest;
	node *name;
} node_goto;

typedef struct node_do {
	NODE_HEADER;
	node *block;
} node_do;

typedef struct node_while {
	NODE_HEADER;
	node *exp;
	node *block;
} node_while;

typedef struct node_repeat {
	NODE_HEADER;
	node *block;
	node *exp;
} node_repeat;

typedef struct node_if {
	NODE_HEADER;
	node *exp;
	node *block;
	node *elseif;
	node *els;
} node_if;

/* elseif or else */
typedef struct node_elseif {
	NODE_HEADER;
	node *exp;
	node *block;
	node *next_elseif;
} node_elseif;

typedef struct node_else {
	NODE_HEADER;
	node *block;
} node_else;

typedef struct node_forr {
	NODE_HEADER;
	node *name;
	node *forexplist;
	node *block;
} node_forr;

typedef struct node_forin {
	NODE_HEADER;
	node *namelist;
	node *explist;
	node *block;
} node_forin;

typedef struct node_forexplist {
	NODE_HEADER;
	node *start;
	node *end;
	node *step;
} node_forexplist;

/* function */
typedef struct node_func {
	NODE_HEADER;
	node *funcname;
	node *funcbody;
} node_func;

/* local function */
typedef struct node_lfunc {
	NODE_HEADER;
	node *name;
	node *funcbody;
} node_lfunc;

/* local assign */
typedef struct node_lasgn {
	NODE_HEADER;
	node *namelist;
	node *explist;
} node_lasgn;

typedef struct node_return {
	NODE_HEADER;
	node *explist;
} node_return;

typedef struct node_label {
	NODE_HEADER;
	TString *name;
	node *dest;
} node_label;

/* Name { . Name } [: Name] */
typedef struct node_funcname {
	NODE_HEADER;
	int len;
	int maxLen;
	node **pnames;
	node *name;
} node_funcname;

typedef struct node_varlist {
	NODE_HEADER;
	int len;
	int maxLen;
	node **vars;
} node_varlist;

/* prefixexp[exp] */
typedef struct node_index {
	NODE_HEADER;
	node *prefixexp;
	node *exp;
} node_index;

/* prefixexp.name */
typedef struct node_dot {
	NODE_HEADER;
	node *prefixexp;
	node *name;
} node_dot;

typedef struct node_namelist {
	NODE_HEADER;
	int len;
	int maxLen;
	node **names;
} node_namelist;

typedef struct node_explist {
	NODE_HEADER;
	int len;
	int maxLen;
	node **exps;
} node_explist;

typedef struct node_functiondef {
	NODE_HEADER;
	node *funcbody;
} node_functiondef;

typedef struct node_funcbody {
	NODE_HEADER;
	node *parlist;
	node *block;
} node_funcbody;

typedef struct node_parlist {
	NODE_HEADER;
	node *namelist;
	/* 最后一个参数是否是 ... */
	int dot3;
} node_parlist;

typedef struct node_tableconstructor {
	NODE_HEADER;
	node *fieldlist;
} node_tableconstructor;

typedef struct node_fieldlist {
	NODE_HEADER;
	int len;
	int maxLen;
	node **fields;
} node_fieldlist;

/* [exp] = exp | name = exp | exp */
typedef struct node_field {
	NODE_HEADER;
	node *name;
	node *expl;
	node *expr;
} node_field;

typedef struct node_false {
	NODE_HEADER;
} node_false;

typedef struct node_true {
	NODE_HEADER;
} node_true;

typedef struct node_ellips {
	NODE_HEADER;
} node_ellips;

#define Binop_node(op) typedef struct node_##op { \
		NODE_HEADER;	\
		node *exp1;		\
		node *exp2;		\
	} node_##op

Binop_node(plus);
Binop_node(minus);
Binop_node(mult);
Binop_node(div);
Binop_node(power);
Binop_node(mod);
Binop_node(eq);
Binop_node(neq);
Binop_node(lt);
Binop_node(le);
Binop_node(gt);
Binop_node(ge);
Binop_node(and);
Binop_node (or);
Binop_node(bar);
Binop_node(amper);
Binop_node(conc);


#define Unop_node(op) typedef struct node_##op { \
		NODE_HEADER;	\
		node *exp;		\
	} node_##op


Unop_node(uminus);
Unop_node(not);
Unop_node(oplen);

void node_parse_init(parser_state*);
void node_parse_free(parser_state*);
int node_parse_file(parser_state*, const char*);
int node_parse_input(parser_state*, FILE* in, const char*);
int node_parse_string(parser_state*, const char*);

void dump_node(node *, int);

void node_add_stat(node *, node *);
node *node_new(node_type, parser_state *);

void realloc_vector(void **, int *, int);

#endif
