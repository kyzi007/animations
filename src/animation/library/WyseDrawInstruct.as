package animation.library {

    import animation.AssetTypes;

    import com.adobe.images.PNGEncoder;
    import com.adobe.serialization.json.JSON;

    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;

    import log.logServer.KLog;

    internal class WyseDrawInstruct extends BaseDrawInstruct {

        public function WyseDrawInstruct(assetData:AssetData, config:AssetDataGetQuery, source:Sprite) {
            super(assetData, config, source);
        }

        private var _matrix:Matrix = new Matrix();
        private var _render:MovieClip = null;
        private var _timline:Vector.<AssetFrame>;
        private var _json:Object;

       /* override public function finish():void {
            var file:File = File.desktopDirectory;
            file = file.resolvePath("assets/" + _assetData.name + "__" + _query.animation + ".json");
            var fileStream:FileStream = new FileStream();
            fileStream.open(file, FileMode.WRITE);
            fileStream.writeMultiByte(JSON.encode(_json), "utf-8");
            fileStream.close();

            super.finish();
        }*/

        override protected function drawFrame(frame:int):Boolean {
            if (!_render) {
                falled();
                return true;
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

            bitmap = new BitmapData(stateRect.width, stateRect.height, true, 0);
            bitmap.draw(_source, _matrix);

            /* var duplicateFrame:int = checkDuplicateData(bitmap, stateRect, frame);
             if (duplicateFrame != -1) {
             bitmap.dispose();
             _timline[frame] = new AssetFrame(stateRect.x, stateRect.y, _timline[duplicateFrame].bitmap);
             _timline[frame].dublicate = duplicateFrame;
             } else {*/
            _timline[frame] = new AssetFrame(stateRect.x, stateRect.y, bitmap);
            /*var ba:ByteArray = PNGEncoder.encode(_timline[frame].bitmap);
            var file:File = File.desktopDirectory;
            file = file.resolvePath("assets/" + _assetData.name + "__" + _query.animation + frame + ".png");

            var fileStream:FileStream = new FileStream();
            fileStream.open(file, FileMode.WRITE);
            fileStream.writeBytes(ba);
            fileStream.close();*/
            // }

            return (frame + 1 == _totalFrames)
        }

        override protected function init():void {
            super.init();

            CONFIG::debug{ KLog.log("WyseDrawInstruct : init  " + _query.animation, KLog.METHODS); }

            _source.gotoAndStop(_query.step);

            _timline = _assetData.frames;

            var name:String = _query.animation + _query.position + _query.rotate;
            _render = _source.getChildByName(name) as MovieClip;

            if (_render != null) {
                setText();
                hideClips();
                _source.x = 0;
                _source.y = 0;
                _totalFrames = _render.totalFrames;
            } else {
                falled();
                CONFIG::debug{ KLog.log("WyseDrawInstruct : init  INVALID ANIMATION " + _query.animation, KLog.ERROR); }
            }
            /*var file:File = File.desktopDirectory;
            file = file.resolvePath("assets/" + _assetData.name + "__" + _query.animation + ".json");
            var fileStream:FileStream = new FileStream();

            if (!file.exists) {
                fileStream.open(file, FileMode.WRITE);
                fileStream.close();
                _json = {};
            } else {
                fileStream.open(file, FileMode.READ);
                var str:String = fileStream.readMultiByte(fileStream.bytesAvailable, "utf-8");
                fileStream.close();
                _json = JSON.decode(str);
            }*/
        }

        private function hideClips():void {
            for (var i:int = 0; i < _source.numChildren; i++) {
                var item:MovieClip = _source.getChildAt(i) as MovieClip;
                item.visible = item == _render;
                item.stop();
            }
        }

        private function setText():void {
            if (_query.text != null) {
                if (_query.objectType == AssetTypes.OBSTACLE) {
                    var textMc:MovieClip = _render[TEXT_MC_NAME];
                    if (textMc) {
                        textMc[TEXT_NAME].text = _query.text;
                        textMc[TEXT_SHADOW_NAME].text = _query.text;
                    }
                } else {
                    throw new Error('text not supported in' + _query.objectType);
                }
            }
        }
    }
}
