package dzyga.utils {
    import flash.net.SharedObject;

    public class LightSharedObject {
        private static const DIR:String = 'midnight';
        private static var _sharedObject:SharedObject = SharedObject.getLocal(DIR);

        public static function write(name:String, data:*):void {
            _sharedObject.data[name] = data;
            _sharedObject.flush();
        }

        public static function read(name:String):* {
            return _sharedObject.data[name];
        }

        public static function remove(name:String):void {
            _sharedObject.data[name] = null;
            _sharedObject.flush();
        }
    }
}
