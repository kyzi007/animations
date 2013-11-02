package com.berry.animation.core.view {
    import com.berry.animation.core.*;
    import com.berry.animation.data.RotateEnum;
    import com.berry.animation.library.AnimationSequenceData;
    import com.berry.animation.library.AnimationPart;
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetDataGetQuery;
    import com.berry.animation.library.AssetLibrary;

    import org.dzyga.callbacks.Promise;
    import org.dzyga.events.Action;
    import org.dzyga.events.EnterFrame;

    public class ComplexMoveAssetCanvas extends MovieAssetCanvas {
        public function ComplexMoveAssetCanvas(name:String) {
            super(name);
        }

        public var fullAnimation:Boolean = true;
        public var isEffect:Boolean = false;
        public var assetLibrary:AssetLibrary;

        public var startRenderPromise:Promise = new Promise();
        public var renderCompletePromise:Promise = new Promise();
        public var animationPartFinishPromise:Promise = new Promise();

        private var _pauseAction:Action;
        private var _nextToTimeAction:Action;

        private var _assetModel:AssetModel;
        private var _currPreset:AnimationPart;
        private var _animationModel:AnimationSequenceData;

        private var _loopCount:int;
        private var _loopList:Boolean;

        private var _rendered:Boolean;

        public function get isActive():Boolean {
            return assetData && assetData.isRenderFinish;
        }

        public function playAnimationSet(animationModel:AnimationSequenceData):void {
            _animationModel = animationModel;
            _loopList = _animationModel.loop;
            _loopCount = _animationModel.sequenceLoopCount;
            playPart(_animationModel.currentPart());
        }

        private function playPart(currPreset:AnimationPart, isOneFrame:Boolean = false):void {
            var nextAssetData:AssetData;
            var query:AssetDataGetQuery;

            _currPreset = currPreset;

            if (isEffect && fullAnimation) {
                // если первый кадр уже отрисован
                query = _assetModel.getQuery(currPreset).setIsFullAnimation(false);
                nextAssetData = assetLibrary.getAssetData(query);
                if (isOneFrame) {
                   // EnterFrame.scheduleAction(3000 + 3000 * Math.random(), getEffect);
                }
            } else {
                query = _assetModel.getQuery(currPreset);
                query.setIsFullAnimation(fullAnimation);
                nextAssetData = assetLibrary.getAssetData(query);
            }

            EnterFrame.removeScheduledAction(_pauseAction);

            if (nextAssetData.isRenderFinish) {
                loop = currPreset.isLoop;
                loopCount = currPreset.loopCount;

                if (assetData != nextAssetData || !loop) {
                    assetData = nextAssetData;
                    if (_animationModel.play) {
                        gotoAndPlay(0);
                        //_view.gotoAndPlay(_animationModel.startFrame);
                    } else {
                        gotoAndStop(_animationModel.startFrame);
                    }
                }

                EnterFrame.removeScheduledAction(_nextToTimeAction);
                if (!loop) {
                    if (currPreset.pauseTime) {
                        animationFinishPromise.callbackRegister(loadOneFrame);
                        _nextToTimeAction = EnterFrame.scheduleAction(currPreset.pauseTime + currPreset.pauseTime * Math.random(), next)
                    } else {
                        animationFinishPromise.callbackRegister(next);
                    }
                } else if (currPreset.randomTime) {
                    if (currPreset.pauseTime) {
                        _nextToTimeAction = EnterFrame.scheduleAction(currPreset.randomTime + currPreset.randomTime * Math.random(), loadOneFrame);
                        _nextToTimeAction = EnterFrame.scheduleAction(currPreset.pauseTime + currPreset.pauseTime * Math.random(), next);
                    } else {
                        _nextToTimeAction = EnterFrame.scheduleAction(currPreset.randomTime + currPreset.randomTime * Math.random(), next);
                    }
                } else {
                    // trace('no time or loop')
                }
            } else {
                // wait to the end rendering
                _rendered = false;
                startRenderPromise.resolve();
                nextAssetData.completeRenderPromise.callbackRegister(newAssetRendered);
            }
        }

        public function get isRenderFinish():Boolean {
            return assetData && assetData.isRenderFinish;
        }

        private function getEffect():void {
            var query:AssetDataGetQuery = _assetModel.getQuery(_animationModel.currentPart()).setIsCheckDuplicateData(AssetDataGetQuery.CHECK_DUPLICATE_ONE_FRAME);
            var fullAssetData:AssetData = assetLibrary.getAssetData(query);

            if (fullAssetData.isRenderFinish) {
                playCurrentPart();
            } else {
                fullAssetData.completeRenderPromise.callbackRegister(playCurrentPart);
            }
        }

        private function loadOneFrame():void {
            animationFinishPromise.callbackRemove(loadOneFrame);
            playPart(_animationModel.currentPart(), true)
        }

        private function newAssetRendered(e:* = null):void {
            _rendered = true;
            if (loop && isPlay) {
                // wait end animation
                loop = false;
                animationFinishPromise.callbackRegister(playCurrentPart);
            } else {
                playPart(_animationModel.currentPart());
            }
            renderCompletePromise.resolve();
        }

        private function playCurrentPart(e:* = null):void {
            animationFinishPromise.callbackRemove(playCurrentPart);
            playPart(_animationModel.currentPart());
        }

        private function next():void {
            animationFinishPromise.callbackRemove(next);
            animationPartFinishPromise.resolve();
            if (_animationModel.isListEnd) {
                animationFinishPromise.resolve();
                if (!_loopList) {
                    _loopCount--;
                }
                if (_loopCount > 0 || _loopList) {
                    _animationModel.nextPresetRandom();
                    //EffectViewer.log(_view.name + ' next ON_ANIMATION_FINISH');
                    playPart(_animationModel.currentPart());
                }
            } else {
                _animationModel.nextPresetRandom();
                //EffectViewer.log(_view.name + ' next ON_ANIMATION_PART_FINISH');
                playPart(_animationModel.currentPart());
            }
        }

        public function set assetModel(value:AssetModel):void {
            _assetModel = value;
            name = _assetModel.assetName;
        }

        public function get animationModel():AnimationSequenceData {
            return _animationModel;
        }

        public function set renderPriority(priority:int):void {_assetModel.priority = priority;}
    }
}
