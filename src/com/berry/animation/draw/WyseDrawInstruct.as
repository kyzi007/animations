package com.berry.animation.draw {
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetDataGetQuery;
    import com.berry.animation.library.AssetFrame;
    import com.berry.animation.utils.MovieClipHelper;

    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.sampler.getSize;
    import flash.utils.getTimer;

    import log.logServer.KLog;

    public class WyseDrawInstruct extends BaseDrawInstruct {

        public function WyseDrawInstruct (assetData:AssetData, config:AssetDataGetQuery, source:Sprite) {
            super(assetData, config, source);
        }

        private var _matrix:Matrix = new Matrix();
        private var _render:MovieClip = null;
        private var _timline:Vector.<AssetFrame>;
        private var _time:int;


        override public function finish ():void {
            //CONFIG::debug{ KLog.log("com.berry.animation.draw.WyseDrawInstruct : finish  " + _query.name + " " + _query.animation, KLog.METHODS); }
            _render = null;
            //trace('finish render',_query.name + ', ' + _query.animation + ', fr ' + _timline.length + ' : ' + (getTimer() - _time) + ' ms,', int(getMem1() * 4 / 1024) + ' kb');
            _assetData.memory = getMem1();
            super.finish();
        }


        override public function falled ():void {
//            trace('falled render', _query.name, _query.animation)
            super.falled();
        }

        override public function init (...params):void {
            super.init();
            _time = getTimer();
            //Mem.start();
            //CONFIG::debug{ KLog.log("com.berry.animation.draw.WyseDrawInstruct : init  " + _query.name + " " + _query.animation, KLog.METHODS); }
            //trace('init', _query.name, _query.animation);

            _source.gotoAndStop(_query.step);
            MovieClipHelper.stopAllMovies(_source);
            _timline = _assetData.frames;

            var name:String = _query.animation + _query.position + _query.rotate;
            _render = _source.getChildByName(name) as MovieClip;

            if (_render != null) {
                setText();
                hideClips();
                _source.x = 0;
                _source.y = 0;
                _totalFrames = _query.isFullAnimation ? _render.totalFrames : 1;
            } else {
                falled();
                CONFIG::debug{
                    KLog.log("com.berry.animation.draw.WyseDrawInstruct : init  INVALID ANIMATION " + _query.animation + ' - ' + _query.name, KLog.ERROR);
                }
            }
        }

        override protected function drawFrame (frame:int):Boolean {
            super.drawFrame(frame);
            if (!_render) {
                falled();
                return true;
            }
            if (_query.optimise != 0 && frame % _query.optimise == 0 && frame != 0) {
                _timline[frame] = new AssetFrame(_timline[frame - 1].x, _timline[frame - 1].y, _timline[frame - 1].bitmap);
                _timline[frame].dublicate = frame - 1;
                return (frame + 1 == _totalFrames);
            }

            _render.gotoAndStop(frame + 1);
            var bitmap:BitmapData;

            var stateRect:Rectangle = _render.getBounds(_source);

            stateRect.top = Math.floor(stateRect.top);
            stateRect.right = Math.ceil(stateRect.right);
            stateRect.bottom = Math.ceil(stateRect.bottom);
            stateRect.left = Math.floor(stateRect.left);

            _matrix.tx = -stateRect.x;
            _matrix.ty = -stateRect.y;

            if (stateRect.width <= 0) {
                stateRect.width = 1;
            }
            if (stateRect.height <= 0) {
                stateRect.height = 1;
            }

            bitmap = new BitmapData(stateRect.width, stateRect.height, true, 0);
            bitmap.draw(_source, _matrix);

            var duplicateFrame:int = checkDuplicateData(bitmap, stateRect, frame);
            if (duplicateFrame != -1) {
                bitmap.dispose();
                _timline[frame] = new AssetFrame(stateRect.x, stateRect.y, _timline[duplicateFrame].bitmap);
                _timline[frame].dublicate = duplicateFrame;
            } else {
                _timline[frame] = new AssetFrame(stateRect.x, stateRect.y, bitmap);
            }

            return (frame + 1 == _totalFrames);
        }

        private function getMem1 ():int {
            var sum:int;
            for each (var assetFrame:AssetFrame in _timline) {
                sum += assetFrame.bitmap.width * assetFrame.bitmap.height;
            }
            return sum;
        }

        private function hideClips ():void {
            for (var i:int = 0; i < _source.numChildren; i++) {
                var item:DisplayObject = _source.getChildAt(i);
                item.visible = item == _render;
            }
        }

        private function setText ():void {
            if (_query.text != null) {
                var textMc:MovieClip = _render[TEXT_MC_NAME];
                if (textMc) {
                    textMc[TEXT_NAME].text = _query.text;
                    textMc[TEXT_SHADOW_NAME].text = _query.text;
                }
            }
        }
    }
}
