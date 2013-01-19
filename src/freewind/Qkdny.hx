package freewind;

import haxe.macro.Context;
import haxe.macro.Expr;

#if macro
using tink.macro.tools.MacroTools;
import tink.macro.tools.ExprTools;
#end

@:autoBuild(freewind.QkdnyBuilder.build()) interface Qkdny {
}


class QkdnyBuilder {

    private static var fieldNames:Array<String>;
    private static var ctor:Function;

    @:macro public static function build():Array<haxe.macro.Field> {
        var fields = Context.getBuildFields();
        ctor = getCtor(fields);
        fieldNames = getFieldVars(fields);
        var block = getExprs(ctor);

        var blockOriBody = block.copy();

        while (block.length > 0) {
            block.shift();
        }

        var targetObjExpr = EConst(CIdent(getTargetObjName(ctor)));

        var toRemove = new Array<Field>();

        for (ex in transformBlock(targetObjExpr, blockOriBody, ctor)) {
            block.push(ex);
        }


        for (f in fields) {
            switch(f.kind) {
                case FFun(func):
                    if (f.name != 'new' && !checkAccess(f.access, AStatic)) {
                        newFunc(block, targetObjExpr, f.name, func);
                        toRemove.push(f);
                    }
                case FVar(t, v):
                    if (!checkAccess(f.access, APrivate) && !checkAccess(f.access, AStatic)) {
                        newField(block, targetObjExpr, f.name, v == null ? null : v.expr);
                    }
                    if (!checkAccess(f.access, AStatic)) {
                        toRemove.push(f);
                    }
                default:
            }
        }

        for (f in toRemove) {
            fields.remove(f);
        }

        return fields;
    }

    #if macro
    
    private static function checkAccess(accessArr:Array<Access>, test:Access) {
        for (a in accessArr) {
            if (a == test) return true;
        }
        return false;
    }


    private static function isArgument(func:Function, varName:String):Bool {
        for (a in func.args) {
            if (a.name == varName) return true;
        }
        return false;
    }


    private static function getFieldVars(fields:Array<haxe.macro.Field>) {
        var names = new Array<String>();
        for (f in fields) {
            switch(f.kind) {
                case FVar(t, v): names.push(f.name);
                default:
            }
        }
        return names;
    }

    private static function transformBlock(target:ExprDef, block:Array<Expr>, ctor:Function):Array<Expr> {
        return block.mapArray(makeTransformer(target, ctor), null);
    }

    private static function getExprs(ctor:Function):Array<Expr> {
        switch(ctor.expr.expr) {
            case EBlock(exprs): return exprs;
            default: return null;
        }
    }

    private static function newField(block:Array<Expr>, target:ExprDef, varName:String, varValue:ExprDef) {
        block.push(
            {
            pos: Context.currentPos(),
            expr: EBinop(OpAssign, {
            pos: Context.currentPos(),
            expr: EField({ pos: Context.currentPos(), expr: target }, varName)
            }, {
            pos: Context.currentPos(),
            expr: varValue == null ? EConst(CIdent('null')) : varValue
            })
            }
        );
    }

    private static function isLocalVar(ctx:Array<VarDecl>, varName:String):Bool {
        for (v in ctx) {
            if (v.name == varName) return true;
        }
        return false;
    }

    private static function isField(name:String) {
        for (v in fieldNames) {
            if (v == name) return true;
        }
        return false;
    }

    private static function makeTransformer(target:ExprDef, func:Function) {
        return function(expr:Expr, ctx:Array<VarDecl>):Expr {
            switch(expr.getIdent()) {
                case Success(id):
                    if (id == 'this') {
                        return target.at();
                    }
                    if (!isLocalVar(ctx, id) && !isArgument(func, id) && isField(id)) {
                        return target.at().field(id);
                    }
                    return expr;
                case Failure(f):
            }
            return expr;
        }
    }

    private static function newFunc(block:Array<Expr>, target:ExprDef, varName:String, func:Function){
        // modify exprs related to `this` in the body of the function

        func.expr = func.expr.map(makeTransformer(target, func), null);

        block.push(
        {
        pos: Context.currentPos(),
        expr: EBinop(OpAssign, {
        pos: Context.currentPos(),
        expr: EField({ pos: Context.currentPos(), expr: target }, varName)
        }, {
        pos: Context.currentPos(),
        expr: EFunction(null, func)
        })
        }
        );

    }

    static function getTargetObjName(ctor:Function):String {
        if (ctor.args.length > 0) {
            return ctor.args[0].name;
        } else {
            throw new Error("Try to use the first argument, but no args found", Context.currentPos());
        }
    }

    static function getCtor(fields:Array<Field>) {
        for (f in fields) {
            if (f.name == "new") {
                switch(f.kind) {
                    case FFun(func): return func;
                    default: // do nothing
                }
            }
        }
        return null;
    }
#end

}
