package com.berry.animation.library {
    import com.berry.animation.data.SourceTypeEnum;
    import com.berry.animation.draw.BaseDrawInstruct;
    import com.berry.animation.draw.TileDrawInstruct;
    import com.berry.animation.draw.WyseDrawInstruct;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.Sprite;

    import org.dzyga.events.EnterFrame;
    import org.dzyga.events.IInstruct;
    import org.dzyga.pool.Pool;

    import umerkiCommon.evens.SimpleEventDispatcher;

    ;

    public class AssetLibrary {
        public function AssetLibrary(baseUrl:String) {
            _baseUrl = baseUrl;
        }

        public static const ON_INIT:String = 'init';
        protected var _assets:Object = {};
        protected var _doHash:Object = {};
        protected var _classHash:Object = {};
        private var _dispatcher:SimpleEventDispatcher = new SimpleEventDispatcher();
        private var _baseUrl:String;
        private var _cached:Object = {};

        public function gcForce():void {
            // todo
        }

        public function init():void {
            // for override
            EnterFrame.scheduleAction(10000, gc);
        }

        public function getPreloader(assetName:String):AssetData {
            // for override
            return null;
        }

        public function registerAsset(data:*, assetName:String):void {
            if (data is Bitmap) {
                _doHash[data] = data;
            } else {
                _classHash[data] = assetName;
            }
        }

        public function gc():void {
            EnterFrame.scheduleAction(10000, gc);
            if (EnterFrame.calculatedFps < 20) {
                return;
            }
            for (var assetsName:String in _assets) {
                var assetsByName:Array = _assets[assetsName];
                var count:int = 0;
                for each (var assetData:AssetData in assetsByName) {
                    // if not playing and rendering
                    if (assetData.useCount == 0 && assetData.getQuery.isAutoClear && assetData.isRenderFinish) {
                        assetData.destroy();
                        assetsByName.splice(assetsByName.indexOf(assetData));
                    }
                    if (!assetData.isDestroyed) {
                        count++;
                    }
                }
                // if asset unused delete source
                if (count == 0) {
                    //delete _classHash[assetsName];
                    delete _cached[assetsName];
                    if (!(_doHash is Bitmap)) {
                        delete _doHash[assetsName];
                    }
                }
            }
        }

        public function loadData(name:String, type:SourceTypeEnum, finishCallback:Function):void {
            var data:* = _classHash[name];

            if (!data) {
                data = new SwfLoader(name, getUrl(name, type.value), null);
                _classHash[name] = data;
                SwfLoader(data).addCallback(function (loadedData:*):void {
                    _classHash[name] = loadedData;
                    finishCallback(loadedData);
                });
            } else if (data is SwfLoader) {
                SwfLoader(data).addCallback(function (loadedData:*):void {
                    _classHash[name] = loadedData;
                    finishCallback(loadedData);
                });
            } else if (data) {
                finishCallback(data);
            }
        }

        public function loaded(name:String):Boolean {
            return _doHash[name] || (_classHash[name] && !(_classHash[name] is SwfLoader) );
        }

        public function cleanUp(name:String):void {

        }

        public function getSource(name:String):DisplayObject {
            var source:DisplayObject = _doHash[name];
            if (!source) {
                if (_classHash[name] is Bitmap) {
                    source = _classHash[name]
                } else {
                    source = new _classHash[name]();
                }
            }
            if (_cached[name]) {
                _doHash[name] = source;
            }
            return source;
        }

        public function cacheSource(name:String):void {
            _cached[name] = true;
        }

        public function removeSourceFromCache(name:String):void {
            delete _cached[name];
            delete _doHash[name];
        }

        public function getAssetData(query:AssetDataGetQuery):AssetData {
            var assetData:AssetData = findAssetData(query);

            if (!assetData || assetData.isDestroyed) {
                assetData = new AssetData(query);
                if (!query.isBitmapRendering) {
                    assetData.sourceClass = _classHash[query.name];
                }
                assetData.startRender(getRender(assetData));
                addAssetData(assetData);
            } else {
                Pool.put(query);
            }

            return assetData;
        }

        public function createSourceInstance(name:String):DisplayObject {
            return new _classHash[name]();
        }

        protected function getRender(assetData:AssetData):IInstruct {
            var render:BaseDrawInstruct;
            if (assetData.getQuery.sourceType == SourceTypeEnum.SOURCE_PNG) {
                render = new TileDrawInstruct(assetData, assetData.getQuery, getSource(assetData.getQuery.name));
            } else {
                render = new WyseDrawInstruct(assetData, assetData.getQuery, getSource(assetData.getQuery.name) as Sprite);
            }

            return render;
        }

        protected function getUrl(name:String, type:String):String {
            return _baseUrl + name + '.' + type;
        }

        private function addAssetData(assetData:AssetData):void {
            if (!_assets[assetData.getQuery.name]) {
                _assets[assetData.getQuery.name] = [];
            }
            _assets[assetData.getQuery.name].push(assetData);
        }

        private function findAssetData(query:AssetDataGetQuery):AssetData {
            var assetsByName:Array = _assets[query.name];
            var assetData:AssetData;

            for each (var assetDataTemp:AssetData in assetsByName) {
                if (assetDataTemp.getQuery.step == query.step
                        && assetDataTemp.getQuery.text == query.text
                        && assetDataTemp.getQuery.rotate == query.rotate
                        && assetDataTemp.getQuery.position == query.position
                        && assetDataTemp.getQuery.animation == query.animation
                        && assetDataTemp.getQuery.isFullAnimation == query.isFullAnimation
                        ) {
                    assetData = assetDataTemp;
                    break;
                }
            }

            return assetData;
        }

        public function set baseUrl(value:String):void {
            _baseUrl = value;
        }

        public function get dispatcher():SimpleEventDispatcher {
            return _dispatcher;
        }
    }
}

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
        loadSwf(url);
    }

    public function addCallback(callback:Function):void {
        if (callback != null) {
            _callback.push(callback);
        }
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

            for (var i:int = 0; i < _callback.length; i++) {
                _callback[i](data);
            }
        }
        clean();
    }

    private function clean():void {
        contentLoaderInfo.removeEventListener(Event.COMPLETE, complete);
        contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, error);
    }
}
