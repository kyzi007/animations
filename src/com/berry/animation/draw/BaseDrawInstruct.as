package com.berry.animation.draw {
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetDataGetQuery;
    import com.berry.animation.library.AssetFrame;
    import com.berry.events.SimpleEventDispatcher;

    import flash.display.BitmapData;
    import flash.geom.Rectangle;

    import org.dzyga.events.IInstruct;

    public class BaseDrawInstruct implements IInstruct {

        public function BaseDrawInstruct(assetData:AssetData, config:AssetDataGetQuery, source:*) {
            _assetData = assetData;
            _query = config;
            _source = source;
        }

        public static const FINISH:String = 'finish';
        public static const FALLED:String = 'falled';
        protected static const TEXT_MC_NAME:String = 'textMc';
        protected static const TEXT_NAME:String = 'text';
        protected static const TEXT_SHADOW_NAME:String = 'shadowText';
        public var dispather:SimpleEventDispatcher = new SimpleEventDispatcher();
        protected var _currentFrame:int = 0;
        protected var _totalFrames:int = 0;
        protected var _query:AssetDataGetQuery;
        protected var _source:*;
        protected var _assetData:AssetData;
        private var _falled:Boolean;
        private var _inited:Boolean;
        // todo render progress

        public function execute():Boolean {
            var complete:Boolean = drawFrame(_currentFrame);
            _currentFrame++;
            return complete;
        }

        public function finish():void {
            _source = null;
            if (!_falled) {
                dispather.dispatchEvent(FINISH);
                _assetData.finishRender();
            }
        }

        public function falled():void {
            _falled = true;
            _assetData.falledRender();
            dispather.dispatchEvent(FALLED);
        }

        /**
         * parse clip
         */
        public function init(...params):void {
            _inited = true;
        }

        protected function checkDuplicateData(bitmap:BitmapData, bounce:Rectangle, frame:int):int {
            if (frame == 0) return -1;
            if (_query.checkDuplicateDataMode == AssetDataGetQuery.CHECK_DUPLICATE_NONE)       return -1;
            if (_query.checkDuplicateDataMode == AssetDataGetQuery.CHECK_DUPLICATE_ONE_FRAME)  return checkDuplicateDataOneFrame(bitmap, bounce, frame);

            var isDuplicate:Boolean = false;
            var compareFrame:AssetFrame;
            var x:uint, y:uint;
            var compareResult:*;

            while (!isDuplicate && --frame >= 0) {
                compareFrame = _assetData.frames[frame];
                if (
                        compareFrame.bitmap.width != bounce.width
                                || compareFrame.bitmap.height != bounce.height
                                || compareFrame.x != bounce.x
                                || compareFrame.y != bounce.y
                        ) {
                    continue;
                }

                x = bounce.width / 2;
                y = bounce.height / 2;

                if (bitmap.getPixel32(x, y) != compareFrame.bitmap.getPixel32(x, y)) continue;

                x = bounce.width / 4;
                y = bounce.height / 4;

                if (bitmap.getPixel32(x, y) != compareFrame.bitmap.getPixel32(x, y)) continue;

                x = bounce.width / 2;
                y = bounce.height / 4;

                if (bitmap.getPixel32(x, y) != compareFrame.bitmap.getPixel32(x, y)) continue;

                x = bounce.width / 4;
                y = bounce.height / 2;

                if (bitmap.getPixel32(x, y) != compareFrame.bitmap.getPixel32(x, y)) continue;

                compareResult = bitmap.compare(compareFrame.bitmap);
                if (compareResult is BitmapData) {
                    BitmapData(compareResult).dispose();
                } else {
                    isDuplicate = true;
                }
            }
            return isDuplicate ? frame : -1;
        }

        protected function checkDuplicateDataOneFrame(bitmap:BitmapData, bounce:Rectangle, i:int):int {
            var isDuplicate:Boolean = false;
            var compareFrame:AssetFrame;
            var compareResult:*;

            i--;
            compareFrame = _assetData.frames[i];
            if (
                    compareFrame.bitmap.width != bounce.width
                            || compareFrame.bitmap.height != bounce.height
                            || compareFrame.x != bounce.x
                            || compareFrame.y != bounce.y
                    ) {
                return -1;
            }

            compareResult = bitmap.compare(compareFrame.bitmap);
            if (compareResult is BitmapData) {
                BitmapData(compareResult).dispose();
            } else {
                isDuplicate = true;
            }

            return isDuplicate ? i : -1;
        }

        /**
         *
         * @param i
         * @return boolean flag - is this finished
         */
        protected function drawFrame(i:int):Boolean {
            return true;
        }

        public function get name():String {
            return "";
        }
    }
}
