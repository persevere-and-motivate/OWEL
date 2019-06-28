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

    public macro static function finalise(searchableFields:Array<String>):Array<Field>
    {
        var fields = Context.getBuildFields();
        var className = Context.getLocalClass().get().name;

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

        //
        // `modify()` - Sets specific values dependent on RESTful notation for a given Database Object.
        // Example: POST user/5  - Will UPDATE the User object with id 5.
        //

        {
            var sharedTypePath = "shared.T" + className;
            var tType = Context.toComplexType(Context.getType(sharedTypePath));
            var cType = Context.toComplexType(Context.getType(className));
            var cTypePath:TypePath = {
                name: className,
                pack: [ "data" ]
            };

            var dataSetters = [];
            switch (tType)
            {
                case TAnonymous(fields):
                {
                    for (i in 0...fields.length)
                    {
                        var f = fields[i];
                        var fieldName = f.name;
                        dataSetters.push(macro { item.$fieldName = data.$fieldName; });
                    }
                }
                default:
            }

           
            var modifyBody = macro {
                if (method == "GET" && id > -1)
                {
                    return manager.get(id).toTypedef();
                }
                else if (method == "DELETE" && id > -1)
                {
                    var item = manager.get(id);
                    item.delete();
                    return null;
                }
                else
                {
                    var input = sys.io.File.getContent("php://input");
                    var data:$tType = haxe.Json.parse(input);
                    var item:$cType = null;

                    if (method == "PUT")
                        item = new $cTypePath();
                    else if (method == "POST" && id > -1)
                        item = manager.get(id);
                    
                    if (id == null)
                    {
                        php.Web.setReturnCode(500);
                        php.Lib.print('The item with the id ' + id + ' does not exist.');
                        return null;
                    }

                    $a{dataSetters};

                    if (method == "PUT")
                        item.insert();
                    else if (method == "POST")
                        item.update();
                    
                    return item.toTypedef();
                }
            };

            var modifyFunction:Function = {
                args: [
                    {
                        name: "method",
                        type: macro :String
                    },
                    {
                        name: "id",
                        type: macro :Int,
                        opt: true,
                        value: macro -1
                    }
                ],
                expr: modifyBody,
                ret: null
            };

            var modifyField:Field = {
                access: [APublic, AStatic],
                kind: FFun(modifyFunction),
                name: "modify",
                pos: Context.currentPos()
            };

            fields.push(modifyField);
        }

        //
        // `search()` - Search the specified default searchable field. Uses only the :searchable options
        // in fields.
        //
        {
            var searchable = "$" + searchableFields[0];

            var searchBody = macro {
                var items = manager.search($i{searchable}.like(value));
                var results = [];
                for (item in items)
                    results.push(item.toTypedef());
                return results;
            };

            var searchFunction:Function = {
                args: [
                    {
                        name: "value",
                        type: macro :String
                    }
                ],
                expr: searchBody,
                ret: null
            };

            var searchField:Field = {
                access: [APublic, AStatic],
                kind: FFun(searchFunction),
                name: "search",
                pos: Context.currentPos()
            };

            fields.push(searchField);
        }

        return fields;
    }

}

#end