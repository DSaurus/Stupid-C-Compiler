bison -vdty grammar.y
flex word.l
g++ -std=c++11 -o res lex.yy.c y.tab.c 
