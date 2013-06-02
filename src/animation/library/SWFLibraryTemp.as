package animation.library {
    public class SWFLibraryTemp {
        public function SWFLibraryTemp() {
        }

        private static var _loaders:Object = {};

        public static function loadSource(name:String, url:String, objectType:String, callback:Function):void {
            var data:* = _loaders[name];

            if (!data || !data is SwfLoader) {
                data = new SwfLoader(name, url, callback);
                _loaders[name] = data;
            } else if (data && data is SwfLoader) {
                SwfLoader(data).addCallback(callback);
            } else if (data) {
                //_loaders[name] = data.data;
                callback(data);
            }
        }

        public static function addSource(name:String, data:*):void {
            _loaders[name] = data;
        }
    }
}

import animation.AnimationSettings;
import animation.library.AssetLibrary;
import animation.library.SWFLibraryTemp;

import dzyga.utils.StringUtils;

import flash.display.Bitmap;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.net.URLRequest;
import flash.system.LoaderContext;

import log.logServer.KLog;

class SwfLoader extends Loader {

    private var _callback:Vector.<Function> = new Vector.<Function>();
    private var _url:String;
    private var _context:LoaderContext;

    private static const HTTP_PREFIX:String = 'http://';
    public var data:Class;
    private var _name:String;
    private const LIB_PROP:String = 'library';

    public function SwfLoader(name:String, url:String, callback:Function) {
        _name = name;

        _context = new LoaderContext();
        _context.checkPolicyFile = true;
        _context.allowCodeImport = true;

        contentLoaderInfo.addEventListener(Event.COMPLETE, complete);
        contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, error);

        addCallback(callback);
        if (!StringUtils.startswith(url, HTTP_PREFIX)) {
            try {
                url = AnimationSettings.getUrl(url);
            } catch (err:Error) {

            }
        }
        loadSwf(url);
    }

    public function addCallback(callback:Function):void {
        _callback.push(callback);
    }

    private function loadSwf(url:String):void {
        _url = url;
        load(new URLRequest(_url), _context);
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

            AssetLibrary.registerAsset(_name, data);
            for (var i:int = 0; i < _callback.length; i++) {
                _callback[i](data);
            }

            SWFLibraryTemp.addSource(_name, data);
        }
        clean();
    }

    private function clean():void {
        contentLoaderInfo.removeEventListener(Event.COMPLETE, complete);
        contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, error);
    }
}
