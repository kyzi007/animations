package com.berry.animation.test {
    import com.berry.animation.library.AnimationLibrary;
    import com.berry.animation.library.AssetLibrary;
    import com.berry.animation.library.MidnightAssetLibrary;

    import explore.view.components.TileView;

    import flash.display.Sprite;

    import log.logServer.KLogSettings;

    import org.dzyga.events.EnterFrame;

    [SWF(width=800, height=800)]
    public class TestTile extends Sprite {

        public function TestTile() {
            KLogSettings.isThrowError = true;
            KLogSettings.traceOn = true;

            EnterFrame.dispatcher = stage;

            var assetLib:MidnightAssetLibrary = new MidnightAssetLibrary("assets/");
            var animLib:AnimationLibrary = new AnimationLibrary();

            assetLib.init();
            assetLib.dispatcher.setEventListener(true, AssetLibrary.ON_INIT, function (e:*) {
                asset = new TileView("tile_road02", "tile_road02");
                asset.animationLibrary = animLib;
                asset.assetLibrary = assetLib;
                asset.init();
                asset.visible = true;

                addChild(asset.mainSprite);

                asset.x = 300;
                asset.y = 700;
            });
        }

        var asset:TileView;
    }
}
