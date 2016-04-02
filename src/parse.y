%{

#define YYDEBUG 1
#define YYERROR_VERBOSE 1

#include <assert.h>

#include "node.h"
#include "tstring.h"

static void node_lineinfo(parser_state *p, node *node) {
	if (!node) return;
	node->fname = p->fname;
	node->lineno = p->lineno;
}

%}

%union {
	node *nd;
	TString *id;
}

%type <nd> chunk block stats stat elseifpart elsepart forexplist localdecl retstat retstat0
%type <nd> funcname funcname0 varlist var namelist explist exp prefixexp
%type <nd> functioncall args functiondef funcbody parlist tableconstructor 
%type <nd> fieldlist fieldlist0 field fieldsep
%type <nd> Name Numeral LiteralString label

%pure-parser
%parse-param 	{parser_state *p}
%lex-param 		{p}


%{
int yylex(YYSTYPE *lval, parser_state *p);
static void yyerror(parser_state *p, const char *s);
%}

%token
		keyword_local
		keyword_if
		keyword_then
		keyword_else
		keyword_elseif
		keyword_while
		keyword_do
		keyword_repeat
		keyword_until
		keyword_break
		keyword_goto
		keyword_for
		keyword_in
		keyword_function
		keyword_end
		keyword_return
		keyword_nil
		keyword_true
		keyword_false
        op_plus
        op_minus
        op_mult
        op_div
		op_power
        op_mod
        op_eq
        op_neq
        op_lt
        op_le
        op_gt
        op_ge
        op_asgn
        op_and
        op_or
        op_not
        op_bar
        op_amper
        op_conc
		op_ellips
		op_len

%token
		LiteralString
		Numeral
		Name
		label


/*
 * precedence table
 */ 
%nonassoc op_LOWEST
 
%left  op_or
%left  op_and
%nonassoc  op_eq op_neq
%left  op_lt op_le op_gt op_ge
%right op_conc
%left  op_plus op_minus
%left  op_mult op_div op_mod
%left op_not op_len
%right op_power

%token op_HIGHEST

%%
chunk				: block
		 				{
							p->lval = $1;
						}

block 				: stats 
						{
							$$ = $1;
						} 
					| stats retstat
						{
							node_add_stat($1, $2);
							$$ = $1;
						}

stats 				:
						{
							$$ = node_new(NODE_BLOCK, p);
						} 
		  			| stats stat
						{
							if ($2) {
								node_add_stat($1, $2);
								$$ = $1;
							}
						}

