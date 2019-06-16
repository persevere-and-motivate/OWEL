package owel;
#if macro

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

import sys.FileSystem;

class Builder
{

    private static var parser:Parser;

    public static function generateTypes(folder:String)
    {
        parser = new Parser();

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
        }
    }

    public static function finalise()
    {
        
    }

}

#end