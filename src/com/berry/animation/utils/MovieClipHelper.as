package com.berry.animation.utils {
    import flash.display.DisplayObject;
    import flash.display.MovieClip;

    public class MovieClipHelper {
        /**
         * stop all animation in the clip and his children
         * @param source
         */
        public static function stopAllMovies(source:MovieClip):void {
            if (source) {
                source.stop();
                for (var i:int = 0; i < source.numChildren; i++) {
                    var o:DisplayObject = source.getChildAt(i);
                    if (o is MovieClip) {
                        stopAllMovies(o as MovieClip);
                    }
                }
            }
        }
    }
}
