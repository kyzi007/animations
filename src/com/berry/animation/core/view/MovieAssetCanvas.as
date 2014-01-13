package com.berry.animation.core.view {
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetFrame;

    import flash.display.BitmapData;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.events.Action;
    import org.dzyga.events.EnterFrame;

    public class MovieAssetCanvas extends AssetCanvas {

        public function MovieAssetCanvas(name:String) {
            super(name);
        }

        public var loopCount:int;
        public var animationFinishPromise:Promise = new Promise();
        private var _filter:ColorMatrix;
        private var _currentFrame:uint = 0;
        private var _drawPriority:int = 10;
        private var _frames:Vector.<AssetFrame>;
        private var _playAction:Action;
        private var _lastFrame:int;
        private var _tempForFreeze:BitmapData;

        public function set drawPriority(value:int):void{
            _drawPriority = value;
        }

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

        public override function clear():void {
            EnterFrame.removeAction(_playAction);
            _playAction = null;
            _onEnterFrame = null;
            if (_assetData) {
                _assetData.useCount--;
            }
            _assetData = null;
            super.clear();
        }

        public function gotoAndPlay(frame:uint = 0):void {
            if (!_assetData.isRenderFinish) return;

            _currentFrame = frame;
            _frames = _assetData.frames;

            if (_frames.length == 0 && !_assetData.mc) {
//                trace("MovieAssetCanvas -> gotoAndPlay : AssetMovieClip : gotoAndStop  ", _assetName, ' invalid animation - 0 frames');
                return;
            }

            draw(_frames[_currentFrame], true);

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

            if (_frames.length == 0 && !_assetData.mc) {
                trace("MovieAssetCanvas -> gotoAndStop : AssetMovieClip : gotoAndStop  ", _assetName, ' invalid animation - 0 frames');
                return;
            }
            draw(_frames[_currentFrame], true);
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
            animationFinishPromise.resolve();
        }

        private function makeFreeze():void {
            if (_filter) {
                try {
                    _tempForFreeze = bitmapData.clone();
                    bitmapData = _tempForFreeze;
                    bitmapData.applyFilter(_tempForFreeze, getBounds(this), getBounds(this).topLeft, _filter.filter);
                    super.smoothing = _smoothing;
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
            if (frame >= totalFrames) {
                if (!_loop) {
                    if (loopCount <= 1) {
                        finishAnimation();
                        return;
                    }
                    loopCount--;
                }
                frame = _currentFrame = 0;
            }

            if (_frames.length > frame) {
                draw(_frames[frame], false);
            }

            makeFreeze();
            if (_onEnterFrame != null) _onEnterFrame();

            _currentFrame += _speed;
        }

        private var _loop:Boolean = true;

        public function get loop():Boolean {
            return _loop;
        }

        public function set loop(value:Boolean):void {
            _loop = value;
        }

        private var _assetData:AssetData;

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
            } else {
                bitmapData = null;
            }
        }

        private var _speed:Number = 1;

        public function get speed():Number {return _speed;}

        public function set speed(speed:Number):void {
            _speed = speed;
        }

        private var _onEnterFrame:Function;
        //TODO: delete onEnterFrame after refactoring movie in midnight
        public function set onEnterFrame(value:Function):void {
            _onEnterFrame = value;
        }

        public function get isPlay():Boolean {
            return _playAction != null;
        }

        public function get totalFrames():Number {
            if (!_assetData) return 0;
            if (_assetData.mc) {
                return _assetData.mc.totalFrames;
            } else {
                return _frames.length
            }
        }

        public function set assetName(value:String):void {
            _assetName = value;
        }
    }
}
