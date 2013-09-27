package com.berry.animation.library {
    import com.berry.animation.data.AnimationSettings;
    import com.berry.animation.data.SourceTypeEnum;
    import com.berry.animation.draw.BaseDrawInstruct;
    import com.berry.animation.draw.TileDrawInstruct;
    import com.berry.animation.draw.WyseDrawInstruct;
    import com.berry.events.SimpleEventDispatcher;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.LoaderInfo;
    import flash.display.Sprite;
    import flash.net.SharedObject;

    import org.dzyga.events.EnterFrame;
    import org.dzyga.events.IInstruct;
    import org.dzyga.pool.Pool;

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
        private var _partAsset:Object = {};

        public function gcForce():void {
            for (var assetsName:String in _assets) {
                var assetsByName:Array = _assets[assetsName];
                var count:int = 0;
                for each (var assetData:AssetData in assetsByName) {
                    // if not playing and rendering
                    if (assetData.useCount == 0) {
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

        public function init():void {
            // for override
            EnterFrame.scheduleAction(10000, gc);
        }

        public function getPreloader(assetName:String):AssetData {
            // for override
            return null;
        }

        public function registerAsset(data:*, assetName:String, loaderInfo:LoaderInfo):void {
            if (data is Bitmap) {
                _doHash[assetName] = data;
            } else {
                _classHash[assetName] = data;
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
            var data:* = _classHash[name] || _doHash[name];

            if (!data) {
                var loader:AssetLoader = new AssetLoader(name, getUrl(name, type.value), null);
                _classHash[name] = loader;
                loader.addCallback(function (loadedData:*, loaderContext:*):void {
                    registerAsset(loadedData, name, loaderContext);
                    finishCallback(loadedData, loaderContext);
                });
            } else if (data is AssetLoader) {
                AssetLoader(data).addCallback(function (loadedData:*, loaderContext:*):void {
                    finishCallback(loadedData, loaderContext);
                });
            } else if (data) {
                finishCallback(data, _partAsset[name]);
            }
        }

        public function loaded(name:String):Boolean {
            return _doHash[name] || (_classHash[name] && !(_classHash[name] is AssetLoader) );
        }

        public function cleanUp(name:String):void {

        }

        public function getSource(name:String):DisplayObject {
            var source:DisplayObject = _doHash[name];
            if (!source) {
                if (_classHash[name] is Bitmap) {
                    source = _doHash[name] || _classHash[name];// fix me
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

        public function getAssetData(query:AssetDataGetQuery, renderProps:Array = null):AssetData {
            var assetData:AssetData = findAssetData(query);

            if (!assetData || assetData.isDestroyed) {
                assetData = new AssetData();
                assetData.renderInitParams = renderProps;
                assetData.getQuery = query;

                //classic render
                if(!_partAsset[query.name]){
                    assetData.startRender(getRender(assetData));
                } else {
                    var mcClass:Class = _partAsset[query.name].applicationDomain.getDefinition(query.name + '__' + query.step + '__'+ query.animation) as Class;
                    assetData.mc = new mcClass;
                    assetData.mc.cacheAsBitmap = true;
                    assetData.finishRender();
                }
                addAssetData(assetData);
            } else {
                Pool.put(query);
            }

            return assetData;
        }

        public function assetRendered(query:AssetDataGetQuery):Boolean {
            var assetData:AssetData = findAssetData(query);

            if (!assetData || assetData.isDestroyed) {
                return false;
            }
            return assetData.isRenderFinish;
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

        public function getUrl(name:String, type:String):String {
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

            if(!assetData && AnimationSettings.saveMode && SharedObject.getLocal('midnight_').data['assets']){

                var frames:* = SharedObject.getLocal('midnight_').data['assets'][query.toString()];
                if(frames){
                    assetData = new AssetData(query);
                    assetData.unpackSavedFrames(frames);
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

        public function registerPartAsset(name:String, content:*):void {
            _partAsset[name] = content;
        }
    }
}
