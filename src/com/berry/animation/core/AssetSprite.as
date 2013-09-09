package com.berry.animation.core {
    import com.berry.animation.library.AssetFrame;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.geom.Point;

    import org.dzyga.callbacks.Promise;
    import org.dzyga.geom.Rect;

    public class AssetSprite extends Sprite {

        public function AssetSprite(name:String) {
            _assetName = name;
            _bitmap.smoothing = true;
            addChild(_bitmap);
        }

        private static const _point:Point = new Point();
        public var boundsUpdatePromise:Promise = new Promise();
        protected var _bitmap:Bitmap = new Bitmap();
        protected var _assetName:String;
        private var _rect:Rect = null;
        private var _currentFrameData:AssetFrame;
        private var _lastMovie:MovieClip;

        public function cleanUp():void {
            _currentFrameData = null;
            _bitmap.bitmapData = null;
            _bitmap = null;
            _rect = null;
        }

        public function hitTest(x:Number, y:Number):Boolean {
            if (_currentFrameData && _currentFrameData.bitmap && !_currentFrameData.isDestroyed) {

                var bitmapData:BitmapData = _currentFrameData.bitmap;
                var left:Number = _currentFrameData.x + bitmapData.width;
                var bottom:Number = _currentFrameData.y + bitmapData.height;

                if (x >= _currentFrameData.x &&
                        x <= left &&
                        y >= _currentFrameData.y &&
                        y <= bottom) {

                    var px:uint = bitmapData.getPixel32(x - _currentFrameData.x, y - _currentFrameData.y);
                    if (px > 0x1000000) return true;
                }
            } else {
                _point.x = x;
                _point.y = y;
                var point:Point = this.globalToLocal(_point);
                return hitTestPoint(point.x, point.y);
            }
            return false;
        }

        /**
         * @param target - AssetFrame (bitmap) or MovieClip (vector)
         * @param isUpdateBounds
         */
        protected function draw(target:*, isUpdateBounds:Boolean = false):void {
            if (!visible && !isUpdateBounds || !_bitmap) return;

            if (target is AssetFrame) {
                _currentFrameData = target;
                _bitmap.x = _currentFrameData.x;
                _bitmap.y = _currentFrameData.y;
                _bitmap.bitmapData = _currentFrameData.bitmap;
                _bitmap.smoothing = true;
            }
            else if (target is MovieClip) {
                if (target.parent != this) {
                    if (_lastMovie && _lastMovie.parent == this) {
                        _lastMovie.parent.removeChild(_lastMovie);
                    }
                    addChildAt(target, 0);
                    _lastMovie = target;
                }
            }

            if ((isUpdateBounds || !_rect) && target is AssetFrame) {
                if (!_rect) _rect = new Rect();
                if (_rect.x != _currentFrameData.x
                        || _rect.y != _currentFrameData.y
                        || _rect.width != _currentFrameData.bitmap.width
                        || _rect.height != _currentFrameData.bitmap.height
                        ) {

                    _rect.fill(
                            _currentFrameData.x,
                            _currentFrameData.y,
                            _currentFrameData.bitmap.width,
                            _currentFrameData.bitmap.height);

                    boundsUpdatePromise.resolve(this);
                }
            }

            if ((isUpdateBounds || !_rect) && target is MovieClip) {
                if (!_rect) _rect = new Rect();
                _rect.match(getBounds(this));
                boundsUpdatePromise.resolve(this);
            }
        }

        override public function set visible(value:Boolean):void {
            super.visible = value;
        }

        public function get rect():Rect {
            return _rect;
        }

        public function get bitmap():Bitmap {
            return _bitmap;
        }
    }
}
