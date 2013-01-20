package freewind;

import haxe.macro.Expr;
#if macro
import haxe.macro.Context;
import tink.macro.tools.ExprTools;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;
using Lambda;
#end

@:autoBuild(freewind.QkdnyBuilder.build()) interface Qkdny {
}

class QkdnyBuilder {

    private static var staticFields:Array<haxe.macro.Field>;

    @:macro public static function build():Array<haxe.macro.Field> {
        var fields = Context.getBuildFields();

        ctor = getCtor(fields);
        instanceFieldNames = getInstanceFieldNames(fields);

        staticFields = [];
        for (f in fields) {
            if (f.access.has(AStatic)) staticFields.push(f);
        }

        var block = getExprs(ctor);

        var blockOriBody = block.copy();

        block.splice(0, block.length);

        var targetObjExpr = getTargetObjName(ctor).resolve();

        var toRemove = new Array<haxe.macro.Field>();

        for (ex in transformBlock(targetObjExpr, blockOriBody, ctor))
            block.push(ex);

        for (f in fields) {
            switch(f.kind) {
                case FFun(func):
                    if (f.name != 'new' && !f.access.has(AStatic)) {
                        // func.expr = func.expr.map(makeTransformer(targetObjExpr, func), scope(targetObjExpr));

                        newFunc(block, targetObjExpr, f.name, func);
                        toRemove.push(f);
                    }
                case FVar(t, v):
                    if (!f.access.has(APrivate) && !f.access.has(AStatic))
                        newField(block, targetObjExpr, f.name, v == null ? (macro null) : v);

                if (!f.access.has(AStatic))
                toRemove.push(f);
                default:
            }
        }

        for (f in toRemove)
            fields.remove(f);

        return fields;
    }

    #if macro
    static var instanceFieldNames:Array<String>;
    static var ctor:Function;

    static function getInstanceFieldNames(fields:Array<haxe.macro.Field>):Array<String> {
        var names = new Array<String>();
        for (f in fields) {
              if(!f.access.has(AStatic)) {
                names.push(f.name);
              }
//            switch(f.kind) {
//                case FVar(t, v): names.push(f.name);
//                default:
//            }
        }
        return names;
    }
    static function scope(target:Expr) {
        var ctx = [ { name : target.getIdent().sure(), type: macro : Dynamic, expr: null } ];
        for(f in staticFields) ctx.push({ name:f.name, type:null, expr:f.toExpr() });
//            switch(f.kind) {
//                case FFun(func): {
//                  var args = func.args.map(function(item) return item.type);
//                  ctx.push({ name: f.name, type: TFunction(args, func.ret), expr: null });
//                }
//                case FVar(_,_): ctx.push({ name: f.name, type: macro:Dynamic, expr: null });
//                default:
//            }
        return ctx;
    }


    static function transformBlock(target:Expr, block:Array<Expr>, ctor:Function):Array<Expr>
        return block.mapArray(makeTransformer(target, ctor), scope(target))

    static function getExprs(ctor:Function):Array<Expr>
        return
            switch(ctor.expr.expr) {
                case EBlock(exprs): exprs;
                default: [ctor.expr];
            }

    static function newField(block:Array<Expr>, target:Expr, varName:String, varValue:Expr)
        block.push(
            OpAssign.make(
                target.field(varName),
                varValue
            )
        )

    static function newFunc(block:Array<Expr>, target:Expr, varName:String, func:Function){
//        func.expr = func.expr.map(makeTransformer(target, func), scope(target));
        func.expr = func.expr.map(function(expr:Expr, ctx:Array<VarDecl>):Expr {
                             return expr;
                         }, null);
//         func.expr = haxe.macro.ExprTools.map(func.expr, function(expr:Expr):Expr {
//                             return expr;
//                         });
        newField(block, target, varName, func.toExpr());
    }

    static function has(haystack:Iterable<{ name: String }>, needle:String) {
        for (straw in haystack)
            if (straw.name == needle)
                return true;
        return false;
    }

    static function makeTransformer(target:Expr, func:Function)
        return function(expr:Expr, ctx:Array<VarDecl>):Expr {
            if(true) return expr;
            return
                switch(expr.getIdent()) {
                    case Success(id):
                        return
                            if (id == 'this')
                                target;
                            else if (!has(ctx, id) && !has(func.args, id) && instanceFieldNames.has(id)) {
                                target.field(id);
                            }
                            else {
                                trace("------ ctx --------" + ctx);
                                expr;
                            }
                    case Failure(f): expr;
                }
        }

    static function getTargetObjName(ctor:Function):String {
        if (ctor.args.length == 0)
            ctor.args.push('scope'.toArg(macro : Dynamic));
        return
            ctor.args[0].name;
    }

    static function getCtor(fields:Array<Field>) {
        for (f in fields)
            if (f.name == "new")
                switch(f.kind) {
                    case FFun(func): return func;
                    default: throw 'assert';//shouldn't happen
                }

        return [].toBlock().func(['scope'.toArg(macro : Dynamic)], false);
    }

#end
}