package com.berry.animation.core {
    import com.berry.animation.library.AnimationModel;
    import com.berry.animation.library.AnimationPart;
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetDataEvents;
    import com.berry.animation.library.AssetDataGetQuery;
    import com.berry.animation.library.AssetLibrary;
    import com.berry.events.SimpleEventDispatcher;

    import org.ColorMatrix;
    import org.dzyga.events.Action;
    import org.dzyga.events.EnterFrame;
    import org.dzyga.geom.Rect;

    public class AdvancedAssetMovieClip {
        public function AdvancedAssetMovieClip() {

        }

        public var fullAnimation:Boolean = true;
        public var loadOneFrameFirst:Boolean = false;
        public var dispatcher:SimpleEventDispatcher = new SimpleEventDispatcher();
        public var assetLibrary:AssetLibrary;
        private var _data:AssetModel;
        private var _view:AssetMovieClip = new AssetMovieClip("");
        private var _animationModel:AnimationModel;
        private var _nextToTimeAction:Action;
        private var _isFinishToEndCurrent:Boolean;
        private var _loopCount:int;
        private var _loopList:Boolean;
        private var _lastPreset:AnimationPart;

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

        private function playPart(currPreset:AnimationPart):void {
            var query:AssetDataGetQuery = _data.getQuery(currPreset.fullName);
            query.setIsFullAnimation(fullAnimation);
            var assetData:AssetData = assetLibrary.getAssetData(query);
            if (assetData.isRenderFinish) {
                _view.loop = currPreset.isLoop;
                _view.loopCount = currPreset.loopCount;

                if (_view.assetData != assetData || !_view.loop) {
                    _view.assetData = assetData;
                    if(assetData.frames.length == 0){
                        trace()
                    }
                    if(_animationModel.play){
                        _view.gotoAndPlay(0);
                        //_view.gotoAndPlay(_animationModel.startFrame);
                    } else {
                        _view.gotoAndStop(_animationModel.startFrame);
                    }
                }

                EnterFrame.removeScheduledAction(_nextToTimeAction);
                if (!_view.loop) {
                    _view.dispatcher.setEventListener(true, AssetViewEvents.ON_ANIMATION_FINISH, next);
                } else if (currPreset.randomTime) {
                    _nextToTimeAction = EnterFrame.scheduleAction(currPreset.randomTime + currPreset.randomTime * Math.random(), next);
                } else {
                    // trace('no time or loop')
                }
                _lastPreset = currPreset;
                dispatcher.dispatchEvent(AssetViewEvents.ON_RENDER);
            } else {
                // wait to the end rendering
                assetData.dispatcher.setEventListener(true, AssetDataEvents.COMPLETE_RENDER, newAssetRendered);
            }
        }

        private function newAssetRendered(e:* = null):void {
            dispatcher.dispatchEvent(AssetViewEvents.ON_RENDER);
            if (_view.loop && _view.isPlay) {
                // wait end animation
                _view.loop = false;
                _view.dispatcher.setEventListener(true, AssetViewEvents.ON_ANIMATION_FINISH, playCurrentPart);
            } else {
                playPart(_animationModel.currentPart());
            }
        }

        private function playCurrentPart(e:*):void {
            _view.dispatcher.setEventListener(false, AssetViewEvents.ON_ANIMATION_FINISH, playCurrentPart);
            playPart(_animationModel.currentPart());
        }

        private function next(e:* = null):void {
            _view.dispatcher.setEventListener(false, AssetViewEvents.ON_ANIMATION_FINISH, next);
            dispatcher.dispatchEvent(AssetViewEvents.ON_ANIMATION_PART_FINISH);

            if (_isFinishToEndCurrent) {
                dispatcher.dispatchEvent(AssetViewEvents.ON_ANIMATION_FINISH);
                if (!_loopList) {
                    _loopCount--;
                }
                if (_loopCount > 0 || _loopList) {
                    _animationModel.nextPresetRandom();
                    trace('next', _animationModel.currentPart().fullName)
                    playPart(_animationModel.currentPart());
                }
            } else {
                _animationModel.nextPresetRandom();
                trace('next', _animationModel.currentPart().fullName)
                playPart(_animationModel.currentPart());
            }
            _isFinishToEndCurrent = _animationModel.isListEnd;
        }

        public function get visible():Boolean {
            return _view.visible;
        }

        public function set visible(value:Boolean):void {
            _view.visible = value;
        }

        public function get bounds():Rect {
            return _view.rect;
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
