package owel;
#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.ExprTools;

import sys.FileSystem;

class Builder
{

    private static var parser:Parser;

    static function initJSIdentifiers(options:OwelOptions)
    {
        options.addIdentifier("ID");
        options.setClientStructureType("Int");
        options.setServerClassType("sys.db.Types.SId");

        options.addIdentifier("TextField");
        options.setClientStructureType("String");
        options.setServerClassType("sys.db.Types.STinyText");

        options.addIdentifier("Numeric");
        options.setClientStructureType("Int");
        options.setServerClassType("sys.db.Types.SInt");

        options.addIdentifier("Date");
        options.setClientStructureType("Date");
        options.setServerClassType("sys.db.Types.SDate");

        options.addIdentifier("Time");
        options.setClientStructureType("Date");
        options.setServerClassType("sys.db.Types.STimeStamp");

        options.addIdentifier("DateTime");
        options.setClientStructureType("Date");
        options.setServerClassType("sys.db.Types.SDateTime");

        options.addIdentifier("CheckBox");
        options.setClientStructureType("Bool");
        options.setServerClassType("sys.db.Types.SBool");

        options.addIdentifier("ComboBox");
        options.setClientStructureType("Int");
        options.setServerClassType("sys.db.Types.SInt");

        options.addIdentifier("TextArea");
        options.setClientStructureType("String");
        options.setServerClassType("sys.db.Types.SText");

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

    public macro static function finalise():Array<Field>
    {
        var fields = Context.getBuildFields();

        //
        // `all()` - Gets all the records for the server type.
        //

        {
            var allBody = macro {
                var items = manager.all();
                var results = [];
                for (item in items)
                    results.push(item.toTypedef());
                return results;
            };

            var allFunction:Function = {
                args: [],
                expr: allBody,
                ret: null
            };

            var allField:Field = {
                access: [APublic, AStatic],
                kind: FFun(allFunction),
                name: "all",
                pos: Context.currentPos()
            };

            fields.push(allField);
        }

        return fields;
    }

}

#end