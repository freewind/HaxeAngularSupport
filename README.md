This is a haxe macro which can let us writing augularjs controllers in class structure(fields and methds).

Actually, there is no extra macro needed to develop angularjs applications with haxe, you can see a demo from cambiata:

https://github.com/cambiata/Haxe-AngularJS-test/blob/master/src/site/MainController.hx

But the code may be improved:

  1. I don't want to declare a `typedef` for the scope argument, to repeat myself to declare those fields and functions
  2. I want to organise my code with class structure(fields and classes), it will be cleaner and benefit from the IDE (outline view)
  3. I don't want to write the "__init__" function each time

So I asked a question here: http://stackoverflow.com/questions/14397460/is-it-possible-to-let-angularjs-work-with-prototype-methods-and-variables

Since there is no good answers, I have to do it myself, with haxe.
After 4 days of work, this project is born.
I really appreciate [back2dos](https://github.com/back2dos/tinkerbell) and his great [tink_macros library](https://github.com/back2dos/tinkerbell/wiki/tink_macros#wiki-tooling),
he gave me so much help,
and also [Simon](http://code.google.com/p/hx-macro-examples/wiki/CompileTimeTemplates)
and [cambiata](https://github.com/cambiata/Haxe-AngularJS-test),
and [Atry](https://github.com/Atry/haxe-continuation). This project is pretty simple, but it shows me the power of haxe,
that I think I can use haxe in my project from now on.

With my "AngularSupport" macro, I can write angularjs controller this way:

```
import freewind.AngularSupport;

class MyCtrl implements Public, implements AngularSupport {

    @AngularSupport({inject:['$scope', '$http'], scope:'$scope'})
    function new(scope:Dynamic, http:Dynamic) {
        this.http = http;
        // don't need to assign "scope" to anything
    }

    var http:Dynamic;
    var name = "Freewind";
    function hello() {
        js.Lib.alert(name);
    }
}
```

It will generate haxe code to:

```
import freewind.AngularSupport;

class MyCtrl implements Public, implements AngularSupport {

    public static function __init__() {
        js.Lib.eval("MyCtrl.$inject = ['$scope', '$http'];");
    }

    function new(scope:Dynamic, http:Dynamic) {
        this.http = http;
        // don't need to assign "scope" to anything
        scope.http = Reflect.setField(scope, 'http', Reflect.field(this, 'http'));
        scope.name = Reflect.setField(scope, 'name', Reflect.field(this, 'name'));
        scope.hello = angular.bind(scope, this.hello);
    }

    var http:Dynamic;
    var name = "Freewind";
    function hello() {
        js.Lib.alert(name);
    }
}
```

Which can generate correct javascript code for angularjs.

Some tips
---------

1. The controller must implements "AngularSupport" interface
2. Put a metadata `@AngularSupport({inject:['$scope', '$http'], scope:'$scope'})` on the constructor, which is function `new`
3. Don't assign the passing `scope` to any fields
4. Static variables and functions won't be added to 'scope'
5. Private variables won't be added to 'scope'

The 5th rule is important for nesting controllers. If I will use some data from parent's scope, that I need it to be private,
then I can just use it(from parent), without assign it to current scope with a new value.

Requirements
------------

1. Use nightly-build haxe, since it requires latest macro api. For me, I use the build r5894, you can download it here if you are using windows: http://94.142.242.48/builds/windows/?C=M;O=D
2. It requires lib "tink_macros", but the version "1.2.1" from haxelib is not new enough. You can use the code I included in this project (src/tink), or clone from https://github.com/back2dos/tinkerbell

Welcome trying and improving it :)