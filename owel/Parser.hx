package owel; #if macro

import owel.TokenType;
import sys.io.File;

class Parser
{

    private var _keywords:Array<String>;
    private var _tokens:Array<Token>;

    public function new()
    {
        _tokens = [];
        _keywords = [ "define", "routing", "client", "server", "use", "route", "structure" ];
    }

    public function parseFile(file:String)
    {
        var contents = File.getContent(file);
        var currentToken:Token = null;
        var currentValue = "";
        var isIdentifier = false;
        var isStringValue = false;
        var isEscaping = false;
        var stringCharUsed = -1;
        var skipNext = 0;

        var line = 1;

        for (i in 0...contents.length)
        {
            var char = contents.charAt(i);

            if (skipNext > 0)
            {
                skipNext--;
                continue;
            }
    
            if (char == " ")
            {
                if (!isStringValue)
                {
                    if (isIdentifier)
                        isIdentifier = false;
                    else
                    {
                        if (!isAKeyword(currentValue))
                        {
                            throw '$file ($line): Identifier `$currentValue` is not a valid keyword.';
                        }
                    }
                }
                else
                {
                    currentValue += char;
                }
            }
            else if (char == "\\")
            {
                if (isStringValue)
                {
                    isEscaping = true;
                }
                else
                {
                    throw '$file ($line): Escape character used outside of a string.';
                }
            }
            else if (char == "@")
            {
                if (!isStringValue)
                {
                    if (currentToken != null)
                    {
                        _tokens.push(currentToken);
                    }

                    currentToken = new Token();
                    currentToken.type = TOKEN_FIELD;
                    currentToken.line = line;
                    currentToken.fileResource = file;
                    currentToken.initField();
                    isIdentifier = true;
                }
                else
                {
                    currentValue += char;
                }
            }
            else if (char == "\"" || char == "'")
            {
                var charValueTheSame = stringCharUsed == char.charCodeAt(0);
                if (!isEscaping)
                {
                    if (isStringValue)
                    {
                        if (charValueTheSame)
                        {
                            if (currentToken.type == TOKEN_FIELD) // the string value is probably the display value
                            {
                                currentToken.displayValue = currentValue;
                            }

                            currentValue = "";
                            stringCharUsed = -1;
                            isStringValue = false;
                        }
                        else
                            currentValue += char;
                    }
                    else
                    {   
                        stringCharUsed = char.charCodeAt(0);
                        isStringValue = true;
                    }
                }
                else
                {
                    currentValue += char;

                    if (isEscaping)
                        isEscaping = false;
                }
            }
            else if ((char == "\r" && contents.charAt(i + 1) == "\n") || char == "\n")
            {
                if (!isStringValue)
                {
                    line++;
                    if (char == "\r")
                    {
                        skipNext = 1;
                    }
                }
                else
                {
                    throw '$file ($line): String values cannot have new line characters in them. Did you forget quotation marks?';
                }
            }
            else
            {
                if (isIdentifier)
                {
                    currentToken.identifier += char;
                }
                else
                {
                    currentValue += char;
                }
            }

            if (i == contents.length - 1)
            {
                _tokens.push(currentToken);
            }
        }

        for (t in _tokens)
        {
            trace("Identifier: " + t.identifier);
            trace("Display Value: " + t.displayValue);
        }
    }

    function isAKeyword(value:String)
    {
        for (k in _keywords)
        {
            if (k == value)
                return true;
        }
        return false;
    }

}
#end