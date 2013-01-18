package ;

import Qkdny;
import QkdnyBuilder;
import Scope;

class Main {
    public function new() {
    }

    public static function main() {
        trace("hello");
        var x = {};
        var scope = new Scope(x);
    }
}
