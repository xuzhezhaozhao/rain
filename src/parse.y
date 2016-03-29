%{

#define YYDEBUG 1
#define YYERROR_VERBOSE 1


%}

%union {
	char *c;
	int n;
}

%type <c> keyword_local keyword_if keyword_then keyword_else keyword_elseif keyword_while keyword_do keyword_repeat keyword_until keyword_break keyword_goto keyword_for keyword_in keyword_function keyword_end keyword_return keyword_nil keyword_true keyword_false op_plus op_minus op_mult op_div op_mod op_eq op_neq op_lt op_le op_gt op_ge op_asgn op_and op_or op_not op_bar op_amper op_conc op_label op_ellips

%type <n> lit_number lit_string identifier


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
		op_label
		op_ellips

%token
		lit_number
		lit_string
		identifier


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
%left op_not
%right op_power

%token op_HIGHEST

%%
chunk				: block

block 				: stats 
					| stats retstat

stats 				:
		  			| stats stat

stat 				: ';'
		  			| varlist op_asgn explist
					| functioncall
					| label
					| keyword_break
					| keyword_goto Name
					| keyword_do block keyword_end
					| keyword_while exp keyword_do block keyword_end
					| keyword_repeat block keyword_until exp
					| keyword_if exp keyword_then block elsepart keyword_end
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


label 				: op_label Name op_label


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
					| op_plus exp			%prec op_not
					| op_minus exp			%prec op_not
					| op_not exp
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
    fprintf(stderr, "syntx error: %s at line %d.\n", s, yylineno);
}
