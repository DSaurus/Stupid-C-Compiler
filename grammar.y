%{
#include <stdio.h>
#include <iostream>
#include <map>
#include <vector>
#define YYSTYPE int
using namespace std;
string get_ID();
const int maxtot = (1<<10);
vector<int> G[maxtot];
int tot = 0, root, mtot = 0;

struct TYPET{
	const static int T_UNDEFINED = 0;
	const static int T_INT = 1;
	const static int T_STRING = 2;
	const static int T_FLOAT = 3;
	const static int T_ERROR = 4;
}TYPE;

struct NTYPET{
	const static int STMT = 0;
	const static int EXPR = 1;
}NTYPE;

const string TYPETABLE[7] = {"UNDEFINED", "INT", "STRING", "FLOAT", "ERROR"};
const string mtype[3] = {"Type Int", "Type String", "Type Float"};

struct TreeNode{
	int ntype;
	int type;
	string value;
	int addr;
	int label;
	TreeNode() { type = ntype = 0; }
}treeNode[maxtot];

struct Ids{
	int type;
	int addr;
};
map<string, Ids> Ids_table;
map<int, int> invIds_table;
int ID_ADDR = 0, LABEL = 0, TEMP_ID = 0;

void yyerror(const char* msg) {}
int yylex();
void init_pre_table();


void add_edge(int x, int y, int ty){
	mtot++;
	G[x].push_back(y);
}
void add_edge(int x, vector<int> y){
	for(int i = 0; i < y.size(); i++){
		mtot++;
		G[x].push_back(y[i]);
	}
}
%}

%token ADD SUB MUL DIV
%token SL SR BL BR
%token ID
%token TSTRING FLOAT INT
%token STRING FLOAT_NUMBER INT_NUMBER
%token IF ELSE FOR WHILE
%token SEMI COMMA
%token ASSIGN
%token EQUAL NOTEQUAL LESS LESSORE MORE MOREORE 
%%

main : main func { $$ = $1; add_edge($$, $2, 0); }
	 | func { $$ = ++tot; treeNode[tot].value = "Main"; root = tot; add_edge($$, $1, 0); }
	 ;

type : INT   { $$ = ++tot; treeNode[tot].value = "Type Int"; }
	 | TSTRING { $$ = ++tot; treeNode[tot].value = "Type String"; }
	 | FLOAT { $$ = ++tot; treeNode[tot].value = "Type Float"; }
	 ;

func : type ID SL var_list SR cp_stmt  {
			$$ = ++tot; treeNode[tot].value = "Function";
			
			$2 = ++tot; treeNode[tot].value = "symbol-" + get_ID();
			add_edge($$, {$1, $2, $4, $6});
		}
	 | ID SL var_list SR cp_stmt {  
		 	$$ = ++tot; treeNode[tot].value = "Function";
			$1 = ++tot; treeNode[tot].value = "symbol-" + get_ID();
			add_edge($$, {$1, $3, $5}); 
	  	}
	 ;

var_list : var_list COMMA type ID  { $$ = ++tot; treeNode[tot].value = "Var List"; $4 = ++tot; treeNode[tot].value = "symbol-" + get_ID(); add_edge($$, {$1, $3, $4}); }
		 | type ID {$$ = ++tot; treeNode[tot].value = "Var List"; $2 = ++tot; treeNode[tot].value = "symbol-" + get_ID(); add_edge($$, {$1, $2}); }
		 |   { $$ = ++tot; treeNode[tot].value = "Empty Variable List"; }
		 ;	 

stmts : stmts stmt { $$ = ++tot; treeNode[tot].value = "Stmts"; add_edge($$, {$1, $2}); }
	  | stmt { $$ = ++tot; treeNode[tot].value = "Stmts"; add_edge($$, $1, 0); }
	  ;

stmt : if_stmt { $$ = ++tot; treeNode[tot].value = "Stmt"; add_edge($$, $1, 0); }
	 | for_stmt { $$ = ++tot; treeNode[tot].value = "Stmt"; add_edge($$, $1, 0); }
	 | while_stmt  { $$ = ++tot; treeNode[tot].value = "Stmt"; add_edge($$, $1, 0); }
	 | assign_stmt  { $$ = ++tot; treeNode[tot].value = "Stmt"; add_edge($$, $1, 0); }
	 | id_stmt  { $$ = ++tot; treeNode[tot].value = "Stmt"; add_edge($$, $1, 0); }
	 | expr_stmt  { $$ = ++tot; treeNode[tot].value = "Stmt"; add_edge($$, $1, 0); }
	 | cp_stmt  { $$ = ++tot; treeNode[tot].value = "Stmt"; add_edge($$, $1, 0); }
	 | func_call_stmt  { $$ = ++tot; treeNode[tot].value = "Stmt"; add_edge($$, $1, 0); }
	 ;

if_stmt : IF SL expr SR stmt { $$ = ++tot; treeNode[tot].value = "If Stmt"; add_edge($$, {$3, $5}); }
	    | IF SL expr SR stmt ELSE stmt { $$ = ++tot; treeNode[tot].value = "If Stmt"; add_edge($$, {$3, $5, $7}); }
		;

for_stmt : FOR SL id_stmt expr_stmt expr SR stmt { $$ = ++tot; treeNode[tot].value = "For Stmt"; add_edge($$, {$3, $4, $5, $7}); }
	     | FOR SL expr_stmt expr_stmt expr SR stmt { $$ = ++tot; treeNode[tot].value = "For Stmt"; add_edge($$, {$3, $4, $5, $7}); }
		 ;

while_stmt : WHILE SL expr SR stmt { $$ = ++tot; treeNode[tot].value = "While Stmt"; add_edge($$, {$3, $5}); }
		   ;

assign_stmt : assign_expr SEMI { $$ = ++tot; treeNode[tot].value = "Assign Stmt"; add_edge($$, $1, 0); }
		    ;

id_stmt : type id_list SEMI { $$ = ++tot; treeNode[tot].value = "ID Stmt"; add_edge($$, {$1, $2}); }
		;

id_list : id_list COMMA assign_expr {$$ = ++tot; treeNode[tot].value = "ID LIST",  add_edge($$, {$1, -',', $3}); }
		| id_list COMMA ID { $$ = ++tot; treeNode[tot].value = "ID List"; $3 = ++tot; treeNode[tot].value = "symbol-" + get_ID(); add_edge($$, {$1, -',', $3}); }
		| assign_expr { $$ = ++tot; treeNode[tot].value = "ID List"; add_edge($$, $1, 0); }
	    | ID { $$ = ++tot; treeNode[tot].value = "ID List"; $1 = ++tot; treeNode[tot].value = "symbol-" + get_ID(); add_edge($$, $1, 0); }
		;

expr_stmt : expr SEMI { $$ = ++tot; treeNode[tot].value = "Expr Stmt"; add_edge($$, $1, 0); }
		  ;

cp_stmt : BL stmts BR { $$ = ++tot; treeNode[tot].value = "Compound Stmt"; add_edge($$, $2, 0); }
	    | BL BR { $$ = ++tot; treeNode[tot].value = "Compound Stmt"; } 
		;

func_call_stmt : func_expr SEMI { $$ = ++tot; treeNode[tot].value = "Function Call Stmt"; add_edge($$, $1, 0); }
			   ;

expr : rela_expr { $$ = ++tot; treeNode[tot].value = "Expr"; add_edge($$, $1, 0); }
	 | assign_expr { $$ = ++tot; treeNode[tot].value = "Expr"; add_edge($$, $1, 0); }
	 | func_expr { $$ = ++tot; treeNode[tot].value = "Expr"; add_edge($$, $1, 0); }
	 | 		{ $$ = ++tot; treeNode[tot].value = "Blank Expr"; }
	 ;

func_expr : ID SL SR { $$ = ++tot; treeNode[tot].value = "Function Call Expr"; $1 = ++tot; treeNode[tot].value = "symbol-" + get_ID(); add_edge($$, $1, 0); }
		  | ID SL id_list SR { $$ = ++tot; treeNode[tot].value = "Function call Expr"; $1 = ++tot; treeNode[tot].value = "symbol-" + get_ID(); add_edge($$, {$1, $3}); }
		  ;

rela_expr : rela_expr LESS add_expr { $$ = ++tot; treeNode[tot].value = "Less Expr"; add_edge($$, {$1, -'<', $3}); }
		  | rela_expr MORE add_expr { $$ = ++tot; treeNode[tot].value = "More Expr"; add_edge($$, {$1, -'>', $3}); }
		  | rela_expr LESSORE add_expr { $$ = ++tot; treeNode[tot].value = "LessOrEqual Expr"; add_edge($$, {$1, -'<'-128, $3}); }
		  | rela_expr MOREORE add_expr { $$ = ++tot; treeNode[tot].value = "MoreOrEqual Expr"; add_edge($$, {$1, -'>'-128, $3}); }
		  | rela_expr EQUAL add_expr { $$ = ++tot; treeNode[tot].value = "Equal Expr"; add_edge($$, {$1, -'='-128, $3}); }
		  | rela_expr NOTEQUAL add_expr {$$ = ++tot; treeNode[tot].value = "NotEqual Expr"; add_edge($$, {$1, -'='-256, $3}); }
		  | add_expr {$$ = ++tot; treeNode[tot].value = "Rela Expr"; add_edge($$, $1, 0); }
		  ;

assign_expr : ID ASSIGN expr { $$ = ++tot; treeNode[tot].value = "Assign Expr"; $1 = ++tot; treeNode[tot].value = "symbol-" + get_ID(); add_edge($$, {$1, -'=', $3}); }
		    ;

add_expr : add_expr ADD mul_expr { $$ = ++tot; treeNode[tot].value = "Add Expr";  add_edge($$, {$1, -'+', $3}); }
		 | add_expr SUB mul_expr { $$ = ++tot; treeNode[tot].value = "Sub Expr"; add_edge($$, {$1, -'-', $3}); }
		 | mul_expr { $$ = ++tot; treeNode[tot].value = "Add Expr"; add_edge($$, $1, 0); }
		 ;

mul_expr : mul_expr MUL id_expr { $$ = ++tot; treeNode[tot].value = "Mul Expr"; add_edge($$, {$1, -'*', $3}); }
		 | mul_expr DIV id_expr { $$ = ++tot; treeNode[tot].value = "Div Expr"; add_edge($$, {$1, -'/', $3}); }
		 | id_expr {$$ = ++tot; treeNode[tot].value = "Mul Expr"; add_edge($$, $1, 0); }
		 ;

id_expr : STRING { $$ = ++tot; treeNode[tot].value = "string-" + get_ID(); }
		| INT_NUMBER { $$ = ++tot; treeNode[tot].value = "int-" + get_ID(); }
		| FLOAT_NUMBER { $$ = ++tot; treeNode[tot].value = "float-" + get_ID(); }
		| ID { $$ = ++tot; treeNode[tot].value = "symbol-" + get_ID(); }
		;

%%
#include <map>
#include <sstream>
#include <iostream>
using namespace std;
map<int, int> sig, sigM;
void dfs(int x, int ty){
	cout<<"(";
	if(x > 0){
		int t = G[x].size();
		if(t >= 1) cout<<"(";
		if(G[x].size() == 1) G[x].push_back(-'E');
		for(auto to : G[x]){
			dfs(to, to == G[x][G[x].size()-1]);
		}
		if(t >= 1){
			cout<<"E)";
		}
	}
	if(x < 0) {
		if(x == -'<' - 128) cout<<"<=";
		else if(x == -'>' - 128) cout<<">=";
		else if(x == -'=' - 128) cout<<"==";
		else if(x == -'=' - 256) cout<<"!=";
		else if(x == -',') cout<<"COMMA";
		else cout<<(char)-x;
	} 
	else cout<<treeNode[x].value;
	if(treeNode[x].ntype == NTYPE.EXPR) cout<<"|"<<TYPETABLE[treeNode[x].type];
	cout<<")";
	if(x != root && ty == 0) cout<<",";
	/*cout<<M[x]<<" || ";
	for(auto to : G[x]) if(to > 0) cout<<M[to]<<" "; else cout<<(char)(-to)<<" "; 
	cout<<"Children: ";
	for(auto to : G[x]) if(to > 0) cout<<to<<" "; cout<<endl;*/
}

void dfs_type_error(int x, int type){
	string tree_str = treeNode[x].value;
	if(tree_str == "ID Stmt"){
		for(int i = 0; i < 3; i++){
			string str = treeNode[G[x][0]].value;
			if(str == mtype[i]) type = i+1;
		}
	}
	if(tree_str == "Assign Expr"){
		if(type != 0) Ids_table[ treeNode[G[x][0]].value ].type = type;
		type = 0;
	}
	if(tree_str.find("symbol-") != -1){
		if(type != 0) Ids_table[tree_str].type = type;
		treeNode[x].ntype = NTYPE.EXPR;
		treeNode[x].type = Ids_table[tree_str].type;
	} else
	if(tree_str.find("string-") != -1){
		treeNode[x].ntype = NTYPE.EXPR;
		treeNode[x].type = TYPE.T_STRING;
	} else
	if(tree_str.find("float-") != -1){
		treeNode[x].ntype = NTYPE.EXPR;
		treeNode[x].type = TYPE.T_FLOAT;
	} else
	if(tree_str.find("int-") != -1){
		treeNode[x].ntype = NTYPE.EXPR;
		treeNode[x].type = TYPE.T_INT;
	} else
	if(tree_str.find("Expr") != -1){
		treeNode[x].ntype = NTYPE.EXPR;
	}
	for(auto to : G[x]){
		if(to < 0) continue;
		dfs_type_error(to, type);
	}
	if(treeNode[x].ntype == NTYPE.EXPR){
		for(auto to : G[x]){
			if(treeNode[to].ntype == NTYPE.EXPR){
				if(treeNode[x].type == 0) treeNode[x].type = treeNode[to].type;
				else if(treeNode[x].type != treeNode[to].type) {
					cout<<"Type error : "<<treeNode[x].value<<"("<<TYPETABLE[treeNode[x].type]<<")"<<" is conflict with "<<
					  treeNode[to].value<<"("<<TYPETABLE[treeNode[to].type]<<")"<<endl;
					treeNode[x].type = TYPE.T_ERROR;
				}
			}
		}
	}
}

void generate(string com, string a, int aty, string b, int bty){
	cout<<com <<" "<< (aty ? a : "-" + a + "(%rbp)")<<","<<(bty ? b : "-" + b + "(%rbp)")<<endl;
}
void generate(string com, int a, int aty, int b, int bty){
	generate(com, to_string(a*4), aty, to_string(b*4), bty);
}
void generate(string com, int a, int aty, string b, int bty){
	generate(com, to_string(a*4), aty, b, bty);
}
void generate(string com, string a, int aty, int b, int bty){
	generate(com, a, aty, to_string(b*4), bty);
}
void generate(string com, string a, int aty){
	cout<<com<<" "<<(aty ? a : "-" + a + "(%rbp)")<<endl;
}
void generate(string com, int a, int aty){
	generate(com,  to_string(a*4), aty);
}
void generate(string com){
	cout<<com<<endl;
}


void dfs_ID(int x){
	string tree_str = treeNode[x].value;
	if(tree_str.find("symbol-") != -1){
		Ids_table[tree_str].addr = ++ID_ADDR;
		invIds_table[ID_ADDR] = 1;
		cerr<<tree_str<<" "<<4*ID_ADDR<<endl;
	}
	for(auto to : G[x]){
		if(to < 0) continue;
		dfs_ID(to);
	}
}

