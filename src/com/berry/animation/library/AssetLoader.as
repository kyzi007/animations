package com.berry.animation.library {

    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;
    import flash.system.LoaderContext;
    import flash.system.SecurityDomain;


    import org.dzyga.callbacks.Once;

    public class AssetLoader extends Loader {

        public function AssetLoader(name:String, url:String) {
            _name = name;

            _context = new LoaderContext();
            _context.checkPolicyFile = true;
            _context.allowCodeImport = true;
            _context.securityDomain = SecurityDomain.currentDomain;

            contentLoaderInfo.addEventListener(Event.COMPLETE, complete);
            contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, error);
            loadSwf(url);
        }

        private static const LIB_PROP:String = 'library';
        public var data:Class;
        private var _url:String;
        private var _context:LoaderContext;
        private var _name:String;
        public var completePromise:Once = new Once();

        private function loadSwf(url:String):void {
            _url = url;
            load(new URLRequest(_url), _context);
        }

        private function clean():void {
            contentLoaderInfo.removeEventListener(Event.COMPLETE, complete);
            contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, error);
        }

        private function error(event:IOErrorEvent):void {
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
                completePromise.resolve(data, contentLoaderInfo);
            }
            clean();
        }
    }
}
