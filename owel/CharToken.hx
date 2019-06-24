package owel;
#if macro

@:enum abstract CharToken(UInt) from UInt to UInt
{
    var CHAR_TOKEN_IDENTIFIER           =   (1 << 0); // 1
    var CHAR_TOKEN_STRING_VALUE         =   (1 << 1); // 2
    var CHAR_TOKEN_WAS_STRING_OPTION    =   (1 << 2); // 4
    var CHAR_TOKEN_ESCAPING             =   (1 << 3); // 8
    var CHAR_TOKEN_KEY                  =   (1 << 4); // 16
    var CHAR_TOKEN_OPTION               =   (1 << 5); // 32
    var CHAR_TOKEN_KEY_SPACE            =   (1 << 6); // 64
}

#end