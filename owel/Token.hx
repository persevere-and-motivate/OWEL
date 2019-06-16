package owel; #if macro

class Token
{

    public var fileResource:String;
    public var line:Int;
    public var type:Int;
    
    /*
    * Field Type parameters
    */

    public var identifier:Null<String>;
    public var displayValue:Null<String>;
    public var options:Null<Map<String, String>>;

    public function new()
    {

    }

    public function initField()
    {
        identifier = "";
        displayValue = "";
        options = new Map<String, String>();
    }

}
#end