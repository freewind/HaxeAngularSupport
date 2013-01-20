package freewind;

import haxe.macro.Context;
import haxe.macro.Expr;

#if macro
import tink.macro.tools.ExprTools.VarDecl;
import tink.macro.tools.ExprTools;
using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
#end
using Lambda;

@:autoBuild(freewind.QkdnyBuilder.build())
interface Qkdny {
}

class QkdnyBuilder {

    @:macro public static function build():Array<haxe.macro.Field> {
        init();

        moveInstanceVars();
        handleCtorBody();
        moveInstanceFunctions();

        removeFields();

        return allFields;
    }

    #if macro

 private static var allFields:Array<Field>;

    private static var staticFields:Array<haxe.macro.Field>;
    private static var instanceNames:Array<String>;

    private static var ctor:Function;

    private static var instanceHolder:Expr;

    private static var ctorOriBlock:Array<Expr>;
    private static var block:Array<Expr>;

    private static var toRemove:Array<Field>;

    private static function init() {
        allFields = Context.getBuildFields();

        staticFields = [];
        instanceNames = [];
        for (f in allFields) {
            if (f.access.has(AStatic)) {
                staticFields.push(f);
            } else {
                instanceNames.push(f.name);
            }
            switch(f.kind) {
                case FFun(func) :
                    if (!f.access.has(AStatic) && f.name == 'new') {
                        ctor = func;
                    }
                default:
            }
        }

        if (ctor == null) throw new Error("No 'function new()' found", Context.currentPos());
        if (ctor.args.length == 0) throw new Error("Try to use the first argument from ctor, but no args found", Context.currentPos());

        instanceHolder = ctor.args[0].name.resolve();

        switch(ctor.expr.expr) {
            case EBlock(b): block = b;
            default: block = [ctor.expr];
        }

        ctorOriBlock = block.copy();
        block.splice(0, block.length);
        toRemove = [];
    }


    private static function moveInstanceVars() {
        // ignore private ones
        for (f in allFields) {
            switch(f.kind) {
                case FVar(t, v): if (!f.access.has(AStatic) && !f.access.has(APrivate)) {
                    block.push(newField(f.name, v == null ? (macro null) : v));
                    toRemove.push(f);
                }
                default:
            }
        }
    }

    private static function handleCtorBody() {
        for(x in ctorOriBlock.mapArray(makeTransformer(ctor.args), defaultScope())) {
            block.push(x);
        }
    }

    private static function moveInstanceFunctions() {
        for (f in allFields) {
            switch(f.kind) {
                case FFun(func): if (!f.access.has(AStatic)) {
                    if (f.name == 'new') continue;
                    trace("### processing func: " + f.name);
                    func.expr = func.expr.map(makeTransformer(func.args), defaultScope());
                    block.push(
                        newField(f.name, EFunction(null, func).at())
                    );
                    toRemove.push(f);
                }
                default:
            }
        }
    }

    private static function removeFields() {
        for (f in toRemove) {
            allFields.remove(f);
        }
    }

    static function defaultScope() {
        var ctx = [
            { name: instanceHolder.getIdent().sure(), type: macro : Dynamic, expr: null }
        ];
        for (f in staticFields) {
            switch(f.kind) {
                case FFun(func):
                    ctx.push({ name:f.name, type:null, expr:func.toExpr() });
                case FVar(t, e):
                    ctx.push({ name: f.name, type: t, expr: e });
                default:
            }
        }
        return ctx;
    }


    private static function newField(varName:String, varValue:Expr) {
        return
            {
            pos: Context.currentPos(),
            expr: EBinop(OpAssign, {
            pos: Context.currentPos(),
            expr: EField(instanceHolder, varName)
            }, varValue)
            }
    }

    private static function makeTransformer(args:Array<FunctionArg>) {
        return function(expr:Expr, ctx:Array<VarDecl>):Expr {
            if (ctx == null) ctx = defaultScope();
            switch(expr.getIdent()) {
                case Success(id):
                    if (id == 'this') return instanceHolder;
                    if (!hasName(ctx, id) && !hasName(args, id)) {
                        if (instanceNames.has(id)) {
                            return instanceHolder.field(id);
                        }
                    }
                    return expr;
                case Failure(f):
            }
            return expr;
        }
    }

    static function hasName(haystack:Iterable<{ name:String }>, needle:String) {
        for (straw in haystack)
            if (straw.name == needle)
                return true;
        return false;
    }

#end
}
