package xxx;

import haxe.Public;

class Scope2 implements Public/*, implements freewind.Qkdny */{

    public function new(scope:Dynamic) {
    }

    public var name:String = "myname";

    public function hello() {
        function() {
            var x = name;
        }
    }

}