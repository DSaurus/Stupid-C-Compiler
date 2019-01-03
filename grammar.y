%{
#include <stdio.h>
#include <iostream>
#include <sstream>
#include <map>
#include <vector>
#define YYSTYPE int
using namespace std;
string get_ID();
const int maxtot = (1<<15);
vector<int> G[maxtot];
int pa[maxtot];
int tot = 0, root, mtot = 0;

// struct TYPET{
// 	const static int T_UNDEFINED = 0;
// 	const static int T_INT = 1;
// 	const static int T_STRING = 2;
// 	const static int T_FLOAT = 3;
// 	const static int T_ERROR = 4;
// }TYPE;

struct NTYPET{
	const static int STMT = 0;
	const static int EXPR = 1;
}NTYPE;

// const string TYPETABLE[7] = {"UNDEFINED", "INT", "STRING", "FLOAT", "ERROR"};
// const string mtype[3] = {"Type Int", "Type String", "Type Float"};

struct TreeNode{
	int ntype;
	string type;
	string value;
	int addr;
	int label;
	TreeNode() { type = "Type Undefined"; ntype = 0; }
}treeNode[maxtot];

struct Ids{
	string type;
	int addr;
};

struct Types{
	string type;
	int sz;
	map<string, Ids> Ids_table;
};
map<string, Types> Types_table;
map<string, Ids> Ids_table;
map<int, int> invIds_table;
int ID_ADDR = 0, LABEL = 0, TEMP_ID = 0, MAX_ID = 0, IS_MAIN;

stringstream ssout("");

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

%token STRUCT PT
%token ADD SUB MUL DIV
%token SL SR BL BR ML MR
%token ADDRESS AT
%token ID
%token TSTRING FLOAT INT
%token STRING FLOAT_NUMBER INT_NUMBER
%token IF ELSE FOR WHILE
%token SEMI COMMA
%token ASSIGN
%token EQUAL NOTEQUAL LESS LESSORE MORE MOREORE
%token RETURN 
%token AND OR NOT 
%%

main : main func { $$ = $1; add_edge($$, $2, 0); }
	 | main struct_declare { $$ = $1; add_edge($$, $2, 0); }
	 | func { $$ = ++tot; treeNode[tot].value = "Main"; root = tot; add_edge($$, $1, 0); }
	 | struct_declare { $$ = ++tot; treeNode[tot].value = "Main"; root = tot; add_edge($$, $1, 0); }
	 ;

struct_declare : struct_type cp_stmt { $$ = ++tot; treeNode[tot].value = "Struct Declare"; add_edge($$, {$1, $2}); }
			   ;

struct_type : STRUCT ID { $$ = ++tot; treeNode[tot].value = "Type Struct " + get_ID(); }
		    ;

base_type : INT   { $$ = ++tot; treeNode[tot].value = "Type Int"; }
	 | base_type MUL { cerr<<"??"<<endl; $$ = ++tot; treeNode[tot].value = "Type@ Int"; }
	 | struct_type { $$ = ++tot; treeNode[tot].value = treeNode[$1].value; }
	 ;

type : base_type 	{ $$ = ++tot; treeNode[tot].value = treeNode[$1].value; add_edge($$, $1, 0); }
	 | type ML INT_NUMBER MR { $$ = ++tot; treeNode[tot].value = treeNode[$1].value + " |" + get_ID(); add_edge($$, $1, 0); }
	 ;

func : type ID SL var_list SR cp_stmt  {
			$$ = ++tot; treeNode[tot].value = "Function";
			
			$2 = ++tot; treeNode[tot].value = "symbol-" + get_ID();
			add_edge($$, {$1, $2, $4, $6});
		}
	 | ID SL var_list SR cp_stmt {  
		 	$$ = ++tot; treeNode[tot].value = "Function";
			$1 = ++tot; treeNode[tot].value = "symbol-" + get_ID();
			add_edge($$, {-1, $1, $3, $5}); 
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
	 | return_stmt { $$ = ++tot; treeNode[tot].value = "Stmt"; add_edge($$, $1, 0); }
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

func_call_stmt : func_expr SEMI { $$ = ++tot; treeNode[tot].value = "Func Call Stmt"; add_edge($$, $1, 0); }
			   ;

return_stmt : RETURN expr SEMI { $$ = ++tot; treeNode[tot].value = "Return Stmt"; add_edge($$, $2, 0); }

expr_list : expr { $$ = ++tot; treeNode[tot].value = "E List"; add_edge($$, $1, 0); }
	      | expr_list COMMA expr { $$ = ++tot; treeNode[tot].value = "E List"; add_edge($$, {$1, $3}); }
	      ;

expr : con_expr { $$ = ++tot; treeNode[tot].value = "Expr"; add_edge($$, $1, 0); }
	 | assign_expr { $$ = ++tot; treeNode[tot].value = "Expr"; add_edge($$, $1, 0); }
	 | func_expr { $$ = ++tot; treeNode[tot].value = "Expr"; add_edge($$, $1, 0); }
	 | 		{ $$ = ++tot; treeNode[tot].value = "Blank Expr"; }
	 ;



func_expr : ID SL SR { $$ = ++tot; treeNode[tot].value = "Func Call Expr"; $1 = ++tot; treeNode[tot].value = "symbol-" + get_ID(); add_edge($$, {$1, -'(', -')'}); }
		  | ID SL expr_list SR { $$ = ++tot; treeNode[tot].value = "Func Call Expr"; $1 = ++tot; treeNode[tot].value = "symbol-" + get_ID(); add_edge($$, {$1, $3}); }
		  ;

con_expr  : rela_expr { $$ = ++tot; treeNode[tot].value = "Con Expr"; add_edge($$, $1, 0); }
		  | con_expr AND rela_expr { $$ = ++tot; treeNode[tot].value = "And Expr"; add_edge($$, {$1, -'&', $3}); }
		  | con_expr OR  rela_expr { $$ = ++tot; treeNode[tot].value = "Or Expr"; add_edge($$, {$1, -'|', $3}); }
		  | NOT con_expr { $$ = ++tot; treeNode[tot].value = "Not Expr"; add_edge($$, {-'!', $2}); }
		  ;

rela_expr : rela_expr LESS add_expr { $$ = ++tot; treeNode[tot].value = "Less Expr"; add_edge($$, {$1, -'<', $3}); }
		  | rela_expr MORE add_expr { $$ = ++tot; treeNode[tot].value = "More Expr"; add_edge($$, {$1, -'>', $3}); }
		  | rela_expr LESSORE add_expr { $$ = ++tot; treeNode[tot].value = "LessOrEqual Expr"; add_edge($$, {$1, -'<'-128, $3}); }
		  | rela_expr MOREORE add_expr { $$ = ++tot; treeNode[tot].value = "MoreOrEqual Expr"; add_edge($$, {$1, -'>'-128, $3}); }
		  | rela_expr EQUAL add_expr { $$ = ++tot; treeNode[tot].value = "Equal Expr"; add_edge($$, {$1, -'='-128, $3}); }
		  | rela_expr NOTEQUAL add_expr {$$ = ++tot; treeNode[tot].value = "NotEqual Expr"; add_edge($$, {$1, -'='-256, $3}); }
		  | add_expr {$$ = ++tot; treeNode[tot].value = "Rela Expr"; add_edge($$, $1, 0); }
		  ;

assign_expr : ID_ap ASSIGN expr { $$ = ++tot; treeNode[tot].value = "Assign Expr"; add_edge($$, {$1, -'=', $3}); }
		    | pt_expr ASSIGN expr { $$ = ++tot; treeNode[tot].value = "Assign Expr"; add_edge($$, {$1, -'=', $3}); }
		    ;

add_expr : add_expr ADD mul_expr { $$ = ++tot; treeNode[tot].value = "Add Expr";  add_edge($$, {$1, -'+', $3}); }
		 | add_expr SUB mul_expr { $$ = ++tot; treeNode[tot].value = "Sub Expr"; add_edge($$, {$1, -'-', $3}); }
		 | mul_expr { $$ = ++tot; treeNode[tot].value = "Add Expr"; add_edge($$, $1, 0); }
		 ;

mul_expr : mul_expr MUL pt_expr { $$ = ++tot; treeNode[tot].value = "Mul Expr"; add_edge($$, {$1, -'*', $3}); }
		 | mul_expr DIV pt_expr { $$ = ++tot; treeNode[tot].value = "Div Expr"; add_edge($$, {$1, -'/', $3}); }
		 | pt_expr {$$ = ++tot; treeNode[tot].value = "Mul Expr"; add_edge($$, $1, 0); }
		 ;

pt_expr : pt_expr PT ID_ap { $$ = ++tot; treeNode[tot].value = "Pt Expr"; add_edge($$, {$1, $3}); } 
		| addr_expr { $$ = ++tot; treeNode[tot].value = "Pt Expr"; add_edge($$, $1, 0); }
		;

addr_expr : ADDRESS at_expr  { $$ = ++tot; treeNode[tot].value = "Addr Expr"; add_edge($$, {-'$', $2}); }
	      | at_expr  { $$ = ++tot; treeNode[tot].value = "Addr Expr"; add_edge($$, $1, 0); }

at_expr : MUL id_expr { $$ = ++tot; treeNode[tot].value = "At Expr"; add_edge($$, {-'@', $2}); }
	    | id_expr { $$ = ++tot; treeNode[tot].value = "At Expr"; add_edge($$, $1, 0);}
		;

id_expr : STRING { $$ = ++tot; treeNode[tot].value = "string-" + get_ID(); }
		| INT_NUMBER { $$ = ++tot; treeNode[tot].value = "int-" + get_ID(); }
		| FLOAT_NUMBER { $$ = ++tot; treeNode[tot].value = "float-" + get_ID(); }
		| ID_ap { $$ = ++tot; treeNode[tot].value = "ID Expr"; add_edge($$, $1, 0); }
		| SL expr SR { $$ = ++tot; treeNode[tot].value = "ID Expr"; add_edge($$, $2, 0); }
		;

ID_ap    : ID_ap ML expr MR { $$ = ++tot; treeNode[tot].value = "Array Expr"; add_edge($$, {$1, $3}); }
	     | ID { $$ = ++tot; treeNode[tot].value = "symbol-" + get_ID(); }
		 ;		

%%
#include <map>
#include <sstream>
#include <iostream>
using namespace std;
map<int, int> sig, sigM;

void dfs_expr(int x);	
void dfs_ID(int x);

void dfs(int x, int ty){
	cout<<"(";
	if(x > 0){
		int t = G[x].size();
		if(t >= 1) cout<<"(";
		if(G[x].size() == 1) G[x].push_back(-'E');
		for(auto to : G[x]){
			pa[to] = x;
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
	if(treeNode[x].ntype == NTYPE.EXPR) cout<<"|"<<treeNode[x].type;
	cout<<")";
	if(x != root && ty == 0) cout<<",";
	/*cout<<M[x]<<" || ";
	for(auto to : G[x]) if(to > 0) cout<<M[to]<<" "; else cout<<(char)(-to)<<" "; 
	cout<<"Children: ";
	for(auto to : G[x]) if(to > 0) cout<<to<<" "; cout<<endl;*/
}


namespace Generate{
	void generate(string com, string a, int aty, string b, int bty){
		ssout<<com <<" "<< (aty ? a : "-" + a + "(%rbp)")<<","<<(bty ? b : "-" + b + "(%rbp)")<<endl;
	}
	void generate(string com, int a, int aty, int b, int bty){
		string ta, tb;
		if(a < 0) { ssout<<"movq "<<a*8<<"(%rbp),"<<"%rcx"; ta = "(%rcx)"; aty = 1; } else ta = to_string(a*8);
		if(b < 0) { ssout<<"movq "<<b*8<<"(%rbp),"<<"%rdx"; tb = "(%rdx)"; bty = 1; } else tb = to_string(b*8);
		generate(com, ta, aty, tb, bty);
	}
	void generate(string com, int a, int aty, string b, int bty){
		if(a < 0){
			ssout<<"movq "<<a*8<<"(%rbp),"<<"%rcx"<<endl;
			generate(com,  "(%rcx)", 1, b, bty);
		} else 
		generate(com, to_string(a*8), aty, b, bty);
	}
	void generate(string com, string a, int aty, int b, int bty){
		if(b < 0){
			ssout<<"movq "<<b*8<<"(%rbp),"<<"%rdx"<<endl;
			generate(com,  a, aty, "(%rdx)", 1);
		} else 
		generate(com, a, aty, to_string(b*8), bty);
	}
	void generate(string com, string a, int aty){
		ssout<<com<<" "<<(aty ? a : "-" + a + "(%rbp)")<<endl;
	}
	void generate(string com, int a, int aty){
		if(a < 0) {
			ssout<<"movq "<<a*8<<"(%rbp),"<<"%rcx"<<endl;
			generate(com,  "(%rcx)", 1);
		} else 
		generate(com,  to_string(a*8), aty);
	}
	void generate(string com){
		ssout<<com<<endl;
	}
};
using namespace Generate;



namespace Struct{
	void dfs_pt_get(int x, vector<int> &res){
		string tree_str = treeNode[x].value;
		cerr<<x<<" "<<treeNode[x].value<<" "<<G[x].size()<<endl;
		if(tree_str == "Pt Expr"){
			for(auto to : G[x]) dfs_pt_get(to, res);
		} else if(tree_str == "Array Expr"){
			dfs_pt_get(G[x][0], res);
		} else {
			for(auto to : G[x]){
				if(to < 0) continue;
				dfs_pt_get(to, res);
			}
		}
		if(tree_str.find("symbol-") != -1) res.push_back(x);
	}
	void pre_pt_expr(int x){
		vector<int> res;
		dfs_pt_get(x, res);
		int a = res[0];
		cerr<<"wtf "<<a<<endl;
		string type = Ids_table[treeNode[a].value].type;
		cerr<<type<<endl;
		for(int i = 1; i < res.size(); i++){
			int y = res[i];
			auto table = Types_table[type].Ids_table;
			type = table[treeNode[y].value].type;
			cerr<<type<<" "<<treeNode[y].value<<endl;
			treeNode[y].value = "int-" + to_string(table[treeNode[y].value].addr*8);
		}
		cerr<<"---"<<endl;
	}
	int calc_size(string type){
		int sz = 0, k = 1;
		stringstream ss(type), ss2(""); string temp;
		ss>>temp; ss2<<temp; ss>>temp; ss2<<" "<<temp; ss>>temp; ss2<<" "<<temp; type = ss2.str();
		for(auto &_ : Types_table[type].Ids_table){
			auto &x = _.second;
			string t = x.type;
			x.addr = sz;
			k = 1;
			if(t.find("@") != -1){
				sz++;
				x.addr = sz;
				continue;
			}
			if(t.find("Struct") != -1){
				k = calc_size(t);
			}
			if(t.find("|") != -1){
				stringstream ss(t);
				string temp;
				for(ss>>temp; temp.find("|") == -1; ss>>temp);
				k *= atoi(temp.substr(1, temp.length()-1).c_str());
				while(ss>>temp) k *= atoi(temp.substr(1, temp.length()-1).c_str());
			}
			sz += k;
		}
		return sz;
	}
	void dfs_struct_id(int x, string type){
		string tree_str = treeNode[x].value;
		auto &T = Types_table[type].Ids_table;
		if(tree_str.find("symbol-") != -1){
			T[tree_str].type = treeNode[x].type;
		}
		for(auto to : G[x]){
			if(to < 0) continue;
			dfs_struct_id(to, type);
		}
	}
	void dfs_struct_declare(int x, string type){
		cerr<<"declare "<<type<<endl;
		if(Types_table.count(type) == 0) Types_table[type].type = type;
		string tree_str = treeNode[x].value;
		if(tree_str == "ID Stmt"){
			dfs_struct_id(x, type);
		} else 
		for(auto to : G[x]){
			if(to < 0) continue;
			dfs_struct_declare(to, type);
		}
	}
}

namespace Array_Pointer{
	void declare(string type, int addr){
		stringstream ss(type);
		string temp; ss>>temp; ss>>temp;
		int space = 1;
		if(type.find("Struct") != -1){
			ss>>temp;
			space = Struct::calc_size(type);
		}
		while(ss>>temp){
			int x = atoi(temp.substr(1, temp.length()-1).c_str());
			space *= x;
		}
		for(int i = 1; i <= space; i++) invIds_table[++ID_ADDR] = 1;
		generate("leaq", ID_ADDR, 0, "%rax", 1);
		generate("movq", "%rax", 1, addr, 0);
	}
	string type_derive(string type){
		stringstream ss(type), ss2("");
		string temp; ss>>temp; ss2<<temp; ss>>temp; ss2<<" "<<temp;
		ss>>temp; 
		while(ss>>temp) ss2<<" "<<temp;
		return ss2.str();
	}
	void derive(string type, int base, int offset, int out){
		stringstream ss(type);
		string temp; ss>>temp; ss>>temp;
		int space = 1, x = -1;
		cerr<<type<<endl;
		while(ss>>temp){
			x = atoi(temp.substr(1, temp.length()-1).c_str());
			space *= x;
		}
		generate("movq", offset, 0, "%rax", 1);
		generate("imulq", "$" + to_string(space*8), 1, "%rax", 1);
		generate("movq", base, 0, "%rbx", 1);
		generate("addq", "%rax", 1, "%rbx", 1);
		generate("movq", "%rbx", 1, out, 0);
	}
};

void dfs_type_error(int x, string type){
	string tree_str = treeNode[x].value;
	if(tree_str == "Var List"){
		if(G[x].size() == 3){
			type = treeNode[G[x][1]].value;
		} else type = treeNode[G[x][0]].value;
	}
	if(tree_str == "ID Stmt"){
		type = treeNode[G[x][0]].value;
		cerr<<type<<endl;
	}
	if(tree_str == "Function" && G[x][0] != -1){
		Ids_table[treeNode[G[x][1]].value].type = treeNode[G[x][0]].value;
	}
	if(tree_str == "Assign Expr"){
		if(type != "Type Undefined") Ids_table[ treeNode[G[x][0]].value ].type = type;
		type = "Type Undefined";
	}
	if(tree_str.find("symbol-") != -1){
		if(type != "Type Undefined") Ids_table[tree_str].type = type;
		treeNode[x].ntype = NTYPE.EXPR;
		treeNode[x].type = Ids_table[tree_str].type;
		cerr<<"typeS "<<tree_str<<" "<<Ids_table[tree_str].type<<endl;
	} else
	if(tree_str.find("int-") != -1){
		treeNode[x].ntype = NTYPE.EXPR;
		treeNode[x].type = "Type Int";
	} else
	if(tree_str.find("Expr") != -1){
		treeNode[x].ntype = NTYPE.EXPR;
	}
	for(auto to : G[x]){
		if(to < 0) continue;
		pa[to] = x;
		dfs_type_error(to, type);
	}
	if(treeNode[x].ntype == NTYPE.EXPR){
		for(auto to : G[x]){
			if(to < 0) continue;
			if(treeNode[to].type.find("Struct") != -1) treeNode[to].type = "Type Int";
			if(treeNode[x].value == "Array Expr"){
				if(G[x].size() == 1){
					treeNode[x].type = treeNode[to].type;
					break;
				} else {
					treeNode[x].type = Array_Pointer::type_derive(treeNode[G[x][0]].type);
					break;
				}
			} else 
			if(treeNode[to].ntype == NTYPE.EXPR){
				if(treeNode[x].type == "Type Undefined") treeNode[x].type = treeNode[to].type;
				else if(treeNode[x].type.find("@") != -1) continue;
				else if(treeNode[x].type != treeNode[to].type) {
					if(treeNode[to].type.find("@") != -1){
						treeNode[x].type = treeNode[to].type;
						continue;
					}
					cout<<"Type error : "<<treeNode[x].value<<"("<<treeNode[x].type<<")"<<" is conflict with "<<
					  treeNode[to].value<<"("<<treeNode[to].type<<")"<<endl;
					treeNode[x].type = "Type Error";
				}
			}
		}
	}
}

string get_func_name(int x){
	string func_name = treeNode[x].value.substr(7, treeNode[x].value.length() - 7);
	if(func_name != "main") func_name = "_L" + func_name;
	return func_name;
}


void dfs_ID(int x){
	string tree_str = treeNode[x].value;
	if(tree_str.find("symbol-") != -1){
		Ids_table[tree_str].addr = ++ID_ADDR;
		invIds_table[ID_ADDR] = 1;
		if(Ids_table[tree_str].type.find("|") != -1){
			Array_Pointer::declare(Ids_table[tree_str].type, ID_ADDR);
		} else if(Ids_table[tree_str].type.find("@") == -1 && Ids_table[tree_str].type.find("Struct") != -1){
			Array_Pointer::declare(Ids_table[tree_str].type, ID_ADDR);
		}
		cerr<<tree_str<<" "<<8*ID_ADDR<<" "<<Ids_table[tree_str].type<<endl;
	}
	for(auto to : G[x]){
		if(to < 0) continue;
		dfs_ID(to);
	}
}

void dfs_push(int x){
	string tree_str = treeNode[x].value;
	if(tree_str == "Expr"){
		generate("pushq", treeNode[x].addr, 0);
		return;
	}
	for(auto to : G[x]){
		if(to < 0) continue;
		dfs_push(to);
	}
}

int dfs_get_func_vb(int x){
	string tree_str = treeNode[x].value;
	if(tree_str == "Expr") {
		return treeNode[x].addr;
	}
	for(auto to : G[x]){
		if(to < 0) continue;
		int temp = dfs_get_func_vb(to);
		if(temp != 0) return temp;
	}
	return 0;
}

void dfs_expr(int x){
	string tree_str = treeNode[x].value;
	int son = -1;
	if(tree_str == "Pt Expr" && G[x].size() >= 2 && treeNode[pa[x]].value != "Pt Expr"){
		cerr<<"Start"<<endl;
		Struct::pre_pt_expr(x);
		cerr<<"End"<<endl;
	}
	cerr<<x<<" "<<treeNode[x].value<<endl;
	for(auto to : G[x]){
		if(to < 0) continue;
		dfs_expr(to);
		if(invIds_table.count(treeNode[to].addr) == 0 && treeNode[to].addr > 0){
			son = to;
		}
	}
	if(son == -1) { treeNode[x].addr = ID_ADDR + (++TEMP_ID); MAX_ID = max(MAX_ID, treeNode[x].addr); }
	else treeNode[x].addr = treeNode[son].addr;
	if(tree_str == "Blank Expr"){
		generate("movq", "$1", 1, treeNode[x].addr, 0);
	} else 
	if(tree_str.find("symbol-") != -1){
		--TEMP_ID;
		treeNode[x].addr = Ids_table[tree_str].addr;
	} else
	if(tree_str.find("strsym-") != -1){
		generate("movq", "$"+tree_str.substr(7, tree_str.length()-7), 1, treeNode[x].addr, 0);
	} else
	if(tree_str.find("float-") != -1){
		//treeNode[x].addr = TYPE.T_FLOAT;
	} else
	if(tree_str.find("int-") != -1){
		generate("movq", "$"+tree_str.substr(4, tree_str.length()-4), 1, treeNode[x].addr, 0);
	} else 
	if(G[x].size() >= 2){
		int a = G[x][0], b = G[x][2];
		a = treeNode[a].addr; b = treeNode[b].addr;
		if(tree_str == "Mul Expr"){
			generate("movq", b, 0, "%rax", 1);
			generate("imulq", a, 0, "%rax", 1);
			generate("movq", "%rax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Div Expr"){
			generate("movq", a, 0, "%rax", 1);
			generate("idivq", b, 0);
			generate("movq", "%rax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Add Expr"){
			generate("movq", a, 0, "%rax", 1);
			generate("addq", b, 0, "%rax", 1);
			generate("movq", "%rax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Sub Expr"){
			generate("movq", a, 0, "%rax", 1);
			generate("subq", b, 0, "%rax", 1);
			generate("movq", "%rax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Assign Expr"){
			generate("movq", b, 0, "%rax", 1);
			generate("movq", "%rax", 1, a, 0);
			generate("movq", "%rax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Less Expr"){
			generate("movq", a, 0, "%rax", 1);
			generate("movq", b, 0, "%rbx", 1);
			generate("movq", "$1", 1, treeNode[x].addr, 0);			
			generate("cmpq", "%rbx", 1, "%rax", 1);
			generate("jl .L" + to_string(LABEL++));
			generate("movq", "$0", 1, treeNode[x].addr, 0);
			generate(".L" + to_string(LABEL-1) + ":");
		} else if(tree_str == "More Expr"){
			generate("movq", a, 0, "%rax", 1);
			generate("movq", b, 0, "%rbx", 1);
			generate("movq", "$0", 1, treeNode[x].addr, 0);
			generate("cmpq", "%rbx", 1, "%rax", 1);
			generate("jle .L" + to_string(LABEL++));
			generate("movq", "$1", 1, treeNode[x].addr, 0);
			generate(".L" + to_string(LABEL-1) + ":");
		} else if(tree_str == "LessOrEqual Expr"){
			generate("movq", a, 0, "%rax", 1);
			generate("movq", b, 0, "%rbx", 1);
			generate("movq", "$1", 1, treeNode[x].addr, 0);
			generate("cmpq", "%rbx", 1, "%rax", 1);
			generate("jle .L" + to_string(LABEL++));
			generate("movq", "$0", 1, treeNode[x].addr, 0);
			generate(".L" + to_string(LABEL-1) + ":");
		} else if(tree_str == "MoreOrEqual Expr"){
			generate("movq", a, 0, "%eax", 1);
			generate("movq", b, 0, "%ebx", 1);
			generate("movq", "$0", 1, treeNode[x].addr, 0);
			generate("cmpq", "%rbx", 1, "%rax", 1);
			generate("jl .L" + to_string(LABEL++));
			generate("movq", "$1", 1, treeNode[x].addr, 0);
			generate(".L" + to_string(LABEL-1) + ":");
		} else if(tree_str == "Equal Expr"){
			generate("movq", a, 0, "%rax", 1);
			generate("movq", b, 0, "%rbx", 1);
			generate("movq", "$1", 1, treeNode[x].addr, 0);
			generate("cmpq", "%rbx", 1, "%rax", 1);
			generate("je .L" + to_string(LABEL++));
			generate("movq", "$0", 1, treeNode[x].addr, 0);
			generate(".L" + to_string(LABEL-1) + ":");
		} else if(tree_str == "NotEqual Expr"){
			generate("movq", a, 0, "%eax", 1);
			generate("movq", b, 0, "%ebx", 1);
			generate("movq", "$1", 1, treeNode[x].addr, 0);
			generate("cmpq", "%ebx", 1, "%eax", 1);
			generate("jne .L" + to_string(LABEL++));
			generate("movq", "$0", 1, treeNode[x].addr, 0);
			generate(".L" + to_string(LABEL-1) + ":");
		} else if(tree_str == "Func Call Expr"){
			if(get_func_name(G[x][0]) == "_Lread"){
				int addr = dfs_get_func_vb(G[x][1]);
				generate("leaq", addr, 0, "%rax", 1);
				generate("movq", "%rax", 1, "%rsi", 1);
				generate("movq", "$.input_string", 1, "%rdi", 1);
				generate("movq", "$0", 1, "%rax", 1);
				generate("call scanf");
			} else if(get_func_name(G[x][0]) == "_Lwrite"){
				int addr = dfs_get_func_vb(G[x][1]);
				generate("movq", addr, 0, "%rax", 1);
				generate("movq", "%rax", 1, "%rsi", 1);
				generate("movq", "$.output_string", 1, "%rdi", 1);
				generate("movq", "$0", 1, "%rax", 1);
				generate("call printf");
			} else if(G[x].size() == 3){
				generate("call " + get_func_name(G[x][0]));
				generate("movq", "%rax", 1, treeNode[x].addr, 0);
			} else if(G[x].size() == 2){
				dfs_push(G[x][1]);
				generate("call " + get_func_name(G[x][0]));
				generate("movq", "%rax", 1, treeNode[x].addr, 0);
			}
		} else if(tree_str == "Array Expr"){
			Array_Pointer::derive(treeNode[x].type, treeNode[G[x][0]].addr, treeNode[G[x][1]].addr, treeNode[x].addr);
			if(treeNode[pa[x]].value != "Array Expr") treeNode[x].addr = -treeNode[x].addr;
			cerr<<treeNode[pa[x]].value<<endl;
		} else if(tree_str == "At Expr"){
			generate("movq", treeNode[G[x][1]].addr, 0, "%rax", 1);
			generate("movq", "%rax", 1, treeNode[x].addr, 0);
			treeNode[x].addr = -treeNode[x].addr;
		} else if(tree_str == "Addr Expr"){
			generate("leaq", treeNode[G[x][1]].addr, 0, "%rax", 1);
			generate("movq", "%rax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Pt Expr"){
			generate("movq", abs(treeNode[G[x][0]].addr), 0, "%rax", 1);
			generate("addq", abs(treeNode[G[x][1]].addr), 0, "%rax", 1);
			generate("movq", "%rax", 1, treeNode[x].addr, 0);
			if(treeNode[pa[x]].value != "Pt Expr") treeNode[x].addr = -treeNode[x].addr;
		} else if(tree_str == "And Expr"){
			generate("movq", "$0", 1, "%rax", 1);
			generate("cmpq", "$0", 1, a, 0);
			generate("sete", "%al", 1);
			generate("cmpq", "$0", 1, b, 0);
			generate("sete", "%al", 1);
			generate("cmpb", "$0", 1, "%al", 1);
			generate("sete", "%al", 1);
			generate("movq", "%rax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Or Expr"){
			generate("movq", "$0", 1, "%rax", 1);
			generate("cmpq", "$0", 1, a, 0);
			generate("setne", "%al", 1);
			generate("cmpq", "$0", 1, b, 0);
			generate("setne", "%al", 1);
			generate("movq", "%rax", 1, treeNode[x].addr, 0);
		} else if(tree_str == "Not Expr"){
			generate("movq", "$0", 1, "%rax", 1);
			generate("cmpq", "$0", 1, treeNode[G[x][1]].addr, 0);
			generate("sete", "%al", 1);
			generate("movq", "%rax", 1, treeNode[x].addr, 0);
		}
	} else {
		if(son == -1) --TEMP_ID;  treeNode[x].addr = treeNode[G[x][0]].addr;	
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
			generate("cmpq", "$0", 1, treeNode[G[x][0]].addr, 0);
			generate("je .L" + to_string(treeNode[x].label));
			dfs_generate(G[x][1]);
			generate(".L" + to_string(treeNode[x].label) + ":");
		} else {
			TEMP_ID = 0; dfs_expr(G[x][0]);
			treeNode[x].label = LABEL; LABEL += 2;
			generate("cmpq",  "$0", 1, treeNode[G[x][0]].addr, 0);
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
		generate("cmpq",  "$0", 1, treeNode[G[G[x][1]][0]].addr, 0);
		generate("je .L" + to_string(treeNode[x].label+1));
		dfs_generate(G[x][3]);
		TEMP_ID = 0; dfs_expr(G[x][2]);
		generate("jmp .L" + to_string(treeNode[x].label));
		generate(".L" + to_string(treeNode[x].label+1) + ":");
	} else if(tree_str == "While Stmt"){
		treeNode[x].label = LABEL; LABEL += 2;
		generate(".L" + to_string(treeNode[x].label) + ":");
		TEMP_ID = 0; dfs_expr(G[x][0]);
		generate("cmpq", "$0", 1, treeNode[G[x][0]].addr, 0);
		generate("je .L" + to_string(treeNode[x].label + 1));
		dfs_generate(G[x][1]);
		generate("jmp .L" + to_string(treeNode[x].label));
		generate(".L" + to_string(treeNode[x].label+1) + ":");
	} else if(tree_str == "Return Stmt") {
		TEMP_ID = 0; dfs_expr(G[x][0]);
		generate("addq $@MAX_ID, %rsp");
		generate("movq", treeNode[G[x][0]].addr, 0, "%rax", 1);
		if(IS_MAIN){
			generate("leave");
		} else generate("popq %rbp");
		generate("ret");
	} else {
		for(auto to : G[x]){
			if(to < 0) continue;
			dfs_generate(to);
		}
	}
}

void variable_init(int n){
	for(int i = 1; i <= n; i++){
		generate("movq " + to_string((i+1)*8) + "(%rbp), %rax");
		generate("movq %rax, -" + to_string((n-i+1)*8) + "(%rbp)");
	}
}

void dfs_function(int x){
	string tree_str = treeNode[x].value;
	if(tree_str == "Function"){
		dfs_type_error(x, "Type Undefined");
		string func_name = get_func_name(G[x][1]); 
		generate(".text");
		generate(".globl " + func_name);
		generate(".type " + func_name + ", @function");
		generate(func_name + ":");
		generate("pushq %rbp");
		generate("movq %rsp, %rbp");
		cout<<ssout.str(); ssout.str("");
		MAX_ID = ID_ADDR = 0; invIds_table.clear();
		IS_MAIN = func_name == "main";
		dfs_ID(G[x][2]);
		variable_init(ID_ADDR);
		dfs_generate(G[x][3]);	
		cout<<"subq $" + to_string(MAX_ID*8 + 8) + ", %rsp"<<endl;
		string outStr = ssout.str();
		while(outStr.find("@MAX_ID") != -1) outStr.replace(outStr.find("@MAX_ID"), 7, to_string(MAX_ID*8 + 8));
		cout<<outStr; ssout.str("");
		
	} else if(tree_str == "Struct Declare"){
		dfs_type_error(x, "Type Undefined");
		Struct::dfs_struct_declare(G[x][1], treeNode[G[x][0]].value);
	} else {
		for(auto to : G[x]){
			if(to < 0) continue;
			dfs_function(to);
		}
	}
}

void data_generate(){
	generate(".section .rodata");
	generate(".input_string:");
	generate(".string \"%lld\"");
	generate(".output_string:");
	generate(".string \"%lld\\n\"");
}

int main() {
	init_pre_table();
	yyparse();
	cerr<<"parse finished"<<endl;
	//freopen("tree.txt", "w", stdout);
	//dfs(root, 0);
	freopen("test.s", "w", stdout);
	data_generate();
	dfs_function(root);
	freopen("/dev/console", "w", stdout);
	cout<<tot<<endl;
	/*for(int i = 1; i <= tot; i++){
		//cout<<i<<endl;
		if(!M.count(i)) cout<<(char)sig[i]<<endl;
		else cout<<M[i]<<endl;
	}*/
}