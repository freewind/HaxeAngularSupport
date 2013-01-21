package common;

class Helper {

    public static function importObject<T>(ob:Dynamic) {
        var hash = new Hash<T>();
        for (field in Reflect.fields(ob))
            hash.set(field, Reflect.field(ob, field));
        return hash;
    }

}
