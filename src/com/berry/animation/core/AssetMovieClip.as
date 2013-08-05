package com.berry.animation.core {
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetFrame;

    import flash.display.BitmapData;
    import flash.display.MovieClip;

    import log.logServer.KLog;

    import org.ColorMatrix;
    import org.dzyga.events.Action;
    import org.dzyga.events.EnterFrame;

    public class AssetMovieClip extends AssetSprite {

        public function AssetMovieClip(name:String) {
            super(name);
        }

        public var loopCount:int;
        protected var _filter:ColorMatrix;
        protected var _currentFrame:uint = 0;
        protected var _drawPriority:int = 25;
        private var _loop:Boolean = true;
        private var _assetData:AssetData;
        private var _speed:Number = 1;
        private var _frames:Vector.<AssetFrame>;
        private var _playAction:Action;
        private var _onEnterFrame:Function;
        private var _lastFrame:int;
        private var _tempForFreeze:BitmapData;
        private var _clip:MovieClip;

        public function applyFilter(filter:ColorMatrix):void {
            if (_filter) return;
            _filter = filter;
            makeFreeze();
        }

        public function removeFilter():void {
            if (!_filter) return;
            _filter = null;
            if (_tempForFreeze) {
                incrementAndDrawFrame();
                _tempForFreeze.dispose();
                _tempForFreeze = null;
            }
        }

        public override function cleanUp():void {
            EnterFrame.removeAction(_playAction);
            _playAction = null;
            _onEnterFrame = null;
            if (_assetData) {
                _assetData.useCount--;
            }
            _assetData = null;
            super.cleanUp();
        }

        public function gotoAndPlay(frame:uint = 0):void {
            if (!_assetData.isRenderFinish) return;

            _currentFrame = frame;
            _frames = _assetData.frames;

            if (_assetData.isBitmap && _frames.length == 0) {
                CONFIG::debug{ KLog.log("AssetMovieClip : gotoAndStop  " + _assetName + ' invalid animation - 0 frames', KLog.ERROR); }
                return;
            }

            if (_assetData.isBitmap) {
                draw(_frames[_currentFrame], true);
            } else {
                _clip = _assetData.getMovie();
                _clip.gotoAndStop(_currentFrame + 1);
                draw(_clip, true);
            }

            makeFreeze();

            if (_playAction) {
                EnterFrame.removeAction(_playAction);
            }
            if (totalFrames > 1) {
                _playAction = EnterFrame.addAction(_drawPriority, incrementAndDrawFrame);
                _playAction.name = 'Asset : incrementAndDrawFrame ' + _assetName;
            }
        }

        public function gotoAndStop(frame:uint):void {
            clearAnimation();

            _currentFrame = frame;
            _frames = _assetData.frames;

            if (_assetData.isBitmap && _frames.length == 0) {
                CONFIG::debug{ KLog.log("AssetMovieClip : gotoAndStop  " + _assetName + ' invalid animation - 0 frames', KLog.ERROR); }
                return;
            }
            if (_assetData.isBitmap) {
                draw(_frames[_currentFrame], true);
            } else {
                _clip = _assetData.getMovie();
                _clip.gotoAndStop(_currentFrame + 1);
                draw(_clip, true);
            }
            makeFreeze();
        }

        public function stop(force:Boolean = false):void {
            if (force) {
                finishAnimation();
            } else {
                _loop = false;
                loopCount = 1;
            }
        }

        protected function finishAnimation():void {
            clearAnimation();
            _lastFrame = -1;
            _clip = null;
            dispatcher.dispatchEvent(AssetViewEvents.ON_ANIMATION_FINISH);
        }

        private function makeFreeze():void {
            if (_filter) {
                try {
                    _tempForFreeze = _bitmap.bitmapData.clone();
                    _bitmap.bitmapData = _tempForFreeze;
                    _bitmap.bitmapData.applyFilter(_tempForFreeze, _bitmap.getBounds(_bitmap), _bitmap.getBounds(_bitmap).topLeft, _filter.filter);
                    _bitmap.smoothing = true;
                } catch (err:Error) {

                }
            }
        }

        private function clearAnimation():void {
            EnterFrame.removeAction(_playAction);
            _playAction = null;
        }

        private function incrementAndDrawFrame():void {
            var frame:uint = Math.floor(_currentFrame);
            if (Math.floor(_currentFrame) >= totalFrames) {
                if (!_loop) {
                    if (loopCount <= 1) {
                        //clearAnimation();
                        finishAnimation();
                        return;
                    }
                    loopCount--;
                }
                frame = _currentFrame = 0;
            }

            if (_assetData.isBitmap) {
                draw(_frames[_currentFrame], false);
            } else {
                _clip.gotoAndStop(_currentFrame + 1);
                draw(_clip, false);
            }

            makeFreeze();
            if (_onEnterFrame != null) _onEnterFrame();

            _currentFrame += _speed;
        }

        public function get isPlay():Boolean {
            return Boolean(_playAction);
        }

        public function get speed():Number {return _speed;}

        public function set speed(speed:Number):void {
            _speed = speed;
        }

        public function set onEnterFrame(value:Function):void {
            _onEnterFrame = value;
        }

        public function get totalFrames():Number {
            if (!_assetData) return 0;
            if (_assetData.isBitmap) {
                return _frames.length;
            } else {
                return _clip.totalFrames;
            }
        }

        public function get assetData():AssetData {
            return _assetData;
        }

        public function set assetData(value:AssetData):void {
            if (_assetData) {
                _assetData.useCount--;
            }
            _assetData = value;
            if (_assetData) {
                _assetData.useCount++;
            }
        }

        public function get loop():Boolean {
            return _loop;
        }

        public function set loop(value:Boolean):void {
            _loop = value;
        }
    }
}
