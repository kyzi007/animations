package com.berry.animation.graphic {
    import com.berry.enums.Enum;

    public class AssetViewStateEnum extends Enum {
        public function AssetViewStateEnum () {
            super([STATE_PRELOADER, STATE_STOP, STATE_PLAY, STATE_INVALID], String)
        }

        public static const STATE_PRELOADER:String = 'preloader';
        public static const STATE_STOP:String = 'one frame';
        public static const STATE_PLAY:String = 'play animation';
        public static const STATE_INVALID:String = 'inavlid';

    }
}
