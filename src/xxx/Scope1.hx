package xxx;

import haxe.Public;

@:keep
class Scope1 implements Public, implements freewind.Qkdny {

    public function new(scope:Dynamic) {
    }

    public var name:String = "myname";
    public var user:User ;
    public static var xxname = "xxname";

    static function test():String {
        return "xx";
    }

    private static var sname = "static name";

    public function hello1() {
        var s =test();
    }

    public function hello2() {
        test();
    }


}

private typedef User = {
name:String
}