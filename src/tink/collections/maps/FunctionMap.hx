package tink.collections.maps;

#if (flash9 || php || js)
	class FunctionMap < K, V > extends ObjectMap < K, V > { 
		#if js
			static function __init__() {
				tink.native.JS.patchBind();
			}
		#end
	}
#elseif (flash)
	class FunctionMap < K, V > extends tink.collections.maps.base.StringIDMap < K, V > { 
		static var idCounter = 0;
		function objID(o:Dynamic):String untyped {			
			var id = o.__getID;
			if (id == null) {
				var v = Std.string(idCounter++);
				o.__getID = id = function () return v;
			}
			return id();		
		}
		override function transform(k:K):String untyped {
			return
				#if js
					if (k == null) 'null';
					else if (k.scope) objID(k.scope) + k.method;
					else objID(k);
				#else
					if (k == null) 'null';
					else if (k.o) objID(k.o) + k.f;
					else objID(k);					
				#end
		}
	}	
#else
	//TODO: optimize for both neko and c++ - depends on the ability do decompose a method closure to it's components or have another way to get a unique ID for method closures
	class FunctionMap < K, V > extends tink.collections.maps.base.KVPairMap < K, V > {
		override function equals(k1:K, k2:K):Bool {
			return Reflect.compareMethods(k1, k2);
		}
	}
#end