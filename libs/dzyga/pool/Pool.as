package dzyga.pool {
    import flash.utils.Dictionary;

    public class Pool {
		private static var _pool:Dictionary = new Dictionary();
		
		public static function get(cls:Class):IReusable {
			var _clsPool:Vector.<IReusable> = Pool._pool[cls];
			if (!_clsPool || !_clsPool.length) {
				return new cls();
			}
			else {
				return _clsPool.shift();
			}
		}
		
		public static function put(instance:IReusable):void {
            if(!instance) return;
			instance.reset();
			var cls:Class = instance.reflection;
			var _clsPool:Vector.<IReusable> = Pool._pool[cls];
			if (!_clsPool) {
				_clsPool = new <IReusable>[instance];
				Pool._pool[cls] = _clsPool;
			}
			else {
				_clsPool.push(instance);
			}
		}
	}
}
