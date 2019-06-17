package owel; #if macro

enum abstract TokenType(Int) from Int to Int
{
    var TOKEN_FIELD         =   0;
    var TOKEN_ROUTE         =   1;
    var TOKEN_DEFINE        =   2;
    var TOKEN_STRUCTURE     =   3;
    var TOKEN_ROUTING       =   4;
}
#end