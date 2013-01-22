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

@:autoBuild(freewind.AngularSupportBuilder.build())
interface AngularSupport {
}

class AngularSupportBuilder {

    @:macro public static function build():Array<haxe.macro.Field> {
        allFields = Context.getBuildFields();
        getClsName();
        getCtor();
        getMeta();
        getInstanceHolderName();
        getCtorBlock();
        handle();
        createInject();
        return allFields;
    }

    #if macro
    private static var META_NAME = "AngularSupport";
    private static var currentClsName:String;
    private static var allFields:Array<Field>;

    private static var metaInject;
    private static var metaScope;

    private static var ctorField:Field;
    private static var ctor:Function;

    private static var instanceHolderName:String;
    private static var instanceHolder:Expr;

    private static var block:Array<Expr>;

    private static function getClsName() {
        switch(Context.getLocalType()) {
            case TInst(ins, _): currentClsName = ins.toString();
            default:
        }
    }

    private static function getCtor() {
        for (f in allFields) {
            switch(f.kind) {
                case FFun(func) :
                    if (!f.access.has(AStatic) && f.name == 'new') {
                        ctor = func;
                        ctorField = f;
                    }
                default:
            }
        }
        if (ctor == null) throw new Error("No constructor 'new()' found", Context.currentPos());
        if (ctor.args.length == 0) throw new Error("Try to use the first argument from ctor, but no args found", Context.currentPos());
    }

    private static function getMeta() {
        if (ctorField.meta == null || ctorField.meta.length == 0) {
            throw new Error("constructor should have a metadata '"+META_NAME+"'", Context.currentPos());
        }

        var angularSupportMeta = null;
        for (m in ctorField.meta) {
            if (m.name == META_NAME) {
                angularSupportMeta = m;
                break;
            }
        }
        if (angularSupportMeta == null) {
            throw new Error("No metadata '" + META_NAME + "' found", Context.currentPos());
        }

        metaInject = [];
        metaScope = null;
        for (params in angularSupportMeta.params) {
            switch(params.expr) {
                case EObjectDecl(pArray):
                    for (p in pArray) {
                        if (p.field == 'inject') {
                            switch(p.expr.expr) {
                                case EArrayDecl(arr):
                                    if (arr.length != ctor.args.length) {
                                        throw new Error("The length(" + arr.length + ") of inject array should be equal to ctor args(" + ctor.args.length + ")", Context.currentPos());
                                    }
                                    for (item in arr) {
                                        metaInject.push(item.getString().sure());
                                    }
                                default: throw new Error("inject should be an array", Context.currentPos());
                            }
                        } else if (p.field == 'scope') {
                            metaScope = p.expr.getString().sure();
                        }
                    }
                default:
            }
        }
    }

    private static function getInstanceHolderName() {
        var scopeIndex = -1;
        for (i in 0...metaInject.length) {
            if (metaInject[i] == metaScope) {
                scopeIndex = i;
                break;
            }
        }
        if (scopeIndex == -1) {
            throw new Error("The scope in metadata AngularJs is not in inject array: " + metaScope, Context.currentPos());
        }
        instanceHolderName = ctor.args[scopeIndex].name;
        instanceHolder = instanceHolderName.resolve();
    }

    private static function createInject() {
        var injectStr = currentClsName + ".$inject = [" + metaInject.map(function(i) return "'" + i + "'").join(',')+ "]";
        var eval = macro js.Lib.eval(${injectStr.toExpr()});

        allFields.push({
            name: "__init__",
            doc: null,
            access: [APublic, AStatic],
            kind: FFun({
                args: [],
                ret: null,
                expr: eval,
                params: []
            }),
            pos: Context.currentPos(),
            meta : null
        });
    }

    private static function getCtorBlock() {
        switch(ctor.expr.expr) {
            case EBlock(b): block = b;
            default: block = [ctor.expr];
        }
    }

    private static function handle() {
        for (f in allFields) {
            if (f.access.has(AStatic)) continue;
            if(f.access.has(APrivate)) continue;
            switch(f.kind) {
                case FVar(t, _):
                    block.push(macro Reflect.setField(
                        ${instanceHolderName.resolve()},
                        ${f.name.toExpr()},
                        Reflect.field(this, ${f.name.toExpr()})));
                case FFun(func):
                    if (f.name == 'new' || f.name == '__init__') continue;
                    var js = (instanceHolderName + "." + f.name + "= angular.bind(" + instanceHolderName + ", this." + f.name + ")").toExpr();
                    block.push(macro untyped { __js__(${js}); });
                default:
            }
        }
    }
#end
}