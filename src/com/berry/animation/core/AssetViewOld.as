package com.berry.animation.core {
    import com.berry.animation.library.AnimationsList;

    import com.berry.animation.data.RotateEnum;
    import com.berry.animation.data.SourceTypeEnum;
    import com.berry.animation.library.AnimationLibrary;
    import com.berry.animation.library.AnimationModel;
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetLibrary;
    import com.berry.events.SimpleEventDispatcher;

    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;

    import log.logServer.KLog;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.geom.Rect;

    public class AssetViewOld {
        public function AssetViewOld(id:String, name:String) {
            _data.id = id;
            _data.assetName = name;
            _main = new AdvancedAssetMovieClip(name);
        }

        public static const ROTATE_NONE:RotateEnum = new RotateEnum(RotateEnum.NONE);
        public static const ROTATE_FLIP:RotateEnum = new RotateEnum(RotateEnum.FLIP);
        public static const SOURCE_PNG:SourceTypeEnum = new SourceTypeEnum(SourceTypeEnum.SOURCE_PNG);
        public static const SOURCE_SWF:SourceTypeEnum = new SourceTypeEnum(SourceTypeEnum.SOURCE_SWF);
        private const BOUNDS:Rect = new Rect(-40, -40, 80, 80);
        public var dispatcher:SimpleEventDispatcher = new SimpleEventDispatcher();

        // Promises
        public var boundsUpdatePromise:Promise = new Promise();
        public var cacheAnimationFinishPromise:Promise = new Promise();
        public var loadCompletePromise:Promise = new Promise();
        protected var _isInit:Boolean;
        protected var _data:AssetModel = new AssetModel();
        protected var _shadow:AssetMovieClip = new AssetMovieClip("shadow");
        protected var _effects:Array = [];
        protected var _preloader:AssetMovieClip = new AssetMovieClip("preloader");
        protected var _assetLibrary:AssetLibrary;
        protected var _animationLibrary:AnimationLibrary;
        protected var _main:AdvancedAssetMovieClip; // advanced animation control (play preset list)
        protected var _renderListBeforePlay:Array;
        protected var _renderListFromMainController:Array;
        protected var _mainSprite:Sprite = new Sprite();
        protected var _preloaderMode:Boolean = true;

        public function playByName(animation:String):void {
            _data.animation = animation;
            if (isLoadComplete && _data.visible) {
                playByModel(_animationLibrary.getAnimationModel(name, _data.animation, _data.stepFrame));
            }
        }

        public function getSource():DisplayObject {
            return _assetLibrary.getSource(name);
        }

        public function createSourceInstance():DisplayObject {
            return _assetLibrary.createSourceInstance(name);
        }

        public function playByModel(animationModel:AnimationModel):void {
            if (animationModel) {
                _data.animationModel = animationModel;
                _data.animation = animationModel.shotName;
                if (!isPreRenderStatus && _data.visible) {
                    updateMain();
                    updateShadow();
                    updateEffects();
                    _data.clearUpdates();
                }
            } else {
                trace('no animationModel', id)
            }
        }

        public function init():void {
            failIfInit();
            _isInit = true;

            CONFIG::debug{
                if (!_assetLibrary || !_animationLibrary) { KLog.log("AssetMediator : init  " + "no data", KLog.CRITICAL); }
            }
            _main.assetLibrary = _assetLibrary;
            _main.data = _data;

            _main.assetMovieClip.boundsUpdatePromise.callbackRegister(onUpdateBounds);

            _mainSprite.addChild(_preloader);
            _mainSprite.addChild(_main.assetMovieClip);

            _assetLibrary.loadData(name, _data.sourceType, onLoadCallback);
        }

        public function getAnimationModel(animation:String):AnimationModel {
            return _animationLibrary.getAnimationModel(name, animation, _data.stepFrame);
        }

        public function cleanUp():void {
            _main.clear();
            _shadow.clear();
            for each (var effect:AdvancedAssetMovieClip in _effects) {
                effect.clear();
            }
            _assetLibrary.cleanUp(name);
            _data.cleanUp();
        }

        public function hitTest(x:Number, y:Number):Boolean {
            return _main.isActive ? _main.hitTest(x, y) : _preloader && _preloader.visible;
        }

        public function applyFilter(value:ColorMatrix):void {
            _main.applyFilter(value);
        }

        public function removeFilter():void {
            _main.removeFilter();
            if (_preloader) {
                _preloader.removeFilter();
            }
            for each (var effect:AssetMovieClip in _effects) {
                effect.removeFilter();
            }
        }

        public function showPivot():void {
            _main.showPivot();
        }

        public function totalFrame():void {
            _data.animationModel ? _data.animationModel.totalFrame : 0;
        }

        protected function preloaderHide(...params):void {
            if (!_renderListBeforePlay && _preloader && _preloader.assetData) {
                // trace(id, 'hidePreloader')
                _main.renderCompletePromise.callbackRemove(preloaderHide);
                boundsUpdatePromise.callbackRemove(preloaderHide);
                _preloader.assetData.completeRenderPromise.callbackRegister(onPreloaderRender);
                _preloader.stop(true);
                _preloader.assetData = null;
                _preloader.setVisible(false);
                //_preloader = null;
            }
        }

        protected function updateEffects():void {
            //clear old
            if (!_data.animationModel || !mainSprite) {
                return;
            }
            var effect:AdvancedAssetMovieClip;
            for each (effect in _effects) {
                effect.clear();
                mainSprite.removeChild(effect.assetMovieClip);
            }
            _effects = [];
            if (_data.rotation.value == RotateEnum.NONE) {
                var effectModels:Object = _animationLibrary.getAnimationEffects(_data.assetName, _data.animationModel.currentPart().fullName, _data.stepFrame);
                for each (var animationModel:AnimationModel in effectModels) {
                    effect = new AdvancedAssetMovieClip(_data.assetName + 'effect');
                    effect.assetLibrary = _assetLibrary;
                    effect.data = _data;
                    effect.fullAnimation = _data.effectMode;
                    effect.loadOneFrameFirst = true;
                    effect.playAnimationSet(animationModel);
                    _effects.push(effect);
                    mainSprite.addChild(effect.assetMovieClip);
                }
            }
        }

        protected function updateMain():void {
            _main.playAnimationSet(_data.animationModel);
            if (!_main._assetMovieClip.assetData) {
                preloaderShow();
            }
        }

        protected function updateShadow():void {
            var assetDataFromShadow:AssetData = _assetLibrary.getAssetData(_data.getQuery(AnimationsList.SHADOW));
            if (assetDataFromShadow.isRenderFinish) {
                shadowAssetOnRender(assetDataFromShadow);
            } else {
                assetDataFromShadow.completeRenderPromise.callbackRegister(shadowAssetOnRender);
            }
        }

        protected function shadowAssetOnRender(data:* = null):void {
            var assetDataFromShadow:AssetData = _assetLibrary.getAssetData(_data.getQuery(AnimationsList.SHADOW));
            _shadow.assetData = assetDataFromShadow;
            _shadow.gotoAndStop(0);
        }

        protected function preRenderNext(e:* = null):void {
            var assetData:AssetData;
            if (_renderListBeforePlay) {
                if (_renderListBeforePlay.length == 0) {
                    _renderListBeforePlay = null;
                    cacheAnimationFinishPromise.resolve();
                    preloaderHide();

                    if (visible) {
                        play();
                    }
                    dispatcher.dispatchEvent('init');
                    if (_renderListFromMainController) {
                        preRenderNext();
                    }
                } else {
                    assetData = _assetLibrary.getAssetData(_data.getQuery(_renderListBeforePlay.shift()));
                    if (assetData.isRenderFinish) {
                        preRenderNext()
                    } else {
                        assetData.completeRenderPromise.callbackRegister(preRenderNext);
                    }
                }
            } else if (_renderListFromMainController) {
                if (_renderListFromMainController.length == 0) {
                    _renderListFromMainController = null;
                } else {
                    assetData = _assetLibrary.getAssetData(_data.getQuery(_renderListFromMainController.shift()));
                    if (assetData.isRenderFinish) {
                        preRenderNext()
                    } else {
                        assetData.completeRenderPromise.callbackRegister(preRenderNext);
                    }
                }
            }

            if (!_renderListFromMainController && !_renderListBeforePlay) {
                _assetLibrary.removeSourceFromCache(name);
            }
        }

        protected function onLoadCallback(data:*, content:*):void {
            _animationLibrary.parseAsset(name, _assetLibrary.getSource(name));
            if (_animationLibrary.getIsComplexAsset(name)) {
                _assetLibrary.registerPartAsset(name, content);
            } else {
                if (_renderListBeforePlay || _renderListFromMainController) {
                    _assetLibrary.cacheSource(name);
                    _renderListBeforePlay = updatePreRenderList(_renderListBeforePlay);
                    _renderListFromMainController = updatePreRenderList(_renderListFromMainController);
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

        private function play():void {
            if (_data.animationModel) {
                playByModel(_data.animationModel);
            } else if (_data.animation) {
                playByName(_data.animation);
            } else {
                playByName(_animationLibrary.defaultAnimation);
            }
        }

        private function onUpdateBounds(...args):void {
            boundsUpdatePromise.resolve(this);
        }

        private function updatePreRenderList(list:Array):Array {
            var tempArray:Array;
            if (list) {
                tempArray = []
                for each (var animationShotName:String in list) {
                    var animationModel:AnimationModel = _animationLibrary.getAnimationModel(name, animationShotName);
                    if (animationModel) {
                        //while (!animationModel.isListEnd) {
                        tempArray.push(animationModel.fullPartAnimationName);
                        // animationModel.nextPreset();
                        // }
                    }
                }
                if (tempArray.length == 0) tempArray = null;
            }
            return tempArray;
        }

        private function onPreloaderRender(e:* = null):void {
            _assetLibrary.dispatcher.setEventListener(false, AssetLibrary.ON_INIT, onPreloaderRender);
            if (!_main.assetMovieClip.assetData || _renderListBeforePlay) {
                _preloader.assetData = _assetLibrary.getPreloader(name);
                _preloader.gotoAndPlay(0);
            }
        }

        private function preloaderShow():void {
            if (!_data.vectorMode && _preloaderMode) {
                //trace(id,  'preloaderShow')
                _main.renderCompletePromise.callbackRegister(preloaderHide);
                boundsUpdatePromise.callbackRegister(preloaderHide);
                _preloader.assetData = _assetLibrary.getPreloader(name);
                _preloader.y = -50;
                _preloader.setVisible(_data.visible);
                if (!_preloader.assetData) {
                    _assetLibrary.dispatcher.setEventListener(true, AssetLibrary.ON_INIT, onPreloaderRender);
                }
                else if (!_preloader.assetData.isRenderFinish) {
                    _preloader.assetData.completeRenderPromise.callbackRegister(onPreloaderRender);
                }
                else {
                    _preloader.gotoAndPlay(0);
                }
            }
        }

        public function set assetLibrary(value:AssetLibrary):void {
            failIfInit();
            _assetLibrary = value;
        }

        public function set animationLibrary(value:AnimationLibrary):void {
            failIfInit();
            _animationLibrary = value;
        }

        public function get main():AdvancedAssetMovieClip {
            return _main;
        }

        /**
         * full names (idle_state_0, idle_state_1_0)
         * @param value
         */
        public function set renderListBeforePlay(value:Array):void {
            failIfInit();
            _renderListBeforePlay = value;
        }

        public function set renderListFromMainController(value:Array):void {
            failIfInit();
            _renderListFromMainController = value;
        }

        public function get mainSprite():DisplayObjectContainer {
            return _mainSprite;
        }

        public function set preloaderMode(preloaderMode:Boolean):void {_preloaderMode = preloaderMode;}

        public function set renderInTread(value:Boolean):void {
            _data.renderInTread = value;
        }

        public function set cachedList(value:Array):void {
            _data.cachedList = value;
        }

        public function get isLoadComplete():Boolean {
            return _assetLibrary.loaded(name);
        }

        public function get visible():Boolean {
            return _data.visible;
        }

        public function set visible(value:Boolean):void {
            if (_data.visible != value) {
                _data.visible = value;
                _main.setVisible(value);
                _shadow.setVisible(value);
                if (_preloader) {
                    _preloader.setVisible(value);
                }
                for each (var effect:AdvancedAssetMovieClip in _effects) {
                    effect.setVisible(value);
                }
                if (value) {
                    if (_assetLibrary.loaded(_data.assetName)) {
                        play();
                    } else {
                        preloaderShow();
                    }
                }
            }
        }

        public function get isPreRenderStatus():Boolean {
            return _renderListBeforePlay != null;
        }

        public function set effectMode(value:Boolean):void {
            if (_data.effectMode != value) {
                //trace('set effectMode', value, _data.name)
                _data.effectMode = value;
                updateEffects();
            }
        }

        public function set vectorMode(value:Boolean):void {
            _data.vectorMode = value;
        }

        public function get shadowSprite():DisplayObjectContainer {
            return _shadow;
        }

        public function get x():Number {
            return _data.x;
        }

        public function set x(value:Number):void {
            _data.x = value;
            mainSprite.x = value;
            shadowSprite.x = value;
        }

        public function get y():Number {
            return _data.y;
        }

        public function set y(value:Number):void {
            _data.y = value;
            mainSprite.y = value;
            shadowSprite.y = value;
        }

        public function get isComplexAnimationPlaying():Boolean {
            return _main.animationModel ? _main.animationModel.currentPart().complex : false;
        }

        public function set cache(value:Boolean):void {
            failIfInit();
            _data.cache = value;
        }

        public function get bounds():Rect {
            if (!_main.bounds) {
                return BOUNDS;
            }
            return _main.bounds;
        }

        public function get name():String {
            return _data.assetName;
        }

        public function set text(value:String):void {
            _data.text = value;
        }

        public function get id():String {
            return _data.id;
        }

        public function get rotation():RotateEnum {
            return _data.rotation;
        }

        public function set rotation(value:RotateEnum):void {
            _data.rotation = value;
            if (_data.animationModel
                    && _data.animationModel.currentPart()
                    && _data.animationModel.currentPart().isRotateSupport(value.value)) {
                playByModel(_data.animationModel);
            }
        }

        public function set sourceType(value:SourceTypeEnum):void {
            _data.sourceType = value;
        }

        public function get stepFrame():int {
            return _data.stepFrame;
        }

        public function set stepFrame(value:int):void {
            _data.stepFrame = value;
        }

        public function set animationSpeed(value:Number):void {
            _main.speed = value;
            for each (var effect:AdvancedAssetMovieClip in _effects) {
                effect.speed = value;
            }
        }
    }
}
