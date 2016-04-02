#ifndef RAIN_NODE_C_
#define RAIN_NODE_C_

#include <assert.h>

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
	yylineno = 0;
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

void node_add_stat(node *block, node *stat) {
	assert(block != NULL && stat != NULL);
	assert(block->type == NODE_BLOCK);
	assert(stat->type == NODE_ASGN || stat->type == NODE_FUNCTIONCALL || \
		   stat->type == NODE_BREAK || stat->type == NODE_LABEL || \
		   stat->type == NODE_GOTO || stat->type == NODE_DO  || \
		   stat->type == NODE_WHILE || stat->type == NODE_REPEAT || \
		   stat->type == NODE_IF || stat->type == NODE_FORR || \
		   stat->type == NODE_FORIN || stat->type == NODE_FUNC || \
		   stat->type == NODE_LFUNC || stat->type == NODE_LASGN || \
		   stat->type == NODE_RETURN);

	node_block *b = (node_block *)block;
	if (b->len == b->maxLen) {
		realloc_vector( (void **)(&b->stats), &b->maxLen, sizeof(node *) );
	}

	b->stats[b->len] = stat;
	b->len++;
	stat->parent = block;
}

#define Binop_case(op_type1, op_type2) case NODE_##op_type1: \
	n = (node *)malloc(sizeof(node_##op_type2)); \
	if (!n) goto err; \
	n->type = NODE_##op_type1; \
	((node_##op_type2 *)n)->exp1 = NULL; \
	((node_##op_type2 *)n)->exp2 = NULL; \
	break

#define Unop_case(op_type1, op_type2) case NODE_##op_type1: \
	n = (node *)malloc(sizeof(node_##op_type2)); \
	if (!n) goto err; \
	n->type = NODE_##op_type1; \
	((node_##op_type2 *)n)->exp = NULL; \
	break



node *node_new(node_type type, parser_state *p) {
	node *n = NULL;
	switch (type) {
		case NODE_NUMBER:
			n = (node *)malloc(sizeof(node_number));
			if (!n) goto err;
			n->type = NODE_NUMBER;
			((node_number *)n)->is_integer = 0;
			((node_number *)n)->d = 0;
			break;
		case NODE_STRING:
			n = (node *)malloc(sizeof(node_string));
			if (!n) goto err;
			n->type = NODE_STRING;
			((node_string *)n)->ts = NULL;
			break;
		case NODE_NAME:
			n = (node *)malloc(sizeof(node_name));
			if (!n) goto err;
			n->type = NODE_NAME;
			((node_name *)n)->name = NULL;
			break;
		case NODE_NIL:
			n = (node *)malloc(sizeof(node_nil));
			if (!n) goto err;
			n->type = NODE_NIL;
			break;
		case NODE_BLOCK:
			n = (node *)malloc(sizeof(node_block));
			if (!n) goto err;
			n->type = NODE_BLOCK;
			((node_block *)n)->len = 0;
			((node_block *)n)->maxLen = 0;
			((node_block *)n)->stats = NULL;
			break;
		case NODE_ASGN:
			n = (node *)malloc(sizeof(node_asgn));
			if (!n) goto err;
			n->type = NODE_ASGN;
			((node_asgn *)n)->varlist = NULL;
			((node_asgn *)n)->explist = NULL;
			break;
		case NODE_FUNCTIONCALL:
			n = (node *)malloc(sizeof(node_functioncall));
			if (!n) goto err;
			n->type = NODE_FUNCTIONCALL;
			((node_functioncall *)n)->prefixexp = NULL;
			((node_functioncall *)n)->opt_name = NULL;
			((node_functioncall *)n)->args = NULL;
			break;
		case NODE_BREAK:
			n = (node *)malloc(sizeof(node_break));
			if (!n) goto err;
			n->type = NODE_BREAK;
			((node_break *)n)->dest = NULL;
			break;
		case NODE_GOTO:
			n = (node *)malloc(sizeof(node_goto));
			if (!n) goto err;
			n->type = NODE_GOTO;
			((node_goto *)n)->dest = NULL;
			((node_goto *)n)->name = NULL;
			break;
		case NODE_DO:
			n = (node *)malloc(sizeof(node_do));
			if (!n) goto err;
			n->type = NODE_DO;
			((node_do *)n)->block = NULL;
			break;
		case NODE_WHILE:
			n = (node *)malloc(sizeof(node_while));
			if (!n) goto err;
			n->type = NODE_WHILE;
			((node_while *)n)->exp = NULL;
			((node_while *)n)->block = NULL;
			break;
		case NODE_REPEAT:
			n = (node *)malloc(sizeof(node_repeat));
			if (!n) goto err;
			n->type = NODE_REPEAT;
			((node_repeat *)n)->block = NULL;
			((node_repeat *)n)->exp = NULL;
			break;
		case NODE_IF:
			n = (node *)malloc(sizeof(node_if));
			if (!n) goto err;
			n->type = NODE_IF;
			((node_if *)n)->exp = NULL;
			((node_if *)n)->block = NULL;
			((node_if *)n)->elseif = NULL;
			((node_if *)n)->els = NULL;
			break;
		case NODE_ELSEIF:
			n = (node *)malloc(sizeof(node_elseif));
			if (!n) goto err;
			n->type = NODE_ELSEIF;
			((node_elseif *)n)->exp = NULL;
			((node_elseif *)n)->block = NULL;
			((node_elseif *)n)->next_elseif = NULL;
			break;
		case NODE_ELSE:
			n = (node *)malloc(sizeof(node_else));
			if (!n) goto err;
			n->type = NODE_ELSE;
			((node_else *)n)->block = NULL;
			break;
		case NODE_FORR:
			n = (node *)malloc(sizeof(node_forr));
			if (!n) goto err;
			n->type = NODE_FORR;
			((node_forr *)n)->name = NULL;
			((node_forr *)n)->forexplist = NULL;
			((node_forr *)n)->block = NULL;
			break;
		case NODE_FORIN:
			n = (node *)malloc(sizeof(node_forin));
			if (!n) goto err;
			n->type = NODE_FORIN;
			((node_forin *)n)->namelist = NULL;
			((node_forin *)n)->explist = NULL;
			((node_forin *)n)->block = NULL;
			break;
		case NODE_FOREXPLIST:
			n = (node *)malloc(sizeof(node_forexplist));
			if (!n) goto err;
			n->type = NODE_FOREXPLIST;
			((node_forexplist *)n)->start = NULL;
			((node_forexplist *)n)->end = NULL;
			((node_forexplist *)n)->step = NULL;
			break;
		case NODE_FUNC:
			n = (node *)malloc(sizeof(node_func));
			if (!n) goto err;
			n->type = NODE_FUNC;
			((node_func *)n)->funcname = NULL;
			((node_func *)n)->funcbody = NULL;
			break;
		case NODE_LFUNC:
			n = (node *)malloc(sizeof(node_lfunc));
			if (!n) goto err;
			n->type = NODE_LFUNC;
			((node_lfunc *)n)->name = NULL;
			((node_lfunc *)n)->funcbody = NULL;
			break;
		case NODE_LASGN:
			n = (node *)malloc(sizeof(node_lasgn));
			if (!n) goto err;
			n->type = NODE_LASGN;
			((node_lasgn *)n)->namelist = NULL;
			((node_lasgn *)n)->explist = NULL;
			break;
		case NODE_RETURN:
			n = (node *)malloc(sizeof(node_return));
			if (!n) goto err;
			n->type = NODE_RETURN;
			((node_return *)n)->explist = NULL;
			break;
		case NODE_LABEL:
			n = (node *)malloc(sizeof(node_label));
			if (!n) goto err;
			n->type = NODE_LABEL;
			((node_label *)n)->name = NULL;
			((node_label *)n)->dest = NULL;
			break;
		case NODE_FUNCNAME:
			n = (node *)malloc(sizeof(node_funcname));
			if (!n) goto err;
			n->type = NODE_FUNCNAME;
			((node_funcname *)n)->len = 0;
			/* 8 magic number */
			((node_funcname *)n)->maxLen = 0;
			((node_funcname *)n)->pnames = NULL;
			((node_funcname *)n)->name = NULL;
			break;
		case NODE_VARLIST:
			n = (node *)malloc(sizeof(node_varlist));
			if (!n) goto err;
			n->type = NODE_VARLIST;
			((node_varlist *)n)->len = 0;
			((node_varlist *)n)->maxLen = 0;
			((node_varlist *)n)->vars = NULL;
			break;
		case NODE_INDEX:
			n = (node *)malloc(sizeof(node_index));
			if (!n) goto err;
			n->type = NODE_INDEX;
			((node_index *)n)->prefixexp = NULL;
			((node_index *)n)->exp = NULL;
			break;
		case NODE_DOT:
			n = (node *)malloc(sizeof(node_dot));
			if (!n) goto err;
			n->type = NODE_DOT;
			((node_dot *)n)->prefixexp = NULL;
			((node_dot *)n)->name = NULL;
			break;
		case NODE_NAMELIST:
			n = (node *)malloc(sizeof(node_namelist));
			if (!n) goto err;
			n->type = NODE_NAMELIST;
			((node_namelist *)n)->len = 0;
			((node_namelist *)n)->maxLen = 0;
			((node_namelist *)n)->names = NULL;
			break;
		case NODE_EXPLIST:
			n = (node *)malloc(sizeof(node_explist));
			if (!n) goto err;
			n->type = NODE_EXPLIST;
			((node_explist *)n)->len = 0;
			((node_explist *)n)->maxLen = 0;
			((node_explist *)n)->exps = NULL;
			break;
		case NODE_FUNCTIONDEF:
			n = (node *)malloc(sizeof(node_functiondef));
			if (!n) goto err;
			n->type = NODE_FUNCTIONDEF;
			((node_functiondef *)n)->funcbody = NULL;
			break;
		case NODE_FUNCBODY:
			n = (node *)malloc(sizeof(node_funcbody));
			if (!n) goto err;
			n->type = NODE_FUNCBODY;
			((node_funcbody *)n)->parlist = NULL;
			((node_funcbody *)n)->block = NULL;
			break;
		case NODE_PARLIST:
			n = (node *)malloc(sizeof(node_parlist));
			if (!n) goto err;
			n->type = NODE_PARLIST;
			((node_parlist *)n)->namelist = NULL;
			((node_parlist *)n)->dot3 = 0;
			break;
		case NODE_TABLECONSTRUCTOR:
			n = (node *)malloc(sizeof(node_tableconstructor));
			if (!n) goto err;
			n->type = NODE_TABLECONSTRUCTOR;
			((node_tableconstructor *)n)->fieldlist = NULL;
			break;
		case NODE_FIELDLIST:
			n = (node *)malloc(sizeof(node_fieldlist));
			if (!n) goto err;
			n->type = NODE_FIELDLIST;
			((node_fieldlist *)n)->len = 0;
			((node_fieldlist *)n)->maxLen = 0;
			((node_fieldlist *)n)->fields = NULL;
			break;
		case NODE_FIELD:
			n = (node *)malloc(sizeof(node_field));
			if (!n) goto err;
			n->type = NODE_FIELD;
			((node_field *)n)->name = NULL;
			((node_field *)n)->expl = NULL;
			((node_field *)n)->expr = NULL;
			break;
		case NODE_FALSE:
			n = (node *)malloc(sizeof(node_false));
			if (!n) goto err;
			n->type = NODE_FALSE;
			break;
		case NODE_TRUE:
			n = (node *)malloc(sizeof(node_true));
			if (!n) goto err;
			n->type = NODE_TRUE;
			break;
		case NODE_ELLIPS:
			n = (node *)malloc(sizeof(node_ellips));
			if (!n) goto err;
			n->type = NODE_ELLIPS;
			break;
		Binop_case(PLUS, plus);
		Binop_case(MINUS, minus);
		Binop_case(MULT, mult);
		Binop_case(DIV, div);
		Binop_case(POWER, power);
		Binop_case(MOD, mod);
		Binop_case(EQ, eq);
		Binop_case(NEQ, neq);
		Binop_case(LT, lt);
		Binop_case(LE, le);
		Binop_case(GT, gt);
		Binop_case(GE, ge);
		Binop_case(AND, and);
		Binop_case(OR, or);
		Binop_case(BAR, bar);
		Binop_case(AMPER, amper);
		Binop_case(CONC, conc);

		Unop_case(UMINUS, uminus);
		Unop_case(NOT, not);
		Unop_case(OPLEN, oplen);

		default:
			/* never reach here */
			assert(0);
	}
	n->fname = p->fname;
	n->lineno = p->lineno;
	n->parent = NULL;
	return n;
err:
	fprintf(stderr, "Error (node_new): Out of memory.\n");
	exit(1);
}


/* TODO 应该划分到别的文件中*/
void realloc_vector(void **v, int *old_len, int sz) {
	if (*old_len >= (1<<30)) {
		fprintf(stderr, "error realloc_vector len too large.\n");
		exit(1);
	}
	int new_len = 0;
	if (0 == *old_len) {
		new_len = 1;
	} else {
		new_len = 2 * (*old_len);
	}
	*v = realloc(*v, new_len * sz);
	*old_len = new_len;
}

#endif
