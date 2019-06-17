package owel; #if macro

import haxe.macro.Context;

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
        var time = Sys.cpuTime();

        var contents = File.getContent(file);
        var currentToken:Token = null;
        var currentValue = "";
        var isIdentifier = false;
        var isStringValue = false;
        var wasStringValueForOption = false;
        var isEscaping = false;
        var isOption = false;
        var isKey = false;
        var spaceExists = false;
        var key = "";
        var value = "";
        var stringCharUsed = -1;
        var skipNext = 0;

        var lastHardChar = "";
        var lastKeyword = "";

        var line = 1;

        inline function checkDefinition(file:String, i:Int)
        {
            if (currentToken.type == TOKEN_STRUCTURE)
            {
                if (currentValue == "")
                {
                    error("`structure` does not have a name.", file, i, i);
                }

                currentToken.identifier = currentValue;
                currentValue = "";
            }
        }

        inline function checkAndCreateOption(file:String, i:Int, isOperator:Bool = false)
        {
            if (isOption)
            {
                if (!isKey && currentValue == "" && !isOperator)
                {
                    error("Key value pairs must be on the same line as each other.", file, i, i);
                }

                if (!wasStringValueForOption)
                {
                    value = currentValue;
                    currentValue = "";
                }

                currentToken.options.set(key, value);
                key = "";
                value = "";
                wasStringValueForOption = false;
                isOption = false;
                isKey = false;
            }
        }

        for (i in 0...contents.length)
        {
            var char = contents.charAt(i);

            if (skipNext > 0)
            {
                skipNext--;
                continue;
            }
    
            if (char == " ") // character is a space
            {
                if (!isStringValue) // character is not wrapped around quotation marks
                {
                    if (isIdentifier) // the last time we parsed, we identified an '@' symbol.
                        isIdentifier = false;
                    else if (isOption && isKey && lastHardChar != ":") // check for spaces in option key context
                        spaceExists = true;
                    else
                    {
                        // `currentValue` is supposedly our keyword if it does not fall under
                        // any other context
                        if (currentValue != "")
                        {
                            var isKeyword = isAKeyword(currentValue);
                            var isPartOfDefine = false;
                            if (currentToken != null)
                                isPartOfDefine = (currentToken.type == TOKEN_DEFINE 
                                    || currentToken.type == TOKEN_STRUCTURE
                                    || currentToken.type == TOKEN_ROUTING);

                            if (!isKeyword && !isOption && !isPartOfDefine)
                            {
                                error('Identifier `$currentValue` is not a valid keyword.', file, i, i);
                            }
                            else if (isKeyword && isOption)
                            {
                                error('You cannot use `$currentValue` as an option key as it is a keyword.', file, i, i);
                            }
                            else
                            {
                                if (currentToken != null)
                                {
                                    if (currentToken.identifier != "" && currentToken.type == TOKEN_STRUCTURE)
                                    {
                                        error('Definition identifiers cannot have spaces.', file, i, i);
                                    }
                                }

                                // unless a string, the last word, i.e. because we are in space context,
                                // is considered a keyword. If the last keyword falls into this scope,
                                // it is the value identifier of a definition (structure, routing, define).
                                // check this and apply accordingly.
                                if (lastKeyword != "")
                                {
                                    checkDefinition(file, i);
                                }

                                if (currentValue == "structure")
                                {
                                    if (currentToken != null)
                                    {
                                        _tokens.push(currentToken);
                                    }

                                    if (lastKeyword != "")
                                    {
                                        error('`$lastKeyword` cannot be used in conjunction with `structure`.', file, i, i);
                                    }

                                    currentToken = new Token();
                                    currentToken.line = line;
                                    currentToken.type = TOKEN_STRUCTURE;
                                    currentToken.fileResource = file;
                                    currentToken.initField();
                                }
                            }
                        }
                    }

                    lastKeyword = currentValue;
                    currentValue = "";
                }
                else
                {
                    if (!isKey)
                        currentValue += char;
                }
            }
            else if (char == ":")
            {
                if (!isStringValue)
                {
                    checkAndCreateOption(file, i, true);

                    isOption = true;
                    isKey = true;
                }
            }
            else if (char == "=")
            {
                if (!isStringValue)
                {
                    if (!isKey)
                    {
                        error("You cannot have more than one equals sign for a key-value pair.", file, i, i);
                    }

                    isKey = false;
                    spaceExists = false;
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
                    error('Escape character used outside of a string.', file, i, i);
                }
            }
            else if (char == "@")
            {
                if (!isStringValue)
                {
                    if (currentToken != null)
                    {
                        checkAndCreateOption(file, i);
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
                        if (isOption)
                        {
                            if (isKey)
                            {
                                error("Key values inside of options cannot be a string.", file, i, i);
                            }
                        }

                        if (charValueTheSame)
                        {
                            if (currentToken.type == TOKEN_FIELD && !isOption) // the string value is probably the display value
                            {
                                currentToken.displayValue = currentValue;
                            }
                            else if (isOption && !isKey)
                            {
                                value = currentValue;
                                wasStringValueForOption = true;
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
                    // we could enter a new line and forget to check the definition.
                    // same as above.
                    if (lastKeyword != "")
                    {
                        checkDefinition(file, i);
                    }
                    checkAndCreateOption(file, i, true);

                    line++;
                    if (char == "\r")
                    {
                        skipNext = 1;
                    }
                }
                else
                {
                    error("String values cannot have new line characters in them. Did you forget quotation marks?", file, i, i);
                }
            }
            else
            {
                if (isIdentifier)
                {
                    currentToken.identifier += char;
                }
                else if (isOption)
                {
                    if (isKey && !spaceExists)
                    {
                        key += char;
                    }
                    else if (isKey && spaceExists)
                    {
                        error('Keys in option context may not have spaces.', file, i - 1, i);
                    }
                    else if (!isKey)
                    {
                        if (wasStringValueForOption)
                        {
                            error("Value of the key-value pair in this option context contains string and non-string values.", file, i, i);
                        }

                        currentValue += char;
                    }
                }
                else
                {
                    currentValue += char;
                }
            }

            if (i == contents.length - 1)
            {
                checkDefinition(file, i);
                checkAndCreateOption(file, i);
                _tokens.push(currentToken);
            }

            if (char != " ")
                lastHardChar = char;
        }

        // for (t in _tokens)
        // {
        //     trace("Identifier: " + t.identifier);
        //     trace("Display Value: " + t.displayValue);
        //     trace("Options: " + t.options);
        // }

        var spent:Float = Sys.cpuTime() - time;
        var milliseconds = spent * 1000;

        print('Time spent on file "$file": $milliseconds ms.');
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

    function print(value:String)
    {
        Sys.print(value + "\r\n");
    }

    function error(value:String, file:String, first:Int, last:Int)
    {
        Context.error(value, Context.makePosition({
            file: file,
            min: first,
            max: last
        }));
    }

}
#end