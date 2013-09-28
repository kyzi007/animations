package com.berry.animation.core {
    import animation.*;
    import com.berry.animation.core.AssetModel;
    import com.berry.animation.library.AnimationLibrary;
    import com.berry.animation.library.AnimationModel;
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetLibrary;

    import flash.display.DisplayObject;
    import flash.display.Sprite;

    import log.logServer.KLog;

    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayProxy;
    import org.dzyga.geom.Rect;

    public class AssetViewNew extends DisplayProxy implements IMidnightView {
        public function AssetViewNew(id:String, name:String) {
            _data.id = id;
            _data.assetName = name;
            super(null);
        }

        private static const _BOUNDS:Rect = new Rect(-40, -40, 80, 80);
        //
        public var cacheAnimationFinishPromise:Promise = new Promise();
        public var loadCompletePromise:Promise;
        //
        internal var _isInit:Boolean;
        internal var _renderListBeforePlay:Array;
        //
        internal var _assetLibrary:AssetLibrary;
        internal var _animationLibrary:AnimationLibrary;
        //
        internal var _mainAspect:IAssetViewAspect;
        internal var _shadowAspect:IAssetViewAspect;
        internal var _effectAspect:IAssetViewAspect;
        //
        internal var _data:AssetModel = new AssetModel();

        override public function hitTest(globalX:int, globalY:int, checkContainer:Boolean = false):Boolean {
            if (!_mainAspect.isRendered) {
                return true;
            } else {
                return _mainAspect.hitTest(globalX, globalY, checkContainer) || (_effectAspect && _effectAspect.hitTest(globalX, globalY, checkContainer));
            }
        }

        public function classicMainAspectInit():AssetViewNew {
            failIfInit();
            _mainAspect = new ClassicMainAspect(this);
            return this;
        }

        public function tileMainAspectInit():AssetViewNew {
            failIfInit();
            _mainAspect = new TileMainAspect(this);
            return this;
        }

        public function shadowAspectInit():AssetViewNew {
            failIfInit();
            _shadowAspect = new ShadowAspect(this);
            return this;
        }

        public function effectAspectInit():AssetViewNew {
            failIfInit();
           // _effectAspect = new EffectAspect(this);
            return this;
        }

        public function init(assetlibrary:AssetLibrary, animationLibrary:AnimationLibrary):void {
            failIfInit();
            _isInit = true;
            CONFIG::debug{
                if (!_mainAspect) {KLog.log("AssetViewNew : init  " + "main view is null", KLog.CRITICAL); }
            }
            if(_effectAspect){
                _view = new Sprite();
                Sprite(_view).addChild(_mainAspect.view);
                Sprite(_view).addChild(_shadowAspect.view);
            } else {
                _view =_mainAspect.view;
            }
            _assetLibrary = assetlibrary;
            _animationLibrary = animationLibrary;
            _assetLibrary.loadData(_data.assetName, _data.sourceType, onLoadCallback);
        }

        public function playByName(animation:String):void {
            _data.animation = animation;
            if (isLoadComplete && _data.visible) {
                playByModel(_animationLibrary.getAnimationModel(_data.assetName, _data.animation, _data.stepFrame));
            }
        }

        public function playByModel(animationModel:AnimationModel):void {
            if (animationModel) {
                _data.animationModel = animationModel;
                _data.animation = animationModel.shotName;

                _mainAspect.play();
                if (_effectAspect) {
                    _effectAspect.play();
                }
                if (_shadowAspect) {
                    _shadowAspect.play();
                }
            } else {
                trace('no animationModel', _data.id);
            }
        }

        private function play():void {
            if (_data.animationModel) {
                playByModel(_data.animationModel);
            } else if (_data.animation) {
                playByName(_data.animation);
            } else {
                playByName(_animationLibrary.defaultAnimation);
            }
        }

        public function get visible():Boolean
        {
            return _data.visible;
        }

        protected function preRenderNext(e:* = null):void {
            var assetData:AssetData;
            if (_renderListBeforePlay) {
                if (_renderListBeforePlay.length == 0) {
                    _renderListBeforePlay = null;
                    cacheAnimationFinishPromise.resolve();
                    if (visible) {
                        play();
                    }
                } else {
                    assetData = _assetLibrary.getAssetData(_data.getQuery(_renderListBeforePlay.shift()));
                    if (assetData.isRenderFinish) {
                        preRenderNext()
                    } else {
                        assetData.completeRenderPromise.callbackRegister(preRenderNext);
                    }
                }
            }

            if (!_renderListBeforePlay) {
                _assetLibrary.removeSourceFromCache(assetName);
            }
        }

        protected function onLoadCallback(data:*, content:*):void {
            _animationLibrary.parseAsset(_data.assetName, _assetLibrary.getSource(_data.assetName));
            if (_animationLibrary.getIsComplexAsset(_data.assetName)) {
                _assetLibrary.registerPartAsset(_data.assetName, content);
            } else {
                if (_renderListBeforePlay) {
                    _assetLibrary.cacheSource(_data.assetName);
                    _renderListBeforePlay = _animationLibrary.getFullNames(assetName, _renderListBeforePlay);
                    preRenderNext();
                }
            }
            if (visible) {
                play();
            }
            loadCompletePromise.resolve();
        }

        protected function failIfInit():void {
            CONFIG::debug{
                if (_isInit) {KLog.log("BaseAssetView : set value  " + "already init", KLog.CRITICAL); }
            }
        }

        public function get assetName():String {
            return _data.assetName;
        }

        /**
         * full names (idle_state_0, idle_state_1_0)
         * @param value
         */
        public function set renderListBeforePlay(value:Array):void {
            failIfInit();
            _renderListBeforePlay = value;
        }

        public function get bounds():Rect {
            if (_mainAspect.isRendered) {
                return _mainAspect.bounds;
            }
            return _BOUNDS;
        }

        public function set visible(value:Boolean):void {
            if (_data.visible != value) {
                _mainAspect.setVisible(value);
                if (_shadowAspect) {
                    _shadowAspect.setVisible(value);
                }
                if (_effectAspect) {
                    _effectAspect.setVisible(value);
                }
            }
        }

        public function get isLoadComplete():Boolean {
            return _assetLibrary.loaded(_data.assetName);
        }

        public function get shadow():DisplayObject {
            return _shadowAspect ? _shadowAspect.view : null;
        }

        public function get boundsUpdatePromise():Promise {
            return _mainAspect.boundsUpdatePromise;
        }

    }
}
