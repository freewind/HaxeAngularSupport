package ;

import haxe.Public;

class Scope1 implements Public, implements freewind.Qkdny {

    public function new(scope:Dynamic) {
    }

    public var name:String = "myname";

    public function hello() {
        var x = name;
        function() {
            var y = name;
        }
    }
}