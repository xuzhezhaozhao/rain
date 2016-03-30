/*
 * lex.l - rain lexer
 *
 */

%{
static int lex_return(parser_state *p, int c) {
	/* TODO */
	return c;
}

#define YY_DECL int yylex(YYSTYPE *lval, parser_state *p)
#define LEX_RETURN(c) return lex_return(p, c)

%}

%option noyywrap
%option yylineno
%option nounput

WHITESPACE ([ \t]+)
NEWLINE (\r|\n|\r\n)
TRAIL [\t \n]*
CHAR [a-zA-Z_]
CHNUM ({CHAR}|[0-9])
WORD {CHAR}{CHNUM}*
NUMBER ([0-9]+("."[0-9]*)?)|(([0-9]+)?"."[0-9]+)|([0-9]+("."[0-9]*)?[dDeEgG][+-]?[0-9]+)|(([0-9]+)?"."[0-9]+[dDeEgG][+-]?[0-9]+)

%%

{NEWLINE}		{}
{WHITESPACE}	{}


"+"  			LEX_RETURN(op_plus);
"-"  			LEX_RETURN(op_minus);
"*"  			LEX_RETURN(op_mult);
"/"  			LEX_RETURN(op_div);
"^"				LEX_RETURN(op_power);
"%"  			LEX_RETURN(op_mod);

"==" 			LEX_RETURN(op_eq);
"~="				LEX_RETURN(op_neq);
"!="				LEX_RETURN(op_neq);
"<"				LEX_RETURN(op_lt);
"<="				LEX_RETURN(op_le);
">"				LEX_RETURN(op_gt);
">="				LEX_RETURN(op_ge);
"="  			LEX_RETURN(op_asgn);

"and"			LEX_RETURN(op_and);
"or"				LEX_RETURN(op_or);
"not"			LEX_RETURN(op_not);
"!"				LEX_RETURN(op_not);
"~"				LEX_RETURN(op_not);
"&&" 			LEX_RETURN(op_and);
"||" 			LEX_RETURN(op_or);
"|"  			LEX_RETURN(op_bar);
"&"  			LEX_RETURN(op_amper);

".."			LEX_RETURN(op_conc);
"..."			LEX_RETURN(op_ellips);


local					LEX_RETURN(keyword_local);
if						LEX_RETURN(keyword_if);
then					LEX_RETURN(keyword_then);
else					LEX_RETURN(keyword_else);
elseif					LEX_RETURN(keyword_elseif);
while					LEX_RETURN(keyword_while);
do						LEX_RETURN(keyword_do);
repeat					LEX_RETURN(keyword_repeat);
until					LEX_RETURN(keyword_until);
break					LEX_RETURN(keyword_break);
goto					LEX_RETURN(keyword_goto);
for						LEX_RETURN(keyword_for);
in						LEX_RETURN(keyword_in);
function				LEX_RETURN(keyword_function);
end						LEX_RETURN(keyword_end);
return					LEX_RETURN(keyword_return);
nil						LEX_RETURN(keyword_nil);
true					LEX_RETURN(keyword_true);
false					LEX_RETURN(keyword_false);



{WORD}					LEX_RETURN(identifier);
{NUMBER}				LEX_RETURN(lit_number);

::{WORD}::				LEX_RETURN(label);

[(\[{,;:.]		 		LEX_RETURN(yytext[0]);
[)\]}]           		LEX_RETURN(yytext[0]);


\"([^\\\"]|\\.)*\"      {
  LEX_RETURN(lit_string);
}


. {
	char c = yytext[0];
	fprintf(stderr, "%s:%d:lexical error", p->fname, yylineno);

    if ((c & 0x80) || !isprint(c)) {
      fprintf(stderr, "('\\%03o').\n", c);
    }
    else if (c == '\\') {
      fprintf(stderr, "('\\\\').\n");
    }
    else {
      fprintf(stderr, "('%c').\n", c);
    }

	exit(1);
}
%%
