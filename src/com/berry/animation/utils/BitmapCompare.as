package com.berry.animation.utils {
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetDataGetQuery;
    import com.berry.animation.library.AssetFrame;

    import flash.display.BitmapData;
    import flash.geom.Rectangle;

    public class BitmapCompare {
        public static function checkDuplicateData(assetData:AssetData, bitmap:BitmapData, bounce:Rectangle, frame:int):int {
            if (frame == 0) return -1;
            if (assetData.getQuery.checkDuplicateDataMode == AssetDataGetQuery.CHECK_DUPLICATE_NONE)       return -1;
            if (assetData.getQuery.checkDuplicateDataMode == AssetDataGetQuery.CHECK_DUPLICATE_ONE_FRAME)  return checkDuplicateDataOneFrame(assetData, bitmap, bounce, frame);

            var isDuplicate:Boolean = false;
            var compareFrame:AssetFrame;
            var x:uint, y:uint;
            var compareResult:*;

            while (!isDuplicate && --frame >= 0) {
                compareFrame = assetData.frames[frame];
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

        public static function checkDuplicateDataOneFrame(_assetData:AssetData, bitmap:BitmapData, bounce:Rectangle, i:int):int {
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

    }
}
