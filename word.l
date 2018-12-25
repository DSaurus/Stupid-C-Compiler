%{
#include<bits/stdc++.h>
#include "y.tab.h"
using namespace std;
int num_lines = 0, num_chars = 0;
stack<string> ID_str;
map<string, int> sign_table;
map<string, int> ID_table;
int ID_label;
int getValue_16(char *s);
int getValue_8(char *s);
%}

%%
[\.\{\};\(\)\[\]\+\-\*/\<\>=,:] {  return sign_table[yytext]; }
!=|==|<=|>= {  return sign_table[yytext]; }
\+\+|-- {   return sign_table[yytext]; }
\<\<|\>\>|\^|\||&|~ {  return sign_table[yytext]; }
xor|and|or|not {   return sign_table[yytext]; }
&&|\|\||! {   return sign_table[yytext]; }
\'.\' {  return sign_table[yytext]; }

if|for|while|do|return|int|long|char|bool|string|float {  return sign_table[yytext];  }
cin|cout|endl {  return sign_table[yytext];  }
\"|\' {  return sign_table[yytext];  }
\/\/[^\n]* { cout<<setw(15)<<"COMMENT"<<setw(15)<<yytext<<endl; }
\/\*(\*+[^\/]|[^\*\/])*\*\/ {cout<<setw(15)<<"COMMENTBLOCK"<<setw(15)<<yytext<<endl; }
\/\/|\/\*|\*\/ {  return sign_table[yytext]; }
[a-zA-Z_]([a-zA-Z0-9_])* { if(!ID_table.count(yytext)) ID_table[yytext] = ++ID_label; ID_str.push(yytext); return ID; }
\"([^\"]|\\\")*\" { ID_str.push(yytext);  return STRING; }
[0-9]*\.[0-9][0-9]* { ID_str.push(yytext); return FLOAT_NUMBER; }
[1-9][0-9]* { ID_str.push(yytext); return INT_NUMBER; }
0[1-9][0-9]* { cout<<setw(15)<<"NUMBER"<<setw(15)<<yytext<<setw(15)<<getValue_8(yytext)<<endl; ID_str.push(yytext); }
0x[1-9][0-9]* { cout<<setw(15)<<"NUMBER"<<setw(15)<<yytext<<setw(15)<<getValue_16(yytext)<<endl; }
[0-0] { ID_str.push("0"); return INT_NUMBER;}
[\n\t] {}
" " {}
%%
string get_ID() { string t = ID_str.top(); ID_str.pop(); return t; }

int getValue_16(char *s) {
    int L = strlen(s);
    int ans = 0;
    for(int i = 2; i < L; i++){
        ans *= 16;
        if(s[i] >= 'a') ans += 10 + s[i] - 'a';
        else ans += s[i] - '0';
    }
    return ans;
}
int getValue_8(char *s) {
    int L = strlen(s);
    int ans = 0;
    for(int i = 1; i < L; i++){
        ans *= 8;
        ans += s[i] - '0';
    }
    return ans;
}

void init_pre_table(){
    sign_table[","] = COMMA;
    /*sign_table[":"] = "COLON";
    sign_table["."] = "DOT";*/
    sign_table["{"] = BL;
    sign_table["}"] = BR;
    sign_table[";"] = SEMI;
    sign_table["=="] = EQUAL;
    sign_table["!="] = NOTEQUAL;
    sign_table["="] = ASSIGN;
    sign_table["("] = SL;
    sign_table[")"] = SR;
    //sign_table["["] = "LBRACK";
    //sign_table["]"] = "RBRACK";
    sign_table["+"] = ADD;
    sign_table["-"] = SUB;
    sign_table["*"] = MUL;
    sign_table["/"] = DIV;
    sign_table["<"] = LESS;
    sign_table[">"] = MORE;
    sign_table["<="] = LESSORE;
    sign_table[">="] = MOREORE;
    /*sign_table["++"] = "INCRE";
    sign_table["--"] = "DECRE";
    sign_table["<<"] = "LEFTSHIFT";
    sign_table[">>"] = "RIGHTSHIFT";
    sign_table["^"] = "XOR";
    sign_table["|"] = "OR";
    sign_table["&"] = "AND";
    sign_table["~"] = "NOT";
    sign_table["xor"] = "XOR";
    sign_table["and"] = "AND";
    sign_table["or"] = "OR";
    sign_table["not"] = "NOT";
    sign_table["&&"] = "LOGICAND";
    sign_table["||"] = "LOGICOR";
    sign_table["!"] = "LOGICNOT";*/
    sign_table["if"] = IF;
    sign_table["for"] = FOR;
    sign_table["while"] = WHILE;
    //sign_table["do"] = "DO";
    //sign_table["return"] = "RETURN";
    sign_table["int"] = INT;
    //sign_table["long"] = "LONG";
    //sign_table["char"] = CHAR;
    sign_table["string"] = TSTRING;
    sign_table["float"] = FLOAT;
    //sign_table["bool"] = "BOOL";
    //sign_table["\""] = "DOUBLEQUATE";
    // sign_table["\'"] = "SINGLEQUATE";
    // sign_table["//"] = "COMMENT";
    // sign_table["/*"] = "LEFTCOMMENT";
    // sign_table["*/"] = "RIGHTCOMMENT";
    // sign_table["cout"] = "COUT";
    // sign_table["cin"] = "CIN";
    // sign_table["endl"] = "ENDL";
}


int yywrap(void){
    init_pre_table();
	return 1;
}