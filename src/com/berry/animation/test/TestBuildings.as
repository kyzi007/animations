package com.berry.animation.test {

    import com.berry.animation.data.AnimationsList;
    import com.berry.animation.library.AnimationLibrary;
    import com.berry.animation.library.AssetLibrary;
    import com.berry.animation.library.MidnightAssetLibrary;

    import flash.display.Sprite;
    import flash.events.MouseEvent;

    import log.logServer.KLogSettings;

    import org.dzyga.events.EnterFrame;

    [SWF(width=800, height=800)]
    public class TestBuildings extends Sprite {

        public function TestBuildings() {
            KLogSettings.isThrowError = true;
            KLogSettings.traceOn = true;

            EnterFrame.dispatcher = stage;

            var assetLib:MidnightAssetLibrary = new MidnightAssetLibrary("assets/");
            var animLib:AnimationLibrary = new AnimationLibrary();

            assetLib.init();
            assetLib.dispatcher.setEventListener(true, AssetLibrary.ON_INIT, function (e:*) {
                //var asset:GameObjectView = new GameObjectView("quest_npc_knight_horse_0", "quest_npc_knight_horse");
                //asset = new MyGameObjectView("npc_angree_tree", "npc_angree_tree");
                ////asset = new MyGameObjectView("building_library", "building_library");
                //asset = new MyGameObjectView("building_knightscastle", "building_knightscastle");
                //asset = new MyGameObjectView("building_farmhouse", "building_farmhouse");
                asset = new MyGameObjectView("building_alchemist", "building_alchemist");
                //asset = new MyGameObjectView("building_smithy", "building_smithy");
                asset.dispatcher.setEventListener(true, AssetViewEvents.ON_UPDATE_BOUNDS, updateBounds);
                asset.stepFrame = 2;
                asset.animationLibrary = animLib;
                asset.assetLibrary = assetLib;
                //asset.rotation = ROTATE;
                //asset.vectorMode = true;

                //asset.flip = true;
                //asset.effectMode = false;
                asset.init();
                asset.visible = true;
                asset.playByName(AnimationsList.IDLE);

                asset.shadowSprite.alpha = 0.5;
                addChild(asset.shadowSprite);
                addChild(asset.mainSprite);

                asset.x = 300;
                asset.y = 700;

                stage.addEventListener(MouseEvent.CLICK, click);

            });
        }

        private function updateBounds(e:*):void {
            trace('UPDATE')
        }

        private function click(event:MouseEvent):void {
            //asset.flip = !asset.flip;
            trace(asset)
        }

        var asset:MyGameObjectView;
    }
}
