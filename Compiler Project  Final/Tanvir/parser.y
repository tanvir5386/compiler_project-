%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

extern int line_num;
extern int yylex();
extern char* yytext;
void yyerror(char *s);

// Symbol table for variable storage

#define SYMBOL_TABLE_SIZE 100
typedef struct {
    char* name;
    int value;
} Symbol;

Symbol symbol_table[SYMBOL_TABLE_SIZE];
int symbol_count = 0;

// Function to look up a symbol in the table

int lookup_symbol(char* name) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

// Function to add a symbol to the table
int add_symbol(char* name, int value) {
    int index = lookup_symbol(name);
    if (index == -1) {
        if (symbol_count >= SYMBOL_TABLE_SIZE) {
            printf("Symbol table full\n");
            return -1;
        }
        symbol_table[symbol_count].name = strdup(name);
        symbol_table[symbol_count].value = value;
        return symbol_count++;
    } else {
        symbol_table[index].value = value;
        return index;
    }
}

// Function to get a symbol's value
int get_symbol_value(char* name) {
    int index = lookup_symbol(name);
    if (index == -1) {
        printf("Undefined variable: %s\n", name);
        return 0;
    }
    return symbol_table[index].value;
}

%}

%union {
    int num;
    char *id;
    char *str;
}

%token <num> NUMBER
%token <id> ID
%token <str> STRING
%token PRINT IF ELSE FOR
%token PLUS MINUS TIMES DIVIDE INC DEC
%token LT GT LE GE EQ NE ASSIGN
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON

/* Define precedence to resolve conflicts */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%left LT GT LE GE EQ NE
%left PLUS MINUS
%left TIMES DIVIDE
%right UMINUS
%right INC_EXPR DEC_EXPR  /* These are for expressions */
%left INC_STMT DEC_STMT   /* These are for statements */

%type <num> expr
%type <num> statement
%type <num> statement_list
%type <num> if_statement

%%

program:
    statement_list { printf("Program executed successfully\n"); }
    ;

statement_list:
    statement { $$ = $1; }
    | statement_list statement { $$ = $2; }
    ;

statement:
    expr SEMICOLON { 
        printf("Result: %d\n", $1); 
        $$ = $1; 
    }
    | ID ASSIGN expr SEMICOLON { 
        add_symbol($1, $3); 
        $$ = $3; 
    }
    | PRINT LPAREN expr RPAREN SEMICOLON { 
        printf("%d\n", $3); 
        $$ = $3; 
    }
    | PRINT LPAREN STRING RPAREN SEMICOLON { 
        // Remove surrounding quotes from the string
        char* str = $3 + 1;
        str[strlen(str) - 1] = '\0';
        printf("%s\n", str); 
        $$ = 0; 
    }
    | if_statement { $$ = $1; }
    | increment_statement { $$ = 0; }
    | decrement_statement { $$ = 0; }
    ;

increment_statement:
    ID INC SEMICOLON %prec INC_STMT { 
        int val = get_symbol_value($1);
        add_symbol($1, val + 1);
    }
    ;

decrement_statement:
    ID DEC SEMICOLON %prec DEC_STMT { 
        int val = get_symbol_value($1);
        add_symbol($1, val - 1);
    }
    ;

if_statement:
    IF LPAREN expr RPAREN statement %prec LOWER_THAN_ELSE {
        $$ = ($3 != 0) ? $5 : 0;
    }
    | IF LPAREN expr RPAREN statement ELSE statement {
        $$ = ($3 != 0) ? $5 : $7;
    }
    ;

expr:
    NUMBER { $$ = $1; }
    | ID { $$ = get_symbol_value($1); }
    | expr PLUS expr { $$ = $1 + $3; }
    | expr MINUS expr { $$ = $1 - $3; }
    | expr TIMES expr { $$ = $1 * $3; }
    | expr DIVIDE expr { 
        if ($3 == 0) {
            yyerror("Division by zero");
            $$ = 0;
        } else {
            $$ = $1 / $3; 
        }
    }
    | MINUS expr %prec UMINUS { $$ = -$2; }
    | LPAREN expr RPAREN { $$ = $2; }
    | ID INC %prec INC_EXPR { 
        int val = get_symbol_value($1);
        add_symbol($1, val + 1);
        $$ = val; // returns the value before increment
    }
    | ID DEC %prec DEC_EXPR { 
        int val = get_symbol_value($1);
        add_symbol($1, val - 1);
        $$ = val; // returns the value before decrement
    }
    | expr LT expr { $$ = $1 < $3; }
    | expr GT expr { $$ = $1 > $3; }
    | expr LE expr { $$ = $1 <= $3; }
    | expr GE expr { $$ = $1 >= $3; }
    | expr EQ expr { $$ = $1 == $3; }
    | expr NE expr { $$ = $1 != $3; }
    ;

%%

void yyerror(char *s) {
    fprintf(stderr, "Error at line %d: %s\n", line_num, s);
}

int main() {
    yyparse();
    return 0;
}