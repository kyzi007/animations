package com.berry.animation.utils {
    import com.berry.animation.library.AssetFrame;

    public class Memory {

        public static function getTimlineSum(timline:Vector.<AssetFrame>):int {
            var sum:int;
            for each (var assetFrame:AssetFrame in timline) {
                sum += assetFrame.bitmap.width * assetFrame.bitmap.height;
            }
            return sum * 4 / 1024;
        }

    }
}
