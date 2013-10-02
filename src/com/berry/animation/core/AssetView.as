package com.berry.animation.core {
    import animation.*;

    import com.berry.animation.data.SourceTypeEnum;
    import com.berry.animation.library.AnimationLibrary;
    import com.berry.animation.library.AnimationModel;
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetLibrary;

    import flash.display.DisplayObject;
    import flash.display.Sprite;

    import log.logServer.KLog;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayProxy;
    import org.dzyga.geom.Rect;

    public class AssetView extends DisplayProxy{
        public function AssetView(id:String, name:String) {
            data.id = id;
            data.assetName = name;
            super(null);
        }

        private static const _BOUNDS:Rect = new Rect(-40, -40, 80, 80);
        public var cacheAnimationFinishPromise:Promise = new Promise();
        public var loadCompletePromise:Promise = new Promise();
        //
        private var _assetLibrary:AssetLibrary;
        private var _animationLibrary:AnimationLibrary;
        //
        public var mainAspect:IAssetViewAspect;
        public var shadowAspect:IAssetViewAspect;
        //
        public var effectAspect:IAssetViewAspect;
        public var data:AssetModel = new AssetModel();
        private var _x:int;
        private var _y:int;
        //
        private var _waitPlay:Boolean;
        internal var _isInit:Boolean;
        internal var _renderListBeforePlay:Array;

        // create init preloader, init presets
        override public function hitTest(globalX:int, globalY:int, checkContainer:Boolean = false):Boolean {
            if (!mainAspect.isRendered) {
                return true;
            } else {
                return mainAspect.hitTest(globalX, globalY, checkContainer) || (effectAspect && effectAspect.hitTest(globalX, globalY, checkContainer));
            }
        }

        public function applyFilter(value:ColorMatrix):void {
            mainAspect.applyFilter(value);
            if (effectAspect) {
                effectAspect.applyFilter(value);
            }
        }

        public function removeFilter():void {
            mainAspect.removeFilter();
            if (effectAspect) {
                effectAspect.removeFilter();
            }
        }

        public function classicMainAspectInit():AssetView {
            failIfInit();
            mainAspect = new ClassicMainAspect(this);
            return this;
        }

        public function tileMainAspectInit():AssetView {
            failIfInit();
            mainAspect = new TileViewAspect(this);
            return this;
        }

        public function shadowAspectInit():AssetView {
            failIfInit();
            shadowAspect = new ShadowAspect(this);
            return this;
        }

        public function effectAspectInit():AssetView {
            failIfInit();
            effectAspect = new EffectAspect(this);
            return this;
        }

        public function createSourceInstance():DisplayObject {
            return assetLibrary.createSourceInstance(assetName);
        }

        public function get assetLibrary ():AssetLibrary {
            return _assetLibrary || AnimationManager.ASSET_LIBRARY;
        }

        public function get animationLibrary ():AnimationLibrary {
            return _animationLibrary || AnimationManager.ANIMATION_LIBRARY;
        }

        public function init(assetLibrary:AssetLibrary = null, animationLibrary:AnimationLibrary = null):AssetView {
            failIfInit();
            _isInit = true;
            _assetLibrary = assetLibrary;
            _animationLibrary = animationLibrary;

            mainAspect.init();
            if (effectAspect) {
                effectAspect.init();
            }
            if (shadowAspect) {
                shadowAspect.init();
            }

            if (effectAspect) {
                _view = new Sprite();
                Sprite(_view).addChild(mainAspect.view);
                Sprite(_view).addChild(effectAspect.view);
            } else {
                _view = mainAspect.view;
            }
            this.assetLibrary.loadData(data.assetName, data.sourceType.value, onLoadCallback);
            return this;
        }

        public function playByName(animation:String):void {
            data.animation = animation;
            if (isLoadComplete && data.visible) {
                _waitPlay = false;
                playByModel(_animationLibrary.getAnimationModel(data.assetName, data.animation, data.stepFrame));
            } else {
                _waitPlay = true;
            }
        }

        public function playByModel(animationModel:AnimationModel):void {
            if (animationModel) {
                if (!data.visible) {
                    _waitPlay = true;
                    return;
                }
                _waitPlay = false;
                data.animationModel = animationModel;
                data.animation = animationModel.shotName;

                mainAspect.play();
                if (effectAspect) {
                    effectAspect.play();
                }
                if (shadowAspect) {
                    shadowAspect.play();
                }
            } else {
                trace('no animationModel', data.id);
            }
        }

        public function getAnimationModel(animation:String):AnimationModel {
            return animationLibrary.getAnimationModel(assetName, animation, data.stepFrame);
        }

        public function play():void {
            if (data.animationModel) {
                playByModel(data.animationModel);
            } else if (data.animation) {
                playByName(data.animation);
            } else {
                playByName(animationLibrary.defaultAnimation);
            }
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
                    assetData = assetLibrary.getAssetData(data.getQuery(_renderListBeforePlay.shift()));
                    if (assetData.isRenderFinish) {
                        preRenderNext()
                    } else {
                        assetData.completeRenderPromise.callbackRegister(preRenderNext);
                    }
                }
            }

            if (!_renderListBeforePlay) {
                assetLibrary.removeSourceFromCache(assetName);
            }
        }

        protected function onLoadCallback(source:*, content:*):void {
            animationLibrary.parseAsset(assetName, assetLibrary.getSource(assetName));
            if (animationLibrary.getIsComplexAsset(data.assetName)) {
                assetLibrary.registerPartAsset(data.assetName, source);
            } else {
                if (_renderListBeforePlay) {
                    assetLibrary.cacheSource(data.assetName);
                    _renderListBeforePlay = animationLibrary.getFullNames(assetName, _renderListBeforePlay);
                    preRenderNext();
                }
            }
            loadCompletePromise.resolve();
            if (_waitPlay) {
                play();
            }
        }

        protected function failIfInit():void {
            CONFIG::debug{
                if (_isInit) {KLog.log("BaseAssetView : set value  " + "already init", KLog.CRITICAL); }
            }
        }

        public function set text(value:String):void {
            data.text = value;
        }

        public function get id():String {
            return data.id;
        }

        public function set cachedList(value:Array):void {
            data.cachedList = value;
        }

        public function set cache(value:Boolean):void {
            failIfInit();
            data.cache = value;
        }

        public function get rotation():String {
            return data.rotation;
        }

        public function set rotation(value:String):void {
            data.rotation = value;
            if (data.animationModel
                    && data.animationModel.currentPart()
                    && data.animationModel.currentPart().isRotateSupport(value)) {
                playByModel(data.animationModel);
            }
        }

        public function set animationSpeed(value:Number):void {
            mainAspect.animationSpeed = value;
        }

        public function get visible():Boolean {
            return data.visible;
        }

        public function set visible(value:Boolean):void {
            if (data.visible != value) {
                data.visible = value;
                mainAspect.setVisible(value);
                if (shadowAspect) {
                    shadowAspect.setVisible(value);
                }
                if (effectAspect) {
                    effectAspect.setVisible(value);
                }
                if (_waitPlay) {
                    play();
                }
            }
        }

        public function get assetName():String {
            return data.assetName;
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
            if (mainAspect.isRendered) {
                return mainAspect.bounds;
            }
            return _BOUNDS;
        }

        public function get stepFrame():int {
            return data.stepFrame;
        }

        public function set stepFrame(value:int):void {
            data.stepFrame = value;
        }

        public function set effectMode(value:Boolean):void {
            if (data.effectMode != value && effectAspect) {
                data.effectMode = value;
                effectAspect.play();
            }
        }

        public function get isLoadComplete():Boolean {
            return assetLibrary.loaded(data.assetName);
        }

        public function get shadow():DisplayObject {
            return shadowAspect ? shadowAspect.view : null;
        }

        public function get boundsUpdatePromise():Promise {
            return mainAspect.boundsUpdatePromise;
        }

        public function get x():int {
            return _x;
        }

        public function set x(value:int):void {
            if (effectAspect) {
                _view.x = value;
            } else {
                mainAspect.x = value;
            }
            if (shadowAspect) {
                shadowAspect.x = value;
            }
            _x = value;
        }

        public function get y():int {
            return _y;
        }

        public function set y(value:int):void {
            if(effectAspect){
                _view.y = value;
            } else {
                mainAspect.y = value;
            }
            if (shadowAspect) {
                shadowAspect.y = value;
            }
            _y = value;
        }
    }
}
