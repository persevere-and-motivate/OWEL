package owel; #if macro

class OwelOptions
{

    var currentIndex:Int = -1;

    public var identifiers:Array<String>;
    public var typesInStructures:Array<String>;
    public var typesInServerClass:Array<String>;

    public function new()
    {
        identifiers = [];
        typesInStructures = [];
        typesInServerClass = [];
    }

    public function addIdentifier(value:String)
    {
        typesInStructures.push("");
        typesInServerClass.push("");
        identifiers.push(value);

        currentIndex++;
    }

    public function setClientStructureType(type:String)
    {
        typesInStructures[currentIndex] = type;
    }

    public function setServerClassType(type:String)
    {
        typesInServerClass[currentIndex] = type;
    }

    public function get(identifier:String, option:Int = 0)
    {
        for (i in 0...identifiers.length)
        {
            if (identifiers[i] == identifier)
            {   
                if (option == GET_CLIENT_TYPE)
                    return typesInStructures[i];
                else if (option == GET_SERVER_TYPE)
                    return typesInServerClass[i];
            }
        }
        return "";
    }

}

@:enum abstract OptionGet(Int) from Int to Int
{
    var GET_CLIENT_TYPE         =   0;
    var GET_SERVER_TYPE         =   1;
}

#end