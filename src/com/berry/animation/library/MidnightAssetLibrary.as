package com.berry.animation.library {
    import com.berry.animation.data.AnimationsList;
    import com.berry.animation.data.SourceTypeEnum;

    public class MidnightAssetLibrary extends AssetLibrary {
        public function MidnightAssetLibrary(baseUrl:String) {
            super(baseUrl);
        }

        private static const PRELOADER_NAME:String = "preloader";
        private var _preloader:AssetData;

        override public function init():void {
            super.init();
            loadData("preloader", new SourceTypeEnum(), preloaderLoaded);
        }

        override public function getPreloader(assetName:String):AssetData {
            return _preloader;
        }

        private function preloaderLoaded(e:*):void {
            _preloader = getAssetData(new AssetDataGetQuery().setAssetName(PRELOADER_NAME).setAnimationName(AnimationsList.IDLE).setIsFullAnimation(true));
            _preloader.dispatcher.setEventListener(true, AssetDataEvents.COMPLETE_RENDER, finishInitCallback);
        }

        private function finishInitCallback(e:*):void {
            _preloader.dispatcher.setEventListener(false, AssetDataEvents.COMPLETE_RENDER, finishInitCallback);
            dispatcher.dispatchEvent(ON_INIT);
        }
    }
}
