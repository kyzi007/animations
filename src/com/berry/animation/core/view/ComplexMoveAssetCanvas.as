package com.berry.animation.core.view {
    import com.berry.animation.core.*;
    import com.berry.animation.data.RotateEnum;
    import com.berry.animation.library.AnimationModel;
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
        public var loadOneFrameFirst:Boolean = false;
        public var assetLibrary:AssetLibrary;
        public var renderCompletePromise:Promise = new Promise();
        public var animationPartFinishPromise:Promise = new Promise();
        private var _data:AssetModel;
        private var _animationModel:AnimationModel;
        private var _nextToTimeAction:Action;
        private var _isFinishToEndCurrent:Boolean;
        private var _loopCount:int;
        private var _loopList:Boolean;
        private var _lastPreset:AnimationPart;
        private var _pauseAction:Action;
        private var _rendered:Boolean;
        public var startRenderPromise:Promise = new Promise();
        private var _currPreset:AnimationPart;

        public function get isActive():Boolean {
            return assetData && assetData.isRenderFinish
        }

        public function playAnimationSet(animationModel:AnimationModel):void {
            _animationModel = animationModel;
            _loopCount = _animationModel.loopCount;
            _loopList = _animationModel.loop;
            playPart(_animationModel.currentPart());
        }

        // ебучий ад, мне стыдно
        private function playPart(currPreset:AnimationPart, isOneFrame:Boolean = false):void {
            var nextAssetData:AssetData;
            var query:AssetDataGetQuery = _data.getQuery(currPreset.fullName);
            _currPreset = currPreset;
            if (!currPreset.isRotateSupport(query.rotate)) {
                query.setRotate(RotateEnum.NONE);
            }
            //EffectViewer.log(_view.name + ' play part ' + currPreset.fullName);

            if (loadOneFrameFirst && fullAnimation || isOneFrame) {
                query.setIsFullAnimation(false).setIsAutoClear(false).setIsCheckDuplicateData(AssetDataGetQuery.CHECK_DUPLICATE_ONE_FRAME);
                nextAssetData = assetLibrary.getAssetData(query);
                if (!isOneFrame) {
                    if (nextAssetData.isRenderFinish) {
                        query = _data.getQuery(currPreset.fullName).setIsFullAnimation(true);
                        if (!currPreset.isRotateSupport(query.rotate)) {
                            query.setRotate(RotateEnum.NONE);
                        }
                        if (assetLibrary.assetRendered(query)) {
                            nextAssetData = assetLibrary.getAssetData(query);
                        } else {
                            EnterFrame.scheduleAction(3000 + 3000 * Math.random(), getEffect);
                        }

                    }
                }
            } else {
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
                _lastPreset = currPreset;
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
            var query:AssetDataGetQuery = _data.getQuery(_animationModel.currentPart().fullName).setIsCheckDuplicateData(AssetDataGetQuery.CHECK_DUPLICATE_ONE_FRAME);
            if (!_currPreset.isRotateSupport(query.rotate)) {
                query.setRotate(RotateEnum.NONE);
            }
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

        public function set data(value:AssetModel):void {
            _data = value;
            name = _data.assetName;
        }

        public function get animationModel():AnimationModel {
            return _animationModel;
        }
    }
}
