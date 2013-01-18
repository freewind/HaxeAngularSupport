package ;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class QkdnyBuilder {

    @:macro public static function build():Array<haxe.macro.Field> {
        var fields = Context.getBuildFields();
        var ctor = getCtor();
        insertStmt(ctor);

        var funcExpr = macro function():String {
            return "test";
        }
        fields.push(makeFunc("test", funcExpr));
        return fields;
    }

    #if macro

    static function makeFunc(name:String, e:Expr, ?access, ?meta) {
		return {
			name: name,
			doc: null,
			access: access != null ? access : [APublic],
			pos: e.pos,
			meta: meta != null ? meta : [],
			kind: switch(e.expr) {
				case EFunction(_, func): FFun(func);
				case _: Context.error("Argument to makeFunc must be a function expression", e.pos);
			}
		}
	}

    static function insertStmt(ctor: Function) {
        switch(ctor.expr.expr) {
            case EBlock(exprs):
            exprs.push(macro trace("world"));
            default:
            trace("not a EBlock, change your code");
        }
    }

    static function getCtor() {
        var fields = Context.getBuildFields();
        for (f in fields) {
            if (f.name == "new") {
                switch(f.kind) {
                    case FFun(func): if (func.args.length == 1) {
                        return func;
                    } else {
                        throw new Error("the constructor can have only one argument, but have " + func.args.length, Context.currentPos());
                    }
                    default:
                }
            }
        }
        return null;
    }

#end

}
