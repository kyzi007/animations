package com.berry.animation.core {
    import com.berry.animation.library.AnimationModel;
    import com.berry.animation.library.AnimationPart;
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetDataGetQuery;
    import com.berry.animation.library.AssetLibrary;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.events.Action;
    import org.dzyga.events.EnterFrame;
    import org.dzyga.geom.Rect;

    public class AdvancedAssetMovieClip {
        public function AdvancedAssetMovieClip(name:String) {
            _assetMovieClip = new AssetMovieClip(name)
        }


        public var fullAnimation:Boolean = true;
        public var loadOneFrameFirst:Boolean = false;
        public var assetLibrary:AssetLibrary;
        public var _assetMovieClip:AssetMovieClip;
        public var renderCompletePromise:Promise = new Promise();
        public var animationPartFinishPromise:Promise = new Promise();
        public var animationFinishPromise:Promise = new Promise();
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

        public function get isActive():Boolean
        {
            return _assetMovieClip && _assetMovieClip.assetData && _assetMovieClip.assetData.isRenderFinish
        }

        public function playAnimationSet(animationModel:AnimationModel):void {
            _animationModel = animationModel;
            _loopCount = _animationModel.loopCount;
            _loopList = _animationModel.loop;
            playPart(_animationModel.currentPart());
        }

        public function cleanUp():void {
            _assetMovieClip.clear();
        }

        public function hitTest(x:int, y:int):Boolean {
            return _assetMovieClip.hitTest(x, y);
        }

        public function applyFilter(value:ColorMatrix):void {
            _assetMovieClip.applyFilter(value);
        }

        public function removeFilter():void {
            _assetMovieClip.removeFilter();
        }

        public function showPivot():void {
            //TODO
        }

        // ебучий ад, мне стыдно
        private function playPart(currPreset:AnimationPart, isOneFrame:Boolean = false):void {
            var assetData:AssetData;
            var query:AssetDataGetQuery = _data.getQuery(currPreset.fullName);

           //EffectViewer.log(_view.name + ' play part ' + currPreset.fullName);

            if (loadOneFrameFirst && fullAnimation || isOneFrame) {
                query.setIsFullAnimation(false).setIsAutoClear(false).setIsCheckDuplicateData(AssetDataGetQuery.CHECK_DUPLICATE_ONE_FRAME);
                assetData = assetLibrary.getAssetData(query);
                if (!isOneFrame) {
                    if (assetData.isRenderFinish) {
                        query = _data.getQuery(currPreset.fullName).setIsFullAnimation(true);
                        if (assetLibrary.assetRendered(query)) {
                            assetData = assetLibrary.getAssetData(query);
                        } else {
                            EnterFrame.scheduleAction(3000 + 3000 * Math.random(), getEffect);
                        }

                    }
                }
            } else {
                query.setIsFullAnimation(fullAnimation);
                assetData = assetLibrary.getAssetData(query);
            }

            EnterFrame.removeScheduledAction(_pauseAction);

            if (assetData.isRenderFinish) {
                _assetMovieClip.loop = currPreset.isLoop;
                _assetMovieClip.loopCount = currPreset.loopCount;

                if (_assetMovieClip.assetData != assetData || !_assetMovieClip.loop) {
                    _assetMovieClip.assetData = assetData;
                    if (_animationModel.play) {
                        _assetMovieClip.gotoAndPlay(0);
                        //_view.gotoAndPlay(_animationModel.startFrame);
                    } else {
                        _assetMovieClip.gotoAndStop(_animationModel.startFrame);
                    }
                }

                EnterFrame.removeScheduledAction(_nextToTimeAction);
                if (!_assetMovieClip.loop) {
                    if (currPreset.pauseTime) {
                        _assetMovieClip.animationFinishPromise.callbackRegister(loadOneFrame);
                        _nextToTimeAction = EnterFrame.scheduleAction(currPreset.pauseTime + currPreset.pauseTime * Math.random(), next)
                    } else {
                        _assetMovieClip.animationFinishPromise.callbackRegister(next);
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
                assetData.completeRenderPromise.callbackRegister(newAssetRendered);
            }
        }

        public function get isRenderFinish():Boolean
        {
            return _assetMovieClip.assetData && _assetMovieClip.assetData.isRenderFinish;
        }

        private function getEffect():void {
            var query:AssetDataGetQuery = _data.getQuery(_animationModel.currentPart().fullName).setIsCheckDuplicateData(AssetDataGetQuery.CHECK_DUPLICATE_ONE_FRAME);
            var fullAssetData:AssetData = assetLibrary.getAssetData(query);
            if (fullAssetData.isRenderFinish) {
                playCurrentPart();
            } else {
                fullAssetData.completeRenderPromise.callbackRegister(playCurrentPart);
            }
        }

        private function loadOneFrame():void {
            _assetMovieClip.animationFinishPromise.callbackRemove(loadOneFrame);
            playPart(_animationModel.currentPart(), true)
        }

        private function newAssetRendered(e:* = null):void {
            _rendered = true;
            if (_assetMovieClip.loop && _assetMovieClip.isPlay) {
                // wait end animation
                _assetMovieClip.loop = false;
                _assetMovieClip.animationFinishPromise.callbackRegister(playCurrentPart);
            } else {
                playPart(_animationModel.currentPart());
            }
            renderCompletePromise.resolve();
        }

        private function playCurrentPart(e:* = null):void {
            _assetMovieClip.animationFinishPromise.callbackRemove(playCurrentPart);
            playPart(_animationModel.currentPart());
        }

        private function next():void {
            _assetMovieClip.animationFinishPromise.callbackRemove(next);
            animationPartFinishPromise.resolve();
            if (_isFinishToEndCurrent) {
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
            _isFinishToEndCurrent = _animationModel.isListEnd;
        }

        public function get visible():Boolean {
            return _assetMovieClip.view.visible;
        }

        public function setVisible(value:Boolean):void {
            _assetMovieClip.setVisible(value);
        }

        public function get bounds():Rect {
            return _assetMovieClip.bounds;
        }

        public function set speed(speed:Number):void {_assetMovieClip.speed = speed;}

        public function set data(value:AssetModel):void {
            _data = value;
            _assetMovieClip.name = _data.assetName;
        }

        public function get assetMovieClip():AssetMovieClip {
            return _assetMovieClip;
        }

        public function get animationModel():AnimationModel {
            return _animationModel;
        }
    }
}
