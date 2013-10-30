package com.berry.animation.core {
    import com.berry.animation.core.components.BodyMovieComponent;
    import com.berry.animation.core.components.BodyTileComponent;
    import com.berry.animation.core.components.EffectComponent;
    import com.berry.animation.core.components.ShadowComponent;
    import com.berry.animation.library.AnimationLibrary;
    import com.berry.animation.library.AnimationSequenceData;
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
        public function AssetView(viewID:String, assetName:String) {
            data.id = viewID;
            data.assetName = assetName;
            super(null);
        }

        private static const _BOUNDS:Rect = new Rect(-40, -40, 80, 80);
        public var cacheAnimationFinishPromise:Promise = new Promise();
        public var loadCompletePromise:Promise = new Promise();
        //
        protected var _assetLibrary:AssetLibrary;
        protected var _animationLibrary:AnimationLibrary;
        //
        public var mainComponent:IAssetViewComponent;
        public var shadowComponent:IAssetViewComponent;
        //
        public var effectComponent:IAssetViewComponent;
        public var data:AssetModel = new AssetModel();
        //
        internal var _isInit:Boolean;
        internal var _renderListBeforePlay:Array;
        private var _lock:Boolean;

        // create init preloader, init presets
        override public function hitTest(globalX:int, globalY:int):Boolean {
            if (!mainComponent.isRendered) {
                return true;
            } else {
                return mainComponent.hitTest(globalX, globalY) || (effectComponent && effectComponent.hitTest(globalX, globalY));
            }
        }

        public function applyFilter(value:ColorMatrix):void {
            mainComponent.applyFilter(value);
            if (effectComponent) {
                effectComponent.applyFilter(value);
            }
        }

        public function removeFilter():void {
            mainComponent.removeFilter();
            if (effectComponent) {
                effectComponent.removeFilter();
            }
        }

        public function classicMainAspectInit():AssetView {
            failIfInit();
            mainComponent = new BodyMovieComponent(this);
            return this;
        }

        public function tileMainAspectInit():AssetView {
            failIfInit();
            mainComponent = new BodyTileComponent(this);
            return this;
        }

        public function shadowAspectInit():AssetView {
            failIfInit();
            shadowComponent = new ShadowComponent(this);
            return this;
        }

        public function effectAspectInit():AssetView {
            failIfInit();
            effectComponent = new EffectComponent(this);
            return this;
        }

        public function createSourceInstance():DisplayObject {
            return assetLibrary.createSourceInstance(assetName);
        }

        public function getComponentList():Array {
            var aspectList:Array = [];
            if (mainComponent) {
                aspectList.push(mainComponent);
            }
            if (shadowComponent) {
                aspectList.push(shadowComponent);
            }
            if (effectComponent) {
                aspectList.push(effectComponent);
            }
            return aspectList;
        }

        public function getComponentViewList():Array {
            var viewList:Array = [];
            if (effectComponent) {
                viewList.push(_view);
            } else {
                viewList.push(mainComponent.view);
            }
            if (shadowComponent) {
                viewList.push(shadowComponent.view);
            }
            return viewList;
        }

        public function get assetLibrary():AssetLibrary {
            return _assetLibrary;
        }

        public function get animationLibrary():AnimationLibrary {
            return _animationLibrary;
        }

        public function init(assetLibrary:AssetLibrary = null, animationLibrary:AnimationLibrary = null):AssetView {
            failIfInit();
            _isInit = true;
            _assetLibrary = assetLibrary;
            _animationLibrary = animationLibrary;

            ArrayUtils.map(getComponentList(), 'init');

            if (effectComponent) {
                _view = new Sprite();
                Sprite(_view).addChild(mainComponent.view);
                Sprite(_view).addChild(effectComponent.view);
            } else {
                _view = mainComponent.view;
            }
            this.assetLibrary.loadData(data.assetName, data.sourceType.value, onLoadCallback);
            return this;
        }

        public function playByName(animation:String):void {
            data.animation = animation;
            if (isLoadComplete) {
                playByModel(animationLibrary.getAnimationModel(data.assetName, data.animation, data.stepFrame));
            }
        }

        public function playByModel(animationModel:AnimationSequenceData):void {
            if (animationModel) {
                data.animationModel = animationModel;
                data.animation = animationModel.animationShotName;
                ArrayUtils.map(getComponentList(), 'play');
            } else {
                trace('no animationModel', data.id);
            }
        }

        public function getAnimationModel(animation:String):AnimationSequenceData {
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
                    play();
                } else {
                    assetData = assetLibrary.getAssetData(data.getQueryByName(_renderListBeforePlay.shift()));
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
                play();
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
            mainComponent.animationSpeed = value;
        }

        public function renderLock():void {
            _lock = true;
        }

        public function renderUnLock():void {
            _lock = false;
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
            if (mainComponent.isRendered) {
                return mainComponent.bounds;
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
            if (data.effectMode != value && effectComponent) {
                data.effectMode = value;
                effectComponent.play();
            }
        }

        public function get isLoadComplete():Boolean {
            return assetLibrary.loaded(data.assetName);
        }

        public function get shadow():DisplayObject {
            return shadowComponent ? shadowComponent.view : null;
        }

        public function get boundsUpdatePromise():Promise {
            return mainComponent.boundsUpdatePromise;
        }

        public function get x():int {
            return view.x;
        }

        public function set x(value:int):void {
            for each (var aspectView:DisplayObject in getComponentViewList()) {
                aspectView.x = value;
            }
        }

        public function get y():int {
            return view.y;
        }

        public function set y(value:int):void {
            for each (var aspectView:DisplayObject in getComponentViewList()) {
                aspectView.y = value;
            }
        }

        override public function moveTo(x:Number, y:Number, truncate:Boolean = false):IDisplayProxy {
            this.x = truncate ? int(x) : x;
            this.y = truncate ? int(y) : y;
            return this;
        }

        public function set smoothing(value:Boolean):void {
            for each (var assetViewComponent:IAssetViewComponent in getComponentList()) {
                assetViewComponent.smoothing = value;
            }
        }
        
        override public function match(target:DisplayObject):IDisplayProxy {
            ArrayUtils.map(getComponentViewList(), DisplayUtils.scale, null, target);
            return this;
        }

        override public function scale(scaleX:Number, scaleY:Number = NaN):IDisplayProxy {
            ArrayUtils.map(getComponentViewList(), DisplayUtils.scale, null, scaleX, scaleY);
            return this;
        }

        override public function offset(dx:Number, dy:Number, truncate:Boolean = false):IDisplayProxy {
            ArrayUtils.map(getComponentViewList(), DisplayUtils.offset, null, dx, dy, truncate);
            return this;

        }

        override public function show():IDisplayProxy {
            ArrayUtils.map(getComponentViewList(), DisplayUtils.show);
            return this;
        }

        override public function hide():IDisplayProxy {
            ArrayUtils.map(getComponentViewList(), DisplayUtils.hide);
            return this;
        }

        override public function toggle():IDisplayProxy {
            ArrayUtils.map(getComponentViewList(), DisplayUtils.toggle);
            return this;
        }

        override public function detach():IDisplayProxy {
            ArrayUtils.map(getComponentViewList(), DisplayUtils.detach);
            return this;
        }

        override public function alpha(alpha:Number = 1):IDisplayProxy {
            ArrayUtils.map(getComponentViewList(), DisplayUtils.alpha);
            return this;
        }

        override public function removeChild(child:DisplayObject):IDisplayProxy {
            return super.removeChild(child);
        }
    }
}
