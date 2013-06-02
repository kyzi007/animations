package dzyga.utils {
    import com.carlcalderon.arthropod.Debug;

    import flash.events.NetStatusEvent;
    import flash.net.SharedObject;
    import flash.net.SharedObjectFlushStatus;
    import flash.net.registerClassAlias;

    public class SOOperator {
        public static var inited:Boolean = false;
		private static var index:SharedObject;
       
        private static const DIR:String = '/';
        private static const INDEX:String = 'sooperator.index';
        private static const SIZE:Number = 0;//100000000000000;
        private static const FLUSH_FAILED:String = 'SharedObject.Flush.Failed';
        private static const FLUSH_SUCCESS:String = 'SharedObject.Flush.Success';
		
        public static function init():void {
			Debug.log('SOOperator.init');
			//return;
            SOOperator.enabled = false;
            registerClassAlias('SOEntry', SOEntry);
            
            try {
                SOOperator.index = SharedObject.getLocal(
                    SOOperator.INDEX, SOOperator.DIR);
            }
            catch (error:Error) {
                SOOperator.enabled = false;
                return;
            }
			
            SOOperator.flushIndex();
            SOOperator.cleanUp();
            SOOperator.inited = true; 
        }
        
        private static function flushIndex():void {
            var re:String;
            try {
                re = SOOperator.index.flush(SOOperator.SIZE);
            }
            catch (e:Error) {
                SOOperator.enabled = false;
                return;
            }
            
            if (re == SharedObjectFlushStatus.PENDING) {
                SOOperator.index.addEventListener(
                    NetStatusEvent.NET_STATUS, SOOperator.onFlush);
            }
            else {
                SOOperator.enabled = true;
            }
        }
        
        private static function onFlush(event:NetStatusEvent=null):void {
            SOOperator.index.removeEventListener(
                NetStatusEvent.NET_STATUS, SOOperator.onFlush);
            var code:String = event.info.code;
            switch (code) {
                case SOOperator.FLUSH_SUCCESS:
                    SOOperator.enabled = true;
                    break;
                case SOOperator.FLUSH_FAILED:
                    SOOperator.enabled = false;
                    break;
                default:
					SOOperator.enabled = false;
                    Debug.error(
						'SOOperator.flushIndex: Unknown NetStatusEvent result: ' 
						+ ObjectUtils.repr(event.info));
            }
        }
        
        private static var _enabled:Boolean;
        public static function get enabled():Boolean {
            if (!SOOperator.inited) {
                SOOperator.init();
            }
            return SOOperator._enabled;
        }
        
        public static function set enabled(val:Boolean):void {
            SOOperator._enabled = val;
        }
        
        public static function cleanUp():void {
            try {
                var oldData:SharedObject = SharedObject.getLocal('parameters', '/');
                oldData.clear();
            }
            catch (e:Error) {}
        }
        
        public static function write(name:String, data:*):void {
            if (!SOOperator.enabled) {
                return;
            }
            
            var entry:SOEntry = SOOperator.index.data[name];
            if (!entry) {
                entry = new SOEntry();
                entry.name = name;
                entry.id = StringUtils.random(10);
                SOOperator.index.data[name] = entry;
            }
            
            entry.data = data;
            entry.time = new Date();//TimeSync.serverTime; 
            SOOperator.flushIndex();
            
            var cache:SharedObject = SharedObject.getLocal(
                entry.id, SOOperator.DIR);
            cache.data.data = entry.data;
            cache.flush();
        }
        
        public static function read(name:String):* {
            if (!SOOperator.enabled) {
                return;
            }
            
            var entry:SOEntry = SOOperator.index.data[name];
            if (!entry) {
                return null;
            }
            
            if (!entry.data) {
                var cache:SharedObject = SharedObject.getLocal(
                    entry.id, SOOperator.DIR);
                entry.data = cache.data.data;
                cache.flush();
            }
            
            entry.time = new Date();//TimeSync.serverTime;
            return entry.data;
        }

        public static function remove(name:String):void {
            if (!SOOperator.enabled) {
                return;
            }

            var entry:SOEntry = SOOperator.index.data[name];
            if (!entry) {
                return;
            }

            var cache:SharedObject = SharedObject.getLocal(
                entry.id, SOOperator.DIR);
            cache.clear();

            delete SOOperator.index.data[name];
            SOOperator.flushIndex();
        }
	}
}