void dfs_expr(int x){
	string tree_str = treeNode[x].value;
	int son = -1;
	for(auto to : G[x]){
		if(to < 0) continue;
		dfs_expr(to);
		if(invIds_table.count(treeNode[to].addr) == 0){
			son = to;
		}
	}
	if(son == -1) treeNode[x].addr = ID_ADDR + (++TEMP_ID);
	else treeNode[x].addr = treeNode[son].addr;
	if(tree_str == "Blank Expr"){
		generate("movl", "$1", 1, treeNode[x].addr, 0);
	} else 
	if(tree_str.find("symbol-") != -1){
		--TEMP_ID;
		treeNode[x].addr = Ids_table[tree_str].addr;
	} else
	if(tree_str.find("string-") != -1){
		//treeNode[x].addr = TYPE.T_STRING;
	} else
	if(tree_str.find("float-") != -1){
		//treeNode[x].addr = TYPE.T_FLOAT;
	} else
	if(tree_str.find("int-") != -1){
		--TEMP_ID;
		generate("movl", "$"+tree_str.substr(4, tree_str.length()-4), 1, treeNode[x].addr, 0);
	} else 
	if(G[x].size() >= 2){
		int a = G[x][0], b = G[x][2];
		a = treeNode[a].addr; b = treeNode[b].addr;
		if(tree_str == "Mul Expr"){
			generate("movl", b, 0, "%eax", 1);
			generate("imull", a, 0, "%eax", 1);
			generate("movl", "%eax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Div Expr"){
			generate("movl", a, 0, "%eax", 1);
			generate("idivl", b, 0);
			generate("movl", "%eax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Add Expr"){
			generate("movl", a, 0, "%eax", 1);
			generate("addl", b, 0, "%eax", 1);
			generate("movl", "%eax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Sub Expr"){
			generate("movl", a, 0, "%eax", 1);
			generate("subl", b, 0, "%eax", 1);
			generate("movl", "%eax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Assign Expr"){
			generate("movl", b, 0, "%eax", 1);
			generate("movl", "%eax", 1, a, 0);
			generate("movl", "%eax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Less Expr"){
			generate("movl", a, 0, "%eax", 1);
			generate("movl", b, 0, "%ebx", 1);
			generate("movl", "$1", 1, treeNode[x].addr, 0);			
			generate("cmpl", "%ebx", 1, "%eax", 1);
			generate("jl .L" + to_string(LABEL++));
			generate("movl", "$0", 1, treeNode[x].addr, 0);
			generate(".L" + to_string(LABEL-1) + ":");
		} else if(tree_str == "More Expr"){
			generate("movl", a, 0, "%eax", 1);
			generate("movl", b, 0, "%ebx", 1);
			generate("movl", "$0", 1, treeNode[x].addr, 0);
			generate("cmpl", "%ebx", 1, "%eax", 1);
			generate("jle .L" + to_string(LABEL++));
			generate("movl", "$1", 1, treeNode[x].addr, 0);
			generate(".L" + to_string(LABEL-1) + ":");
		} else if(tree_str == "LessOrEqual Expr"){
			generate("movl", a, 0, "%eax", 1);
			generate("movl", b, 0, "%ebx", 1);
			generate("movl", "$1", 1, treeNode[x].addr, 0);
			generate("cmpl", "%ebx", 1, "%eax", 1);
			generate("jle .L" + to_string(LABEL++));
			generate("movl", "$0", 1, treeNode[x].addr, 0);
			generate(".L" + to_string(LABEL-1) + ":");
		} else if(tree_str == "MoreOrEqual Expr"){
			generate("movl", a, 0, "%eax", 1);
			generate("movl", b, 0, "%ebx", 1);
			generate("movl", "$0", 1, treeNode[x].addr, 0);
			generate("cmpl", "%ebx", 1, "%eax", 1);
			generate("jl .L" + to_string(LABEL++));
			generate("movl", "$1", 1, treeNode[x].addr, 0);
			generate(".L" + to_string(LABEL-1) + ":");
		} else if(tree_str == "Equal Expr"){
			generate("movl", a, 0, "%eax", 1);
			generate("movl", b, 0, "%ebx", 1);
			generate("movl", "$1", 1, treeNode[x].addr, 0);
			generate("cmpl", "%ebx", 1, "%eax", 1);
			generate("je .L" + to_string(LABEL++));
			generate("movl", "$0", 1, treeNode[x].addr, 0);
			generate(".L" + to_string(LABEL-1) + ":");
		} else if(tree_str == "NotEqual Expr"){
			generate("movl", a, 0, "%eax", 1);
			generate("movl", b, 0, "%ebx", 1);
			generate("movl", "$1", 1, treeNode[x].addr, 0);
			generate("cmpl", "%ebx", 1, "%eax", 1);
			generate("jne .L" + to_string(LABEL++));
			generate("movl", "$0", 1, treeNode[x].addr, 0);
			generate(".L" + to_string(LABEL-1) + ":");
		} else {

		}
	} else {
		--TEMP_ID;  treeNode[x].addr = treeNode[G[x][0]].addr;	
	}
}

void dfs_generate(int x){
	string tree_str = treeNode[x].value;
	if(tree_str == "ID Stmt"){
		dfs_ID(x);
	} else 
	if(treeNode[x].ntype == NTYPE.EXPR){
		TEMP_ID = 0; dfs_expr(x);
	} else if(tree_str == "If Stmt"){
		if(G[x].size() == 2){
			TEMP_ID = 0; dfs_expr(G[x][0]);
			treeNode[x].label = LABEL++;
			generate("cmpl", "$0", 1, treeNode[G[x][0]].addr, 0);
			generate("je .L" + to_string(treeNode[x].label));
			dfs_generate(G[x][1]);
			generate(".L" + to_string(treeNode[x].label) + ":");
		} else {
			TEMP_ID = 0; dfs_expr(G[x][0]);
			treeNode[x].label = LABEL; LABEL += 2;
			generate("cmpl",  "$0", 1, treeNode[G[x][0]].addr, 0);
			generate("je .L" + to_string(treeNode[x].label));
			dfs_generate(G[x][1]);
			generate("jmp .L" + to_string(treeNode[x].label + 1));
			generate(".L" + to_string(treeNode[x].label) + ":");
			dfs_generate(G[x][2]);
			generate(".L" + to_string(treeNode[x].label + 1) + ":");
		}
	} else if(tree_str == "For Stmt"){
		dfs_generate(G[x][0]);
		treeNode[x].label = LABEL; LABEL += 2;
		generate(".L" + to_string(treeNode[x].label) + ":");
		dfs_generate(G[x][1]);
		generate("cmpl",  "$0", 1, treeNode[G[G[x][1]][0]].addr, 0);
		generate("je .L" + to_string(treeNode[x].label+1));
		dfs_generate(G[x][3]);
		TEMP_ID = 0; dfs_expr(G[x][2]);
		generate("jmp .L" + to_string(treeNode[x].label));
		generate(".L" + to_string(treeNode[x].label+1) + ":");
	} else if(tree_str == "While Stmt"){
		treeNode[x].label = LABEL; LABEL += 2;
		generate(".L" + to_string(treeNode[x].label) + ":");
		TEMP_ID = 0; dfs_expr(G[x][0]);
		generate("cmpl", "$0", 1, treeNode[G[x][0]].addr, 0);
		generate("je .L" + to_string(treeNode[x].label + 1));
		dfs_generate(G[x][1]);
		generate("jmp .L" + to_string(treeNode[x].label));
		generate(".L" + to_string(treeNode[x].label+1) + ":");
	} else {
		for(auto to : G[x]){
			if(to < 0) continue;
			dfs_generate(to);
		}
	}
}

int main() {
	init_pre_table();
	yyparse();
	dfs_type_error(root, 0);
	//freopen("tree.txt", "w", stdout);
	//dfs(root, 0);
	freopen("asm.txt", "w", stdout);
	dfs_generate(root);
	freopen("/dev/console", "w", stdout);
	cout<<tot<<endl;
	/*for(int i = 1; i <= tot; i++){
		//cout<<i<<endl;
		if(!M.count(i)) cout<<(char)sig[i]<<endl;
		else cout<<M[i]<<endl;
	}*/
}