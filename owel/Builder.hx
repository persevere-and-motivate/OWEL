package owel;
#if macro

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

import sys.FileSystem;

class Builder
{

    private static var parser:Parser;

    static function initJSIdentifiers(options:OwelOptions)
    {
        options.addIdentifier("ID");
        options.setClientStructureType("Int");
        options.addIdentifier("TextField");
        options.setClientStructureType("String");
        options.addIdentifier("Numeric");
        options.setClientStructureType("Int");
        options.addIdentifier("Date");
        options.setClientStructureType("Date");
        options.addIdentifier("Time");
        options.setClientStructureType("Date");
        options.addIdentifier("CheckBox");
        options.setClientStructureType("Bool");
        options.addIdentifier("ComboBox");
        options.setClientStructureType("Int");
        options.addIdentifier("TextArea");
        options.setClientStructureType("String");

        return options;
    }

    public static function generateTypes(folder:String)
    {
        var options = new OwelOptions();
        options = initJSIdentifiers(options);

        parser = new Parser(options);

        if (FileSystem.exists(folder))
        {
            var files = FileSystem.readDirectory(folder);
            for (f in files)
            {
                var path = folder + f;
                if (!FileSystem.isDirectory(path))
                {
                    // is an owel file
                    if (path.indexOf(".owel") == path.length - ".owel".length)
                    {
                        parser.parseFile(path);
                    }
                }
            }

            parser.executeTypes();
        }
    }

    public static function finalise()
    {
        
    }

}

#end