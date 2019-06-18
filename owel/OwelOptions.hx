package owel; #if macro

class OwelOptions
{

    var currentIndex:Int = -1;

    public var identifiers:Array<String>;
    public var typesInStructures:Array<String>;

    public function new()
    {
        identifiers = [];
        typesInStructures = [];
    }

    public function addIdentifier(value:String)
    {
        typesInStructures.push("");
        identifiers.push(value);

        currentIndex++;
    }

    public function setClientStructureType(type:String)
    {
        typesInStructures[currentIndex] = type;
    }

    public function get(identifier:String, option:Int = 0)
    {
        for (i in 0...identifiers.length)
        {
            if (identifiers[i] == identifier)
            {
                
                if (option == 0)
                    return typesInStructures[i];
            }
        }
        return "";
    }

}
#end