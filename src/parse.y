%{

#define YYDEBUG 1
#define YYERROR_VERBOSE 1

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

%type <nd> chunk block stats stat elsepart forexplist localdecl retstat retstat0
%type <nd> funcname funcname0 varlist var namelist explist exp prefixexp
%type <nd> functioncall args functiondef funcbody parlist tableconstructor 
%type <nd> fieldlist fieldlist0 field fieldsep
%type <id> Name 
%type <nd> Numeral LiteralString label

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
		lit_number
		lit_string
		identifier
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
							node_add_stat($1, $2);
							$$ = $1;
						}

stat 				: ';'
						{ }
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
							$$ = node_new(NODE_LABEL, p);
							node_label *n = (node_label *)$$;
							n->name = $1;
							/* TODO dest 指向下一条指令 */
							n->dest = NULL;
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
					| keyword_if exp keyword_then block elsepart keyword_end
						{
							$$ = node_new(NODE_IF, p);
							node_if *n = (node_if *)$$;
							n->exp = $2;
							n->block = $4;
							n->elsif = $5;
						}
					| keyword_for Name op_asgn forexplist keyword_do block keyword_end
					| keyword_for namelist keyword_in explist keyword_do block keyword_end
					| keyword_function funcname funcbody
					| keyword_local keyword_function Name funcbody
					| localdecl


elsepart			: 
		   			| keyword_else block
			 		| keyword_elseif exp keyword_then block elsepart

forexplist 			: exp
			  		| exp ',' exp
					| exp ',' exp ',' exp

localdecl			: keyword_local namelist
					| keyword_local namelist op_asgn explist

retstat 			: retstat0
		   			| retstat0 ';'

retstat0 			: keyword_return
		   			| keyword_return explist



funcname 			: funcname0
					| funcname0 ':' Name 

funcname0 			: Name 
					| funcname0 '.' Name


varlist 			: var
		   			| varlist ',' var

var 				: Name
					| prefixexp '[' exp ']'
					| prefixexp '.' Name

namelist 			: Name
					| namelist ',' Name


explist 			: exp
		   			| explist ',' exp


exp 				: keyword_nil
					| keyword_false
					| keyword_true
					| Numeral
					| LiteralString
					| op_ellips
					| functiondef
					| prefixexp
					| tableconstructor
					| exp op_plus exp
					| exp op_minus exp
					| exp op_mult exp
					| exp op_div exp
					| exp op_mod exp
					| exp op_eq exp
					| exp op_neq exp
					| exp op_lt exp
					| exp op_le exp
					| exp op_gt exp
					| exp op_ge exp
					| exp op_and exp
					| exp op_or exp
					| exp op_conc exp
					| exp op_power exp
					| op_minus exp			%prec op_not
					| op_not exp
					| op_len exp
					| '(' exp ')'

prefixexp 			: var
			 		| functioncall

functioncall 		: prefixexp args
			   		| prefixexp ':' Name args

args 				: '(' ')'
		 			| '(' explist ')'
					| tableconstructor
					| LiteralString

functiondef 		: keyword_function funcbody

funcbody 			: '(' parlist ')' block keyword_end

parlist 			: 
		   			| namelist 
		   			| namelist ',' op_ellips
		   			| op_ellips

tableconstructor 	: '{' '}'
				  	| '{' fieldlist '}'

fieldlist 			: field fieldlist0
			 		| field fieldlist0 fieldsep


fieldlist0 			: 
			  		| fieldlist0 fieldsep field

field 				: '[' exp ']' op_asgn exp
		  			| Name op_asgn exp
					| exp

fieldsep 			: ','
					| ';'



Name 				: identifier

Numeral 			: lit_number

LiteralString 		: lit_string


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
