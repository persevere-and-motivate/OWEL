package owel; #if macro

import haxe.macro.Expr;
import haxe.macro.Context;

import owel.OwelOptions.OptionGet;
import owel.TokenType;
import sys.io.File;

using StringTools;

class Parser
{

    private var options:OwelOptions;

    private var _keywords:Array<String>;
    private var _tokens:Array<Token>;

    public function new(options:OwelOptions)
    {
        _tokens = [];
        _keywords = [ "define", "routing", "client", "server", "use", "route", "structure" ];

        this.options = options;
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
                    {
                        if (lastHardChar == "@")
                            error("Field Identifier has not been given a name.", file, i, i);
                        
                        isIdentifier = false;
                    }
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
                                    || currentToken.type == TOKEN_STRUCTURE);

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
                        if (currentToken.displayValue == "" && currentToken.type == TOKEN_FIELD)
                            error("The last field you input does not have a display value.", file, i, i);
                        
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

        var spent:Float = Sys.cpuTime() - time;
        var milliseconds = spent * 1000;

        //print('Time spent on file "$file": $milliseconds ms.');
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

    public function executeTypes()
    {
        if (_tokens.length > 0)
        {
            if (Context.defined("js")) // client-side
            {
                executeSharedTypes();   
            }
            else if (Context.defined("php")) // server-side
            {
                executeSharedTypes();
                executeServerTypes();
            }
        }
    }

    function executeSharedTypes()
    {
        var typeName = "";
        var typeFields = [];

        for (i in 0..._tokens.length)
        {
            var t = _tokens[i];

            if (t.type == TOKEN_STRUCTURE)
            {
                if (typeName != "")
                {
                    var def:TypeDefinition = {
                        fields: typeFields,
                        kind: TDAlias(TAnonymous(typeFields)),
                        name: typeName,
                        pack: [ "shared" ],
                        pos: Context.currentPos()
                    };

                    Context.defineType(def);
                }

                typeName = "T" + t.identifier;
            }
            else if (t.type == TOKEN_FIELD)
            {
                if (!doesStructureDefineTokenExist(i))
                    error("Field is not defined inside of a `structure` definition.", t.fileResource, i, i);

                var name = "";
                if (t.options.exists("id"))
                {
                    name = t.options.get("id");
                    name = name.replace(" ", "_").toLowerCase();
                }
                else
                {
                    name = t.displayValue;
                    name = name.replace(" ", "_").toLowerCase();
                }

                var type = options.get(t.identifier, GET_CLIENT_TYPE);
                if (type == "")
                    Context.error('Identifier `${t.identifier}` has not been defined or the type representing the identifier is empty.', Context.currentPos());

                typeFields.push({
                    kind: FVar(Context.toComplexType(Context.getType(type))),
                    pos: Context.currentPos(),
                    name: name,
                    meta: [
                        {
                            name: ":optional",
                            pos: Context.currentPos()
                        }
                    ]
                });
            }

            if (i == _tokens.length - 1)
            {
                var def:TypeDefinition = {
                    fields: typeFields,
                    kind: TDAlias(TAnonymous(typeFields)),
                    name: typeName,
                    pack: [ "shared" ],
                    pos: Context.currentPos()
                };

                Context.defineType(def);
            }
        }
    }

    function executeServerTypes()
    {
        var typeName = "";
        var typeFields = [];

        for (i in 0..._tokens.length)
        {
            var t = _tokens[i];

            if (t.type == TOKEN_STRUCTURE)
            {
                if (typeName != "")
                {
                    var def:TypeDefinition = {
                        fields: typeFields,
                        kind: TDClass({
                            name: "Object",
                            pack: [ "sys", "db" ]
                        }),
                        name: typeName,
                        pack: [ "data" ],
                        pos: Context.currentPos(),
                    };

                    Context.defineType(def);
                }

                typeName = t.identifier;
            }
            else if (t.type == TOKEN_FIELD)
            {
                if (!doesStructureDefineTokenExist(i))
                    error("Field is not defined inside of a `structure` definition.", t.fileResource, i, i);

                var name = "";
                if (t.options.exists("id"))
                {
                    name = t.options.get("id");
                    name = name.replace(" ", "_").toLowerCase();
                }
                else
                {
                    name = t.displayValue;
                    name = name.replace(" ", "_").toLowerCase();
                }

                var type = options.get(t.identifier, GET_SERVER_TYPE);
                if (type == "")
                    Context.error('Identifier `${t.identifier}` has not been defined or the type representing the identifier is empty.', Context.currentPos());
                
                typeFields.push({
                    kind: FVar(Context.toComplexType(Context.getType(type))),
                    pos: Context.currentPos(),
                    name: name,
                    access: [APublic]
                });
            }

            if (i == _tokens.length - 1)
            {
                var def:TypeDefinition = {
                    fields: typeFields,
                    kind: TDClass({
                        name: "Object",
                        pack: [ "sys", "db" ]
                    }),
                    name: typeName,
                    pack: [ "data" ],
                    pos: Context.currentPos(),
                };

                Context.defineType(def);
            }
        }
    }

    function doesStructureDefineTokenExist(current:Int)
    {
        var i = current;
        while (i > -1)
        {
            if (_tokens[i].type == TOKEN_STRUCTURE)
                return true;
            
            i--;
        }
        return false;
    }

}
#end