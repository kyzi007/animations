package animation.graphic {
    import animation.AssetTypes;
    import animation.event.AssetViewEvents;
    import animation.library.AssetData;
    import animation.library.AssetFrame;

    import dzyga.events.Action;
    import dzyga.events.EnterFrame;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;

    import log.logServer.KLog;

    public class AssetMovieClip extends AssetSprite {

        public function AssetMovieClip(name:String, type:String) {
            super(name);
            _objectType = type;
            if (_objectType == AssetTypes.TILE) {
                _assetFormat = SOURCE_PNG;
            }
            _shadowSprite.addChild(_shadowBitmap);
        }

        private static var _freezColorMatrix:ColorMatrix;
        protected var _freeze:Boolean;
        protected var _shadowSprite:Sprite = new Sprite();
        protected var _assetData:AssetData;
        protected var _currentFrame:uint = 0;
        protected var _drawPriority:int = 25;
        protected var _loop:Boolean;
        protected var _loopCount:int;
        protected var _loopTime:int;
        protected var _objectType:String;
        private var _shadowBitmap:Bitmap = new Bitmap();
        private var _speed:Number = 1;
        private var _frames:Vector.<AssetFrame>;
        private var _playAction:Action;
        private var _onEnterFrame:Function;
        private var _lastFrame:int;
        private var _shadowTimline:Vector.<AssetFrame>;
        private var _tempForFreeze:BitmapData;

        public function freeze():void {
            if (_freeze) return;
            _freeze = true;
            makeFreeze();
        }

        public function unFreeze():void {
            if (!_freeze) return;
            _freeze = false;
            if (_tempForFreeze) {
                incrementAndDrawFrame();
                _tempForFreeze.dispose();
                _tempForFreeze = null;
            }
        }

        public override function cleanUp():void {
            super.cleanUp();

            EnterFrame.removeAction(_playAction);
            _playAction = null;
            _onEnterFrame = null;
            _assetData = null;
            _shadowBitmap.bitmapData = null;
        }

        public function gotoAndPlay(frame:uint = 0):void {
            if (!_assetData.isRenderFinish) return;

            gotoAndStop(frame);

            if (totalFrames > 1) {
                _playAction = EnterFrame.addAction(_drawPriority, incrementAndDrawFrame);
                _playAction.name = 'Asset : incrementAndDrawFrame ' + _assetName;
            }
            dispatcher.dispatchEvent(AssetViewEvents.ON_UPDATE_BOUNDS);
        }

        public function gotoAndStop(frame:uint):void {
            clearAnimation();

            _currentFrame = frame;
            _frames = _assetData.frames;

            if (!_assetData.isBitmap) {
                _assetData.getMovie(this).gotoAndStop(frame + 1);
            }

            if (_assetData.isBitmap && _frames.length == 0) {
                CONFIG::debug{ KLog.log("AssetMovieClip : gotoAndStop  " + _assetName + ' invalid animation - 0 frames', KLog.ERROR); }
                return;
            }
            draw(_assetData.isBitmap ? _frames[_currentFrame] : _assetData.getMovie(this), true);
            makeFreeze();
        }

        public function stop(force:Boolean = false):void {
            if (force) {
                finishAnimation();
            } else {
                _loop = false;
                _loopCount = 1;
            }
        }

        protected function setShadowTimline(timline:Vector.<AssetFrame>):void {
            if (_shadowTimline == timline) return;
            _shadowTimline = timline;
            updateShadow();
        }

        protected function finishAnimation():void {
            clearAnimation();
            _lastFrame = -1;
        }

        private function makeFreeze():void {
            if (_freeze) {
                try {

                    _tempForFreeze = _bitmap.bitmapData.clone();
                    _bitmap.bitmapData = _tempForFreeze;
                    _bitmap.bitmapData.applyFilter(_tempForFreeze, _bitmap.getBounds(_bitmap), _bitmap.getBounds(_bitmap).topLeft, freezColorMatrix.filter);
                    _bitmap.smoothing = true;

                } catch (err:Error) {

                }
            }
        }

        private function updateShadow():void {
            if (_shadowTimline && _shadowTimline.length == 1) {
                _shadowBitmap.bitmapData = _shadowTimline[0].bitmap;
                _shadowBitmap.x = _shadowTimline[0].x;
                _shadowBitmap.y = _shadowTimline[0].y;
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
                    if (_loopCount <= 1) {
                        clearAnimation();
                        finishAnimation();
                        return;
                    }
                    _loopCount--;
                }
                frame = _currentFrame = 0;
            }

            draw(_assetData.isBitmap ? _frames[frame] : _assetData.getMovie(this), false);
            makeFreeze();
            if (_onEnterFrame != null) _onEnterFrame();

            _currentFrame += _speed;
        }

        private function get freezColorMatrix():ColorMatrix {
            if (!_freezColorMatrix) {
                _freezColorMatrix = new ColorMatrix();
                _freezColorMatrix.adjustSaturation(0.3);
                _freezColorMatrix.colorize(0, 0.1);
            }
            return _freezColorMatrix;
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
            }
            return _assetData.getMovie(this).totalFrames;
        }
    }
}
