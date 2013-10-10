package com.berry.animation.core.view {
    import com.berry.animation.library.AssetFrame;

    import flash.display.Bitmap;

    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayUtils;
    import org.dzyga.geom.Rect;

    public class AssetCanvas extends Bitmap {

        public function AssetCanvas(name:String) {
            _assetName = name;
        }

        public var boundsUpdatePromise:Promise = new Promise();
        protected var _assetName:String;
        private var _currentFrameData:AssetFrame;
        private var _y:int;
        private var _x:int;
        private var _lock:Boolean;

        public override function set x(value:Number):void {
            super.x = int(value + (_currentFrameData ? _currentFrameData.x : 0));
            _x = value;
        }

        public override function set y(value:Number):void {
            super.y = int(value + (_currentFrameData ? _currentFrameData.y : 0));
            _y = value;
        }

        public function clear():void {
            _currentFrameData = null;
            bitmapData = null;
            _bounds = null;
        }

        override public function set smoothing(value:Boolean):void {
            _smoothing = value;
            super.smoothing = value;
        }

        public function hitTest(globalX:Number, globalY:Number):Boolean {
            if (_currentFrameData && _currentFrameData.bitmap && !_currentFrameData.isDestroyed) {
                return  DisplayUtils.hitTest(this, globalX, globalY, true);
            }
            return false;
        }

        /**
         * @param frame - AssetFrame (bitmap)
         * @param isUpdateBounds
         */
        public function draw(frame:AssetFrame, isUpdateBounds:Boolean = false):void {
            if (_lock && !isUpdateBounds) return;

            _currentFrameData = frame;
            super.x = _currentFrameData.x + _x;
            super.y = _currentFrameData.y + _y;
            bitmapData = _currentFrameData.bitmap;
            super.smoothing = _smoothing;

            if ((isUpdateBounds || !_bounds)) {
                if (!_bounds) _bounds = new Rect();
                if (_bounds.x != _currentFrameData.x
                        || _bounds.y != _currentFrameData.y
                        || _bounds.width != _currentFrameData.bitmap.width
                        || _bounds.height != _currentFrameData.bitmap.height
                        ) {

                    _bounds.fill(
                            _currentFrameData.x,
                            _currentFrameData.y,
                            _currentFrameData.bitmap.width,
                            _currentFrameData.bitmap.height);

                    boundsUpdatePromise.resolve();
                }
            }
        }

        private var _bounds:Rect = null;
        protected var _smoothing:Boolean;

        public function get bounds():Rect {
            return _bounds;
        }

        public function get currentFrameData():AssetFrame {
            return _currentFrameData;
        }

        public function drawLock():void {
            _lock = true;
        }

        public function drawUnLock():void {
            _lock = false;
        }

        override public function get smoothing():Boolean {
            return _smoothing;
        }
    }
}
