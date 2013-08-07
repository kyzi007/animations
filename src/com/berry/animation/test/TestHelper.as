package com.berry.animation.test {
    import animation.MidnightAssetLibrary;
    import animation.MidnightAssetView;

    import com.berry.animation.data.AnimationsList;
    import com.berry.animation.library.AnimationLibrary;

    import flash.display.Sprite;
    import flash.events.MouseEvent;

    import log.logServer.KLogSettings;

    import org.dzyga.events.EnterFrame;

    [SWF(width=800, height=800)]
    public class TestHelper extends Sprite {

        public function TestHelper() {
            KLogSettings.isThrowError = true;
            KLogSettings.traceOn = true;

            EnterFrame.dispatcher = stage;

            var assetLib:MidnightAssetLibrary = new MidnightAssetLibrary("assets/");
            var animLib:AnimationLibrary = new AnimationLibrary();

            assetLib.init();
            //assetLib.dispatcher.setEventListener(true, AssetLibrary.ON_INIT, function (e:*) {
            asset = new MidnightAssetView("DEFAULT_FEMALE", "DEFAULT_FEMALE");
            asset.stepFrame = 1;
            asset.animationLibrary = animLib;
            asset.assetLibrary = assetLib;
            //asset.rotation = ROTATE;
            //asset.vectorMode = true;

            //asset.flip = true;
            //asset.effectMode = false;
            asset.configureAnimationAsHelper();
            asset.cache = true;
            asset.init();
            asset.visible = true;
            asset.playByName(AnimationsList.IDLE);

            asset.shadowSprite.alpha = 0.5;
            addChild(asset.shadowSprite);
            addChild(asset.mainSprite);

            asset.x = 300;
            asset.y = 700;

            stage.addEventListener(MouseEvent.CLICK, click);
            //});
        }

        private function click(event:MouseEvent):void {
            asset.flip = !asset.flip;
        }

        var asset:MidnightAssetView;
    }
}
