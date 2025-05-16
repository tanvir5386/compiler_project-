%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

void yyerror(char *s);
int line_num = 1;
%}

%%

"print"         { return PRINT; }
"if"            { return IF; }
"else"          { return ELSE; }

[a-zA-Z][a-zA-Z0-9_]*    { yylval.id = strdup(yytext); return ID; }
[0-9]+          { yylval.num = atoi(yytext); return NUMBER; }
\"[^\"]*\"      { yylval.str = strdup(yytext); return STRING; }

"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return TIMES; }
"/"             { return DIVIDE; }
"++"            { return INC; }
"--"            { return DEC; }
"<"             { return LT; }
">"             { return GT; }
"<="            { return LE; }
">="            { return GE; }
"=="            { return EQ; }
"!="            { return NE; }
"="             { return ASSIGN; }

"("             { return LPAREN; }
")"             { return RPAREN; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }
";"             { return SEMICOLON; }

[ \t]           { /* ignore whitespace */ }
[\n]            { line_num++; }
.               { printf("Unknown character %c\n", yytext[0]); }

%%

int yywrap(void) {
    return 1;
}