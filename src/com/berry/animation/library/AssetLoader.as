package com.berry.animation.library {
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;
    import flash.system.LoaderContext;
    import flash.system.SecurityDomain;

    import log.logServer.KLog;

    public class AssetLoader extends Loader {

        public function AssetLoader(name:String, url:String, callback:Function) {
            _name = name;

            _context = new LoaderContext();
            _context.checkPolicyFile = true;
            _context.allowCodeImport = true;
            _context.securityDomain = SecurityDomain.currentDomain;
            CONFIG::debug{ _context.securityDomain = null; }

            contentLoaderInfo.addEventListener(Event.COMPLETE, complete);
            contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, error);

            addCallback(callback);
            loadSwf(url);
        }

        private static const HTTP_PREFIX:String = 'http://';
        private const LIB_PROP:String = 'library';
        public var data:Class;
        private var _callback:Vector.<Function> = new Vector.<Function>();
        private var _url:String;
        private var _context:LoaderContext;
        private var _name:String;

        public function addCallback(callback:Function):void {
            if (callback != null) {
                _callback.push(callback);
            }
        }

        private function loadSwf(url:String):void {
            _url = url;
            load(new URLRequest(_url), _context);
        }

        private function clean():void {
            contentLoaderInfo.removeEventListener(Event.COMPLETE, complete);
            contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, error);
        }

        private function error(event:IOErrorEvent):void {

            CONFIG::debug{ KLog.log("SwfLoader:error " + event.toString() + ' url=' + _url, KLog.ERROR); }
            complete(null);
        }

        private function complete(event:Event):void {
            if (event) {
                var data:*;
                var className:String;

                if (content is Bitmap) {
                    data = content;
                } else {
                    if (content.hasOwnProperty(LIB_PROP)) {
                        var lib:Object = content[LIB_PROP];
                        for (var string:String in lib) {
                            className = string;
                            break;
                        }
                    } else {
                        className = _name;
                    }

                    data = contentLoaderInfo.applicationDomain.getDefinition(className) as Class;
                }

                for (var i:int = 0; i < _callback.length; i++) {
                    _callback[i](data, contentLoaderInfo);
                }
            }
            clean();
        }
    }

}