stat 				: ';'
						{
							$$ = NULL; 
						}
		  			| varlist op_asgn explist
						{
							$$ = node_new(NODE_ASGN, p);
							node_asgn *n = (node_asgn *)$$;
							n->varlist = $1;
							n->explist = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| functioncall
						{
							$$ = $1;
						}
					| label
						{
							$$ = $1;
						}
					| keyword_break
						{
							/* TODO */
							$$ = node_new(NODE_BREAK, p);
						}
					| keyword_goto Name
						{
							/* TODO */
							$$ = node_new(NODE_GOTO, p);
							((node_goto *)$$)->name = $2;
							$2->parent = $$;
						}
					| keyword_do block keyword_end
						{
							$$ = node_new(NODE_DO, p);
							((node_do *)$$)->block = $2;
							$2->parent = $$;
						}
					| keyword_while exp keyword_do block keyword_end
						{
							$$ = node_new(NODE_WHILE, p);
							node_while *n = (node_while *)$$;
							n->exp = $2;
							n->block = $4;
							$2->parent = $$;
							$4->parent = $$;
							/* TODO */
						}
					| keyword_repeat block keyword_until exp
						{
							$$ = node_new(NODE_REPEAT, p);
							node_repeat *n = (node_repeat *)$$;
							n->block = $2;
							n->exp = $4;
							$2->parent = $$;
							$4->parent = $$;
						}
					| keyword_if exp keyword_then block elseifpart elsepart keyword_end
						{
							$$ = node_new(NODE_IF, p);
							node_if *n = (node_if *)$$;
							n->exp = $2;
							n->block = $4;
							n->elseif = $5;
							n->els = $6;
							$2->parent = $$;
							$4->parent = $$;
							if ($5) $5->parent = $$;
							if ($6) $6->parent = $$;
						}
					| keyword_for Name op_asgn forexplist keyword_do block keyword_end
						{
							$$ = node_new(NODE_FORR, p);
							node_forr *n = (node_forr *)$$;
							n->name = $2;
							n->forexplist = $4;
							n->block = $6;
							$2->parent = $$;
							$4->parent = $$;
							$6->parent = $$;
						}
					| keyword_for namelist keyword_in explist keyword_do block keyword_end
						{
							$$ = node_new(NODE_FORIN, p);
							node_forin *n = (node_forin *)$$;
							n->namelist = $2;
							n->explist = $4;
							n->block = $6;
							$2->parent = $$;
							$4->parent = $$;
							$6->parent = $$;
						}
					| keyword_function funcname funcbody
						{
							$$ = node_new(NODE_FUNC, p);
							node_func *n = (node_func *)$$;
							n->funcname = $2;
							n->funcbody = $3;
							$2->parent = $$;
							$3->parent = $$;
						}
					| keyword_local keyword_function Name funcbody
						{
							$$ = node_new(NODE_LFUNC, p);
							node_lfunc *n = (node_lfunc *)$$;
							n->name = $3;
							n->funcbody = $4;
							$3->parent = $$;
							$4->parent = $$;
						}
					| localdecl
						{
							$$ = $1;
						}


elseifpart 			: 
			  			{
			  				$$ = NULL;
						}
		   			| elseifpart keyword_elseif exp keyword_then block
						{
							if ($1 == NULL) {
			  					$1 = node_new(NODE_ELSEIF, p);
							}
							node *n = node_new(NODE_ELSEIF, p);
							((node_elseif *)n)->exp = $3;
							((node_elseif *)n)->block = $5;
							$3->parent = n;
							$5->parent = n;

							node_elseif *p = (node_elseif *)$1;
							while (p->next_elseif) {
								p = (node_elseif *)p->next_elseif;
							}
							/* p 指向链表尾结点 */
							p->next_elseif = n;
							((node_elseif *)n)->next_elseif = NULL;
						}

elsepart 			:
						{
							$$ = NULL;
						}
		 			| keyword_else block
						{
							$$ = node_new(NODE_ELSE, p);
							((node_else *)$$)->block = $2;
							$2->parent = $$;
						}

forexplist 			: exp ',' exp
			  			{
							$$ = node_new(NODE_FOREXPLIST, p);
							node_forexplist *n = (node_forexplist *)$$;
							n->start = $1;
							n->end = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp ',' exp ',' exp
			  			{
							$$ = node_new(NODE_FOREXPLIST, p);
							node_forexplist *n = (node_forexplist *)$$;
							n->start = $1;
							n->end = $3;
							n->step = $5;
							$1->parent = $$;
							$3->parent = $$;
							$5->parent = $$;
						}

localdecl			: keyword_local namelist
						{
							$$ = node_new(NODE_LASGN, p);
							((node_lasgn *)$$)->namelist = $2;
							$2->parent = $$;
						}
					| keyword_local namelist op_asgn explist
						{
							$$ = node_new(NODE_LASGN, p);
							((node_lasgn *)$$)->namelist = $2;
							((node_lasgn *)$$)->explist = $4;
							$2->parent = $$;
							$4->parent = $$;
						}

retstat 			: retstat0
		   				{
		   					$$ = $1;
						}
		   			| retstat0 ';'
						{
							$$ = $1;
						}

retstat0 			: keyword_return
						{
							$$ = node_new(NODE_RETURN, p);
						}
		   			| keyword_return explist
						{
							$$ = node_new(NODE_RETURN, p);
							((node_return *)$$)->explist = $2;
							$2->parent = $$;
						}



funcname 			: funcname0
						{
							$$ = $1;
						}
					| funcname0 ':' Name 
						{
							((node_funcname *)$1)->name = $3;
							$3->parent = $1;
							$$ = $1;
						}

funcname0 			: Name 
						{
			 				$$ = node_new(NODE_FUNCNAME, p);
							node_funcname *n = (node_funcname *)$$;
							if (n->len == n->maxLen) {
								realloc_vector( (void **)&n->pnames,  
								&n->len, sizeof(TString *) );
							}
							n->pnames[n->len] = $1;
							n->len++;
							$1->parent = $$;
						}
					| funcname0 '.' Name
						{
							node_funcname *n = (node_funcname *)$1;
							if (n->len == n->maxLen) {
								realloc_vector( (void **)&n->pnames,  
								&n->len, sizeof(TString *) );
							}
							n->pnames[n->len] = $3;
							n->len++;
							$$ = $1;
							$3->parent = $1;
						}


varlist 			: var
		  				{
		  					$$ = node_new(NODE_VARLIST, p);
							node_varlist *n = (node_varlist *)$$;
							if (n->len == n->maxLen) {
								realloc_vector( (void **)(&n->vars),
								&n->maxLen, sizeof(node *) );
							}
							n->vars[n->len] = $1;
							n->len++;
							$1->parent = $$;
						}
		   			| varlist ',' var
						{
							node_varlist *n = (node_varlist *)$1;
							if (n->len == n->maxLen) {
								realloc_vector( (void **)&n->vars,
								&n->maxLen, sizeof(node *) );
							}
							n->vars[n->len] = $3;
							$3->parent = $1;
							$$ = $1;
						}

var 				: Name
						{
							$$ = $1;
						}
					| prefixexp '[' exp ']'
						{
							$$ = node_new(NODE_INDEX, p);
							node_index *n = (node_index *)$$;
							n->prefixexp = $1;
							n->exp = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| prefixexp '.' Name
						{
							$$ = node_new(NODE_DOT, p);
							node_dot *n = (node_dot *)$$;
							n->prefixexp = $1;
							n->name = $3;
							$1->parent = $$;
							$3->parent = $$;
						}

namelist 			: Name
						{
							$$ = node_new(NODE_NAMELIST, p);
							node_namelist *n = (node_namelist *)$$;
							if (n->len == n->maxLen) {
								realloc_vector( (void **)(&n->names),
								&n->maxLen, sizeof(node *));
							}
							n->names[n->len] = $1;
							n->len++;
							$1->parent = $$;
						}
					| namelist ',' Name
						{
							node_namelist *n = (node_namelist *)$1;
							if (n->len == n->maxLen) {
								realloc_vector( (void **)(&n->names),
								&n->maxLen, sizeof(node *));
							}
							n->names[n->len] = $3;
							n->len++;
							$3->parent = $1;
							$$ = $1;
						}


explist 			: exp
						{
							$$ = node_new(NODE_EXPLIST, p);
							node_explist *n = (node_explist *)$$;
							if (n->len == n->maxLen) {
								realloc_vector( (void **)(&n->exps),
								&n->maxLen, sizeof(node *));
							}
							n->exps[n->len] = $1;
							n->len++;
							$1->parent = $$;
						}
		   			| explist ',' exp
						{
							node_explist *n = (node_explist *)$1;
							if (n->len == n->maxLen) {
								realloc_vector( (void **)(&n->exps),
								&n->maxLen, sizeof(node *));
							}
							n->exps[n->len] = $3;
							n->len++;
							$3->parent = $1;
							$$ = $1;
						}


exp 				: keyword_nil
						{
							$$ = node_new(NODE_NIL, p);
						}
					| keyword_false
						{
							$$ = node_new(NODE_FALSE, p);
						}
					| keyword_true
						{
							$$ = node_new(NODE_TRUE, p);
						}
					| Numeral
						{
							$$ = $1;
						}
					| LiteralString
						{
							$$ = $1;
						}
					| op_ellips
						{
							$$ = node_new(NODE_ELLIPS, p);
						}
					| functiondef
						{
							$$ = $1;
						}
					| prefixexp
						{
							$$ = $1;
						}
					| tableconstructor
						{
							$$ = $1;
						}
					| exp op_plus exp
						{
							$$ = node_new(NODE_PLUS, p);
							node_plus *n = (node_plus *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_minus exp
						{
							$$ = node_new(NODE_MINUS, p);
							node_minus *n = (node_minus *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_mult exp
						{
							$$ = node_new(NODE_MULT, p);
							node_mult *n = (node_mult *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_div exp
						{
							$$ = node_new(NODE_DIV, p);
							node_div *n = (node_div *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_mod exp
						{
							$$ = node_new(NODE_MOD, p);
							node_mod *n = (node_mod *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_eq exp
						{
							$$ = node_new(NODE_EQ, p);
							node_eq *n = (node_eq *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_neq exp
						{
							$$ = node_new(NODE_NEQ, p);
							node_neq *n = (node_neq *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_lt exp
						{
							$$ = node_new(NODE_LT, p);
							node_lt *n = (node_lt *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_le exp
						{
							$$ = node_new(NODE_LE, p);
							node_le *n = (node_le *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_gt exp
						{
							$$ = node_new(NODE_GT, p);
							node_gt *n = (node_gt *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_ge exp
						{
							$$ = node_new(NODE_GE, p);
							node_ge *n = (node_ge *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_and exp
						{
							$$ = node_new(NODE_AND, p);
							node_and *n = (node_and *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_or exp
						{
							$$ = node_new(NODE_OR, p);
							node_or *n = (node_or *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_conc exp
						{
							$$ = node_new(NODE_CONC, p);
							node_conc *n = (node_conc *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp op_power exp
						{
							$$ = node_new(NODE_POWER, p);
							node_power *n = (node_power *)$$;
							n->exp1 = $1;
							n->exp2 = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| op_minus exp			%prec op_not
						{
							$$ = node_new(NODE_UMINUS, p);
							node_uminus *n = (node_uminus *)$$;
							n->exp = $2;
							$2->parent = $$;
						}
					| op_not exp
						{
							$$ = node_new(NODE_NOT, p);
							node_not *n = (node_not *)$$;
							n->exp = $2;
							$2->parent = $$;
						}
					| op_len exp
						{
							$$ = node_new(NODE_OPLEN, p);
							node_oplen *n = (node_oplen *)$$;
							n->exp = $2;
							$2->parent = $$;
						}
					| '(' exp ')'
						{
							$$ = $2;
						}

prefixexp 			: var
			 			{
							$$ = $1;
						}
			 		| functioncall
						{
							$$ = $1;
						}

functioncall 		: prefixexp args
			   			{
							$$ = node_new(NODE_FUNCTIONCALL, p);
							node_functioncall *n = (node_functioncall *)$$;
							n->prefixexp = $1;
							n->args = $2;
							$1->parent = $$;
							if ($2) $2->parent = $$;
						}
			   		| prefixexp ':' Name args
			   			{
							$$ = node_new(NODE_FUNCTIONCALL, p);
							node_functioncall *n = (node_functioncall *)$$;
							n->prefixexp = $1;
							n->opt_name = $3;
							n->args = $4;
							$1->parent = $$;
							$3->parent = $$;
							if ($4) $4->parent = $$;
						}

args 				: '(' ')'
						{
							$$ = NULL;
						}
		 			| '(' explist ')'
						{
							$$ = $2;
						}
					| tableconstructor
						{
							$$ = $1;
						}
					| LiteralString
						{
							$$ = $1;
						}

functiondef 		: keyword_function funcbody
			  			{
							$$ = node_new(NODE_FUNCTIONDEF, p);
							((node_functiondef *)$$)->funcbody = $2;
							$2->parent = $$;
						}

funcbody 			: '(' parlist ')' block keyword_end
						{
							$$ = node_new(NODE_FUNCBODY, p);
							node_funcbody *n = (node_funcbody *)$$;
							n->parlist = $2;
							n->block = $4;
							if ($2) $2->parent = $$;
							$4->parent = $$;
						}

parlist 			: 
		   				{
		   					$$ = NULL;
						}
		   			| namelist 
						{
							$$ = node_new(NODE_PARLIST, p);
							node_parlist *n = (node_parlist *)$$;
							n->namelist = $1;
							n->dot3 = 1;
							$1->parent = $$;
						}
		   			| namelist ',' op_ellips
						{
							$$ = node_new(NODE_PARLIST, p);
							node_parlist *n = (node_parlist *)$$;
							n->namelist = $1;
							n->dot3 = 1;
							$1->parent = $$;
						}
		   			| op_ellips
						{
							$$ = node_new(NODE_PARLIST, p);
							node_parlist *n = (node_parlist *)$$;
							n->dot3 = 1;
						}

tableconstructor 	: '{' '}'
				  		{
				  			$$ = node_new(NODE_TABLECONSTRUCTOR, p);
						}
				  	| '{' fieldlist '}'
						{
				  			$$ = node_new(NODE_TABLECONSTRUCTOR, p);
							node_tableconstructor *n = 
										(node_tableconstructor *)$$;
							n->fieldlist = $2;
							$2->parent = $$;
						}

fieldlist 			: fieldlist0
			 			{
							$$ = $1;
						}
			 		| fieldlist0 fieldsep
						{
							$$ = $1;
						}


fieldlist0 			: field
			  			{
							$$ = node_new(NODE_FIELDLIST, p);
							node_fieldlist *n = (node_fieldlist *)$$;
							if (n->len == n->maxLen) {
								realloc_vector( (void **)(&n->fields),
								&n->maxLen, sizeof(node *));
							}
							n->fields[n->len] = $1;
							n->len++;
							$1->parent = $$;
						}
			  		| fieldlist0 fieldsep field
						{
							node_fieldlist *n = (node_fieldlist *)$1;
							if (n->len == n->maxLen) {
								realloc_vector( (void **)(&n->fields),
								&n->maxLen, sizeof(node *));
							}
							n->fields[n->len] = $3;
							n->len++;
							$3->parent = $1;
							$$ = $1;
						}

field 				: '[' exp ']' op_asgn exp
		 				{
		  					$$ = node_new(NODE_FIELD, p);
							node_field *n = (node_field *)$$;
							n->expl = $2;
							n->expr = $5;
							$2->parent = $$;
							$5->parent = $$;
						}
		  			| Name op_asgn exp
						{
		  					$$ = node_new(NODE_FIELD, p);
							node_field *n = (node_field *)$$;
							n->name = $1;
							n->expr = $3;
							$1->parent = $$;
							$3->parent = $$;
						}
					| exp
						{
		  					$$ = node_new(NODE_FIELD, p);
							node_field *n = (node_field *)$$;
							n->expl = $1;
						}

fieldsep 			: ','
						{}
					| ';'
						{}


%%

#include "lex.yy.c"


static void yyerror(parser_state *p, const char *s)
{
	++p->nerr;
	if (p->fname) {
    	fprintf(stderr, "%s:%d:%s\n", p->fname, yylineno, s);
	} else {
    	fprintf(stderr, "%d:%s\n", yylineno, s);
	}
}
