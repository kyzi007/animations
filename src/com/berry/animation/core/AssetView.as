package com.berry.animation.core {
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
    import org.dzyga.display.DisplayUtils;
    import org.dzyga.display.IDisplayProxy;
    import org.dzyga.geom.Rect;
    import org.dzyga.utils.ArrayUtils;

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
        protected var _assetLibrary:AssetLibrary;
        protected var _animationLibrary:AnimationLibrary;
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
        override public function hitTest (globalX:int, globalY:int):Boolean {
            if (!mainAspect.isRendered) {
                return true;
            } else {
                return mainAspect.hitTest(globalX, globalY) || (effectAspect && effectAspect.hitTest(globalX, globalY));
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

        public function getAspectList ():Array {
            var aspectList:Array = [];
            if (mainAspect) {
                aspectList.push(mainAspect);
            }
            if (shadowAspect) {
                aspectList.push(shadowAspect);
            }
            if (effectAspect) {
                aspectList.push(effectAspect);
            }
            return aspectList;
        }

        public function getAspectViewList ():Array {
            var viewList:Array = [];
            if (effectAspect) {
                viewList.push(_view);
            } else {
                viewList.push(mainAspect.view);
            }
            if (shadowAspect) {
                viewList.push(shadowAspect.view);
            }
            return viewList;
        }

        public function get assetLibrary ():AssetLibrary {
            return _assetLibrary;
        }

        public function get animationLibrary ():AnimationLibrary {
            return _animationLibrary;
        }

        public function init(assetLibrary:AssetLibrary = null, animationLibrary:AnimationLibrary = null):AssetView {
            failIfInit();
            _isInit = true;
            _assetLibrary = assetLibrary;
            _animationLibrary = animationLibrary;

            ArrayUtils.map(getAspectList(), 'init');

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

                ArrayUtils.map(getAspectList(), 'play');
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
            return view.x;
        }

        public function set x (value:int):void {
            for each (var aspectView:DisplayObject in getAspectViewList()) {
                aspectView.x = value;
            }
        }

        public function get y():int {
            return view.y;
        }

        public function set y(value:int):void {
            for each (var aspectView:DisplayObject in getAspectViewList()) {
                aspectView.y = value;
            }
        }

        override public function moveTo (x:Number, y:Number, truncate:Boolean = false):IDisplayProxy {
            this.x = truncate ? int(x) : x;
            this.y = truncate ? int(y) : y;
            return this;
        }

        override public function match (target:DisplayObject):IDisplayProxy {
            ArrayUtils.map(getAspectViewList(), DisplayUtils.scale, null, target);
            return this;
        }

        override public function scale (scaleX:Number, scaleY:Number = NaN):IDisplayProxy {
            ArrayUtils.map(getAspectViewList(), DisplayUtils.scale, null, scaleX, scaleY);
            return this;
        }

        override public function offset (dx:Number, dy:Number, truncate:Boolean = false):IDisplayProxy {
            ArrayUtils.map(getAspectViewList(), DisplayUtils.offset, null, dx, dy, truncate);
            return this;

        }

        override public function show ():IDisplayProxy {
            ArrayUtils.map(getAspectViewList(), DisplayUtils.show);
            return this;
        }

        override public function hide ():IDisplayProxy {
            ArrayUtils.map(getAspectViewList(), DisplayUtils.hide);
            return this;
        }

        override public function toggle ():IDisplayProxy {
            ArrayUtils.map(getAspectViewList(), DisplayUtils.toggle);
            return this;
        }

        override public function detach ():IDisplayProxy {
            ArrayUtils.map(getAspectViewList(), DisplayUtils.detach);
            return this;
        }

        override public function alpha (alpha:Number = 1):IDisplayProxy {
            ArrayUtils.map(getAspectViewList(), DisplayUtils.alpha);
            return this;
        }


        override public function removeChild (child:DisplayObject):IDisplayProxy {
            return super.removeChild(child);
        }
    }
}
