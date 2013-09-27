package com.berry.animation.core {
    import com.berry.animation.library.AssetFrame;

    import flash.display.Bitmap;

    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayUtils;
    import org.dzyga.geom.Rect;

    public class AssetSprite {

        public function AssetSprite(name:String) {
            _assetName = name;
            _view.smoothing = true;
            _view.visible = false;
        }

        public var boundsUpdatePromise:Promise = new Promise();
        protected var _assetName:String;
        private var _currentFrameData:AssetFrame;

        public function setVisible(value:Boolean):void {
            _view.visible = value;
        }

        public function cleanUp():void {
            _currentFrameData = null;
            _view.bitmapData = null;
            _view = null;
            _bounds = null;
        }

        public function hitTest(globalX:Number, globalY:Number):Boolean {
            if (_currentFrameData && _currentFrameData.bitmap && !_currentFrameData.isDestroyed) {
                return  DisplayUtils.hitTest(_view, globalX, globalY, true);
            }
            return false;
        }

        /**
         * @param frame - AssetFrame (bitmap)
         * @param isUpdateBounds
         */
        public function draw(frame:AssetFrame, isUpdateBounds:Boolean = false):void {
            if (!_view.visible && !isUpdateBounds || !_view) return;

            if (frame is AssetFrame) {
                _currentFrameData = frame;
                _view.x = _currentFrameData.x;
                _view.y = _currentFrameData.y;
                _view.bitmapData = _currentFrameData.bitmap;
                _view.smoothing = true;
            }

            if ((isUpdateBounds || !_bounds) && frame is AssetFrame) {
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

                    boundsUpdatePromise.resolve(this);
                }
            }
        }

        protected var _view:Bitmap = new Bitmap();

        public function get view():Bitmap {
            return _view;
        }

        private var _bounds:Rect = null;

        public function get bounds():Rect {
            return _bounds;
        }

        public function get currentFrameData():AssetFrame {
            return _currentFrameData;
        }
    }
}
