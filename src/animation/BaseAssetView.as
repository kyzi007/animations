package animation {
    import animation.event.AssetDataEvents;
    import animation.event.AssetViewEvents;
    import animation.graphic.*;
    import animation.library.AnimationLibrary;
    import animation.library.AssetData;
    import animation.library.SWFLibraryTemp;
    import animation.logic.Generator;

    import dzyga.events.Action;
    import dzyga.events.EnterFrame;
    import dzyga.geom.Rect;
    import dzyga.pool.Pool;

    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.filters.GlowFilter;
    import flash.text.TextField;

    import log.logServer.KLog;

    public class BaseAssetView extends AssetMovieClip {
        public function BaseAssetView(name:String, type:String = AssetTypes.ITEM, baseAnimations:Array = null, text:String = null) {
            super(name, type);
            _generator = new Generator(name, type, isBitmap, text);
            _generator.baseAnimations = baseAnimations;
            setMovieState(AssetViewStateEnum.STATE_PRELOADER);
            SWFLibraryTemp.loadSource(_assetName, url, type, onAssetLoaded);
        }

        private const TEMP_RECT:Rect = new Rect(-50, -50, 100, 100);
        protected var _generator:Generator;
        protected var _state:AssetViewStateEnum = new AssetViewStateEnum();
        protected var _nextAssetData:AssetData;
        protected var _animationQuery:AnimationModel;
        protected var _isLoadComplete:Boolean;
        protected var _rotate:String = RotateEnum.NONE;
        protected var _shadowAssetData:AssetData;
        protected var _preloader:AssetData;
        private var _nextAnimPartShedule:Action;
        private var _isDie:Boolean = false;
        private var _alphaAction:Action;
        private var _targetAlpha:Number;
        private var _startAlpha:Number;
        private var _currentAnimationPreset:AnimationPart;
        private var _isFinishToEndCurrent:Boolean;
        private var _x:int;
        private var _y:int;

        public function showName():void {
            var tf:TextField = new TextField();
            tf.selectable = false;
            tf.y = 20;
            tf.text = _assetName;
            addChild(tf);
        }

        public override function cleanUp():void {
            super.cleanUp();
            _generator.cleanUp();
            _generator.removeAllLoadCallbacks();
            _assetData = null;
            _generator = null;
            _isDie = true;
            clearAssetCallback(_nextAssetData);
        }

        public function getFirstFrameBounds(animation:String = ''):Rect {
            if (!_rect || _state.value == AssetViewStateEnum.STATE_PRELOADER) {
                return TEMP_RECT;
            }
            return _rect;
        }

        /*public function higliteCell(on:Boolean):void {
         if (on) {
         var f:GlowFilter = new GlowFilter(0xffffff * Math.random(), 3, 3, 1, 20, 1, true);
         _bitmap.filters = [f];
         _cell.view.filters = [f];
         if (alpha == 1) {
         alpha = 0.5;
         }
         } else {
         _bitmap.filters = [];
         _cell.view.filters = [];
         alpha = 1;
         }
         }*/

        public override function hitTest(x:Number, y:Number):Boolean {
            return _state.value == AssetViewStateEnum.STATE_PRELOADER ? true : super.hitTest(x, y);
        }

        public function next():void {
            if (_isFinishToEndCurrent) {
                dispatcher.dispatchEvent(AssetViewEvents.ON_ANIMATION_FINISH);
            }
            dispatcher.dispatchEvent(AssetViewEvents.ON_ANIMATION_PART_FINISH);
            _animationQuery.nextPresetRandom();
            setAnimation(_animationQuery);
        }

        public function nextToTime():void {
            CONFIG::debug{ KLog.log("AssetView : nextToTime  ", KLog.DEBUG); }
            stop();
            //next();
        }

        public function playDefault():void {
            setAnimation(AnimationLibrary.getAnimationQueryInstance(assetName, AnimationsList.IDLE));
        }

        public function playSimpleAnimation():void {
            if (_state.value == AssetViewStateEnum.STATE_PLAY) return;
            playDefault();
        }

        public function setAnimation(animationQueryList:AnimationModel):void {
            if (_isDie) {
                return;
            }
            if (animationQueryList == null) {
                return;
            }
            if (_animationQuery != animationQueryList) {
                Pool.put(_animationQuery);
                _animationQuery = animationQueryList;
            }

            _isFinishToEndCurrent = _animationQuery.isListEnd;
            _currentAnimationPreset = _animationQuery._currentPreset();
            _generator.setStep(_animationQuery.step);
            EnterFrame.removeScheduledAction(_nextAnimPartShedule);
            setMovieState(AssetViewStateEnum.STATE_PLAY);
        }

        public function showPivot():void {
            var shape:Shape = new Shape();
            graphics.lineStyle(2, 0, 10);
            graphics.drawCircle(0, 0, 3);
            addChild(shape);
        }

        public function stopAnimation():void {
            //stop();
        }

        public function stopAnimationFromHide():void {
            //stop(true);
        }

        public function setPosition(x:int, y:int):void {
            this.x = x;
            this.y = y;
        }

        protected function clearAssetCallback(assetData:AssetData):void {
            if (assetData) {
                assetData.dispatcher.setEventListener(false, AssetDataEvents.COMPLETE_RENDER, onGenerateOneFrame);
                assetData.dispatcher.setEventListener(false, AssetDataEvents.COMPLETE_RENDER, onGenerateAnimation);
                assetData.dispatcher.setEventListener(false, AssetDataEvents.COMPLETE_RENDER, onGeneratePreloader);
            }
        }

        override protected function finishAnimation():void {
            //super.finishAnimation();
            CONFIG::debug{ KLog.log("AssetView : finishAnimation  ", KLog.DEBUG); }
            next();
        }

        protected function onGenerateAnimation(e:*):void {
            setMovieState(AssetViewStateEnum.STATE_PLAY);
        }

        protected function onGenerateOneFrame(e:*):void {
            setMovieState(AssetViewStateEnum.STATE_STOP);
        }

        protected function onGeneratePreloader(e:*):void {
            if (_state.value == AssetViewStateEnum.STATE_PRELOADER) setMovieState(AssetViewStateEnum.STATE_PRELOADER);
        }

        protected function setMovieState(value:String):void {

            if (_isDie) {
                return;
            }
            if (!_generator.isPreloadAnimations && value != AssetViewStateEnum.STATE_PRELOADER) {
                return;
            }

            _state.setValue(value);
            EnterFrame.removeScheduledAction(_nextAnimPartShedule);

            switch (_state.value) {

                case AssetViewStateEnum.STATE_PRELOADER:
                    _generator.rotationLogicOn = false;
                    _nextAssetData = _preloader; // показываем прелоадер только если он определен сверху
                    if (_nextAssetData) {
                        if (!_nextAssetData.isRenderFinish) {
                            _nextAssetData.dispatcher.setEventListener(true, AssetDataEvents.COMPLETE_RENDER, onGeneratePreloader);
                        } else {
                            if (_assetData) {
                                _nextAssetData.dispatcher.setEventListener(false, AssetDataEvents.COMPLETE_RENDER, onGeneratePreloader);
                            }
                            _assetData = _nextAssetData;
                            _loop = true;
                            gotoAndPlay(0);
                        }
                    }
                    break;

                case AssetViewStateEnum.STATE_PLAY:
                    if (!_isLoadComplete) return;
                    if (!_generator.isPreloadAnimations) {
                        setMovieState(AssetViewStateEnum.STATE_PRELOADER);
                        return;
                    }
                    if (!_animationQuery._currentPreset()) {
                        CONFIG::debug{ KLog.log("AssetView : setMovieState  " + 'invalid animation ' + _assetName + ' ' + _animationQuery.fullPartAnimationName, KLog.CRITICAL); }
                        return;
                    }
                    _generator.rotationLogicOn = _animationQuery._currentPreset().isRotateSupport(_rotate);

                    if (_animationQuery.isFullAnimation) {
                        _nextAssetData = _generator.getAnimation(_animationQuery.fullPartAnimationName, false);
                    } else {
                        _nextAssetData = _generator.getFirstFrame(_animationQuery.fullPartAnimationName);
                    }

                    var shadowAnimationQuery:AnimationModel = AnimationLibrary.getAnimationQueryInstance(_assetName, 'shadow');
                    if (shadowAnimationQuery._currentPreset()) {
                        _generator.rotationLogicOn = shadowAnimationQuery._currentPreset().isRotateSupport(_rotate);

                        var nextShadowAssetData:AssetData = _generator.getAnimation('shadow');
                        if (_shadowAssetData != nextShadowAssetData) {
                            if (_shadowAssetData) _shadowAssetData.dispatcher.clearAllCallbacks();
                            _shadowAssetData = nextShadowAssetData;
                            if (_shadowAssetData.isRenderFinish) {
                                updateShadowFrames();
                            } else {
                                _shadowAssetData.dispatcher.setEventListener(true, AssetDataEvents.COMPLETE_RENDER, updateShadowFrames);
                            }
                        }
                    }

                    if (!_nextAssetData.isRenderFinish) {
                        _nextAssetData.dispatcher.setEventListener(true, AssetDataEvents.COMPLETE_RENDER, onGenerateAnimation);
                        if (!_assetData && _preloader) {
                            setMovieState(AssetViewStateEnum.STATE_PRELOADER);
                        }
                    } else {
                        //clearAssetCallback(_assetData);

                        // TODO fixme
                        if (!_animationQuery._currentPreset()) {
                            next();
                            return;
                        }
                        _assetData = _nextAssetData;
                        var timeToNext:uint = 0;
                        var randomTime:int = _animationQuery._currentPreset().randomTime;
                        if (_animationQuery.loopTime) {
                            timeToNext = _loopTime;
                        } else if (randomTime) {
                            timeToNext = randomTime * Math.random() + randomTime;
                        }

                        if (timeToNext) {
                            _nextAnimPartShedule = EnterFrame.scheduleAction(timeToNext, nextToTime);
                        }

                        if (_objectType != AssetTypes.WORKER && _objectType != AssetTypes.NPC) {
                            setPosition(_x, _y);
                        }

                        _loopCount = _animationQuery.loopCount;
                        _loop = _animationQuery.loopCount == 0;

                        if (_animationQuery.isFullAnimation) {
                            //gotoAndPlay(_animationQuery.startFrame);
                            gotoAndPlay(0);
                        } else {
                            //gotoAndStop(_animationQuery.startFrame);
                            gotoAndStop(0);
                        }

                        if (!timeToNext && !_loopCount) {
                            trace()
                        }

                        CONFIG::debug{ KLog.log("AssetView : setMovieState  " + _animationQuery.fullPartAnimationName + " " + timeToNext + "  " + _loopCount, KLog.DEBUG); }
                    }
                    break;

                case AssetViewStateEnum.STATE_INVALID:
                    setMovieState(AssetViewStateEnum.STATE_PRELOADER);
                    filters = [new GlowFilter(0xfff000, 1, 10, 10, 10, 1, true)];
                    break;
            }
        }

        private function changeAlpha():void {
            if (_targetAlpha > _startAlpha) {
                alpha += 0.08;
                _shadowSprite.alpha = alpha;
                if (alpha > _targetAlpha) {
                    alpha = _targetAlpha;
                    EnterFrame.removeAction(_alphaAction);
                    _alphaAction = null;
                }
            } else {
                alpha -= 0.08;
                _shadowSprite.alpha = alpha;
                if (alpha < _targetAlpha) {
                    alpha = _targetAlpha;
                    EnterFrame.removeAction(_alphaAction);
                    _alphaAction = null;
                }
            }
        }

        private function onAssetLoaded(data:*):void {
            if (_isDie) return;
            _isLoadComplete = true;
            dispatcher.dispatchEvent(AssetViewEvents.ON_LOAD);
            if (_generator.preCache() != 0) {
                _generator.setAllLoadCallback(onRenderFinish);
                dispatcher.dispatchEvent(AssetViewEvents.ON_RENDER);
            } else {
                dispatcher.dispatchEvent(AssetViewEvents.ON_RENDER);
            }
            if (_animationQuery) {
                setAnimation(_animationQuery);
            }
        }

        private function onRenderFinish():void {
            dispatcher.dispatchEvent(AssetViewEvents.ON_RENDER);
            if (!_animationQuery) {
                playDefault();
            } else {
                setMovieState(AssetViewStateEnum.STATE_PLAY);
            }
        }

        private function updateShadowFrames(e:* = null):void {
            setShadowTimline(_shadowAssetData.frames);
        }

        public function set allCache(value:Boolean):void {
            if (value) {
                _generator.preCacheAll();
            }
        }

        public function get animationRendered():Boolean {
            return _state.value == AssetViewStateEnum.STATE_PRELOADER ? false : (_nextAssetData ? _nextAssetData.isRenderFinish : _assetData.isRenderFinish);
        }

        public function get animationStep():uint {return _generator.step;}

        public function get assetComplete():Boolean {
            return true;
        }

        public function get assetName():String {
            return _assetName;
        }

        override public function set x(value:Number):void {
            super.x = _x = value;
        }

        override public function set y(value:Number):void {
            super.y = _y = value;
        }

        public function set contentAlpha(value:Number):void {
            if (alpha == value) return;
            if (_alphaAction) {
                EnterFrame.removeAction(_alphaAction);
            }
            _alphaAction = EnterFrame.addAction(0, changeAlpha);
            _targetAlpha = value;
            _startAlpha = alpha;
        }

        protected function get isBitmap():Boolean {
            return true;
        }

        public function get supportRotateList():Array {
            return _animationQuery._currentPreset().supportRotateList;
        }

        public function get isComplexAnimationPlaying():Boolean {
            return _currentAnimationPreset ? _currentAnimationPreset.complex : false;
        }

        public function get isLoadComplete():Boolean {
            return _isLoadComplete;
        }

        public function get isOnStage():Boolean {
            return _isOnStage;
        }

        public function set isOnStage(value:Boolean):void {
            if (_isOnStage == value) return;
            _isOnStage = value;
        }

        public function get played():Boolean {
            return _state.value != AssetViewStateEnum.STATE_PLAY;
        }

        public function set rotate(value:String):void {
            //if (value == _rotate) return;
            _rotate = value;
            _generator.setRotate(_rotate);
            if (_animationQuery && _animationQuery._currentPreset() && _animationQuery._currentPreset().isRotateSupport(value)) {
                setAnimation(_animationQuery);
            }
        }

        public function get shadow():Sprite {
            return _shadowSprite;
        }

        public function get url():String {
            if (_assetFormat == SOURCE_SWF) {
                return  "" + _assetName + ".swf";
            }
            return  "" + _assetName + ".png";
        }
    }
}
