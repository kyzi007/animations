package com.berry.animation.library {
    import com.berry.animation.data.SourceTypeEnum;
    import com.berry.animation.draw.TileDrawInstruct;
    import com.berry.animation.draw.WyseDrawInstruct;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.LoaderInfo;

    import org.dzyga.eventloop.Loop;
    import org.dzyga.events.EnterFrame;
    import org.dzyga.pool.Pool;

    public class AssetLibrary {
        public function AssetLibrary (baseUrl:String) {
            _baseUrl = baseUrl;
        }

        public static const ON_INIT:String = 'init';
        protected var _assets:Object = {};
        protected var _doHash:Object = {};
        protected var _classHash:Object = {};
        private var _baseUrl:String;
        private var _cached:Object = {};
        private var _partAsset:Object = {};
        private var _loop:Loop;
        private var _tempHash:Object = {};


        public function assetDataExistAndRendered(query:AssetDataGetQuery):Boolean{
            var assetData:AssetData = findAssetData(query);
            return assetData && assetData.isRenderFinish;
        }

        public function gcForce ():void {
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
                    delete _cached[assetsName];
                    if (!(_doHash is Bitmap)) {
                        delete _doHash[assetsName];
                    }
                }
            }
        }

        public function init ():void {
            EnterFrame.scheduleAction(60000, gc);
        }

        public function getPreloader (assetName:String):AssetData {
            // for override
            return null;
        }

        public function registerAsset (data:*, assetName:String, loaderInfo:LoaderInfo):void {
            if (data is Bitmap) {
                _doHash[assetName] = data;
            } else {
                _classHash[assetName] = data;
            }
        }

        public function gc ():void {
            EnterFrame.scheduleAction(20000, gc);
            if (EnterFrame.calculatedFps < 15) {
                return;
            }
//            trace('GC RUN')
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
//                    trace('GC, delete ' + assetsName);
                    delete _cached[assetsName];
                    if (!(_doHash is Bitmap)) {
                        delete _doHash[assetsName];
                    }
                }
            }
            _tempHash = {};
        }

        public function loadData (name:String, type:String, finishCallback:Function):void {
            var data:* = _classHash[name] || _doHash[name] || _tempHash[name];

            if (!data) {
                var loader:AssetLoader = new AssetLoader(name, getUrl(name, type));
                _classHash[name] = loader;
                loader.completePromise.callbackRegister(
                    function (loadedData:*, loaderContext:*):void {
                        registerAsset(loadedData, name, loaderContext);
                        finishCallback(loadedData, loaderContext);
                    }
                )
            } else if (data is AssetLoader) {
                AssetLoader(data).completePromise.callbackRegister(function (loadedData:*, loaderContext:*):void {
                    finishCallback(loadedData, loaderContext);
                });
            } else if (data) {
                finishCallback(data, _partAsset[name]);
            }
        }

        public function loaded (name:String):Boolean {
            return _tempHash[name] || _doHash[name] || (_classHash[name] && !(_classHash[name] is AssetLoader) );
        }

        public function getSource (name:String):DisplayObject {
            var source:DisplayObject = _doHash[name] || _tempHash[name];
            if (!source) {
                if (_classHash[name] is Bitmap) {
                    source = _doHash[name] || _classHash[name];// fix me
                } else {
                    _tempHash[name] = source = new _classHash[name]();
                }
            }
            return source;
        }

        public function getAndInitAssetData (query:AssetDataGetQuery, renderProps:Array = null):AssetData {
            var assetData:AssetData = findAssetData(query);

            if (!assetData || assetData.isDestroyed) {
                assetData = new AssetData();
                assetData.renderInitParams = renderProps;
                assetData.getQuery = query;
                assetData.renderClass = getRender(assetData);
                assetData.sourceCallback = getSource;
                var data:* = _classHash[query.name] || _doHash[query.name] || _tempHash[query.name];
                if (data is AssetLoader) {
                    AssetLoader(data).completePromise.callbackRegister(assetData.startRender);
                } else if (!data) {
                    loadData(query.name, query.sourceType, assetData.startRender);
                } else {
                    assetData.startRender();
                }
                addAssetData(assetData);
            } else {
                Pool.put(query);
            }

            return assetData;
        }

        public function createSourceInstance (name:String):DisplayObject {
            _tempHash[name] = _classHash[name] ? new _classHash[name]() : _doHash[name];
            return _tempHash[name];
        }

        protected function getRender (assetData:AssetData):Class {
            if (assetData.getQuery.sourceType == SourceTypeEnum.SOURCE_PNG) {
                return TileDrawInstruct;
            } else {
                return WyseDrawInstruct;
            }
        }

        public function getUrl (name:String, type:String):String {
            return _baseUrl + name + '.' + type;
        }

        private function addAssetData (assetData:AssetData):void {
            if (!_assets[assetData.getQuery.name]) {
                _assets[assetData.getQuery.name] = [];
            }
            _assets[assetData.getQuery.name].push(assetData);
        }

        private function findAssetData (query:AssetDataGetQuery):AssetData {
            var assetsByName:Array = _assets[query.name];
            var assetData:AssetData;

            for each (var assetDataTemp:AssetData in assetsByName) {
                if (assetDataTemp.getQuery.step == query.step
                    && assetDataTemp.getQuery.animation == query.animation
                    && assetDataTemp.getQuery.isFullAnimation == query.isFullAnimation
                    && assetDataTemp.getQuery.text == query.text
                    && assetDataTemp.getQuery.rotate == query.rotate
                    && assetDataTemp.getQuery.position == query.position
                    ) {
                    assetData = assetDataTemp;
                    break;
                }
            }

            return assetData;
        }

        public function set baseUrl (value:String):void {
            _baseUrl = value;
        }

        public function registerPartAsset (name:String, content:*):void {
            _partAsset[name] = content;
        }

        public function get loop ():Loop {
            return _loop;
        }
    }
}
