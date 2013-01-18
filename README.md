Move all the fields and functions of a class to a specified object.

Usage(not implemented yet):
====

Haxe code:

```
class Scope {
    public var name = "freewind";
    public function hello() {
        trace(name);
    }
    public function new(obj:Dynamic) {
    }
}
```

Will generate js code:

```
class Scope {
    public function new(obj:Dynamic) {
        obj.name = "freewind";
        obj.hello = function() {
            trace(obj.name);
        }
    }
}
```


In order to solve this problem:

http://stackoverflow.com/questions/14397460/is-it-possible-to-let-angularjs-work-with-prototype-methods-and-variables