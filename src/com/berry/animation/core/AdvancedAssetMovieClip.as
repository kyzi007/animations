package com.berry.animation.core {
    import com.berry.animation.library.AnimationModel;
    import com.berry.animation.library.AnimationPart;
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetDataGetQuery;
    import com.berry.animation.library.AssetLibrary;

    import org.ColorMatrix;
    import org.dzyga.events.Action;
    import org.dzyga.events.EnterFrame;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.geom.Rect;

    public class AdvancedAssetMovieClip {
        public function AdvancedAssetMovieClip(name:String) {
            _view = new AssetMovieClip(name)
        }

        public var fullAnimation:Boolean = true;
        public var loadOneFrameFirst:Boolean = false;
        public var assetLibrary:AssetLibrary;
        public var _view:AssetMovieClip;
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

        public function get isActive():Boolean
        {
            return _view && _view.assetData && _view.assetData.isRenderFinish
        }

        public function playAnimationSet(animationModel:AnimationModel):void {
            _animationModel = animationModel;
            _loopCount = _animationModel.loopCount;
            _loopList = _animationModel.loop;
            playPart(_animationModel.currentPart());
        }

        public function cleanUp():void {
            _view.cleanUp();
        }

        public function hitTest(x:int, y:int):Boolean {
            return _view.hitTest(x, y);
        }

        public function applyFilter(value:ColorMatrix):void {
            _view.applyFilter(value);
        }

        public function removeFilter():void {
            _view.removeFilter();
        }

        public function showPivot():void {
            //TODO
        }

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
                _view.loop = currPreset.isLoop;
                _view.loopCount = currPreset.loopCount;

                if (_view.assetData != assetData || !_view.loop) {
                    _view.assetData = assetData;
                    if (_animationModel.play) {
                        _view.gotoAndPlay(0);
                        //_view.gotoAndPlay(_animationModel.startFrame);
                    } else {
                        _view.gotoAndStop(_animationModel.startFrame);
                    }
                }

                EnterFrame.removeScheduledAction(_nextToTimeAction);
                if (!_view.loop) {
                    if (currPreset.pauseTime) {
                        _view.animationFinishPromise.callbackRegister(loadOneFrame);
                        _nextToTimeAction = EnterFrame.scheduleAction(currPreset.pauseTime + currPreset.pauseTime * Math.random(), next)
                    } else {
                        _view.animationFinishPromise.callbackRegister(next);
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
                assetData.completeRenderPromise.callbackRegister(newAssetRendered);
            }
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
            _view.animationFinishPromise.callbackRemove(loadOneFrame);
            playPart(_animationModel.currentPart(), true)
        }

        private function newAssetRendered(e:* = null):void {
            renderCompletePromise.resolve();
            if (_view.loop && _view.isPlay) {
                // wait end animation
                _view.loop = false;
                _view.animationFinishPromise.callbackRegister(playCurrentPart);
            } else {
                playPart(_animationModel.currentPart());
            }
        }

        private function playCurrentPart(e:* = null):void {
            _view.animationFinishPromise.callbackRemove(playCurrentPart);
            playPart(_animationModel.currentPart());
        }

        private function next():void {
            _view.animationFinishPromise.callbackRemove(next);
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
            return _view.visible;
        }

        public function setVisible(value:Boolean):void {
            _view.setVisible(value);
        }

        public function get bounds():Rect {
            return _view.bounds;
        }

        public function set speed(speed:Number):void {_view.speed = speed;}

        public function set data(value:AssetModel):void {
            _data = value;
            _view.name = _data.name;
        }

        public function get view():AssetMovieClip {
            return _view;
        }

        public function get animationModel():AnimationModel {
            return _animationModel;
        }
    }
}
