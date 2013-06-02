package {
    import animation.graphic.AnimationsList;

    import game.animation.*;
    import animation.AssetView;
    import animation.library.AssetData;
    import animation.library.AssetDataGetQuery;
    import animation.library.AssetLibrary;

    import dzyga.events.Action;
    import dzyga.events.EnterFrame;

    import explore.LevelNotifications;
    import explore.model.data.GameObject;

    import flash.utils.Dictionary;

    import game.GlobalNotifications;

    import org.puremvc.as3.interfaces.INotification;
    import org.puremvc.as3.patterns.mediator.Mediator;

    public class AnimationManager extends Mediator {

        public static const NAME:String = 'RandomAnimationManager';
        public static var itemPreloader:AssetData;
        public static var helperPreloader:AssetData;
        private var _isWork:Boolean = false;
        private var _action:Action;
        private var _objects:Dictionary = new Dictionary();
        private var _updateKeys:Dictionary;
        private var _lock:Boolean;

        public function addItem(item:AssetView):void {
            _objects[item] = item;
            startWork();
        }

        override public function getMediatorName():String {
            return NAME;
        }

        override public function handleNotification(notification:INotification):void {
            switch (notification.getName()) {

                case GlobalNotifications.MECHANIC_READY:
                    animate();
                    break;

                case LevelNotifications.READY:
                    stopAll();
                    break;
            }
        }

        override public function listNotificationInterests():Array {
            return [
                GlobalNotifications.MECHANIC_READY,
                LevelNotifications.READY
            ];
        }

        public function lock():void {
            _lock = true;
            pauseWork();
        }

        override public function onRegister():void {
            super.onRegister();

            helperPreloader = itemPreloader = AssetLibrary.getAssetData(
                    new AssetDataGetQuery()
                            .setAssetName('preloader')
                            .setObjectType(GameObject.ITEM)
                            .setIsAutoClear(false)
                            .setIsFullAnimation(true)
                            .setAnimationName(AnimationsList.IDLE)
                            .setIsBitmapRendering(true)
                            .setAsynchRender(true)

            );
        }

        public function removeItem(item:AssetView):void {
            delete _objects[item];
        }

        public function unlock():void {
            _lock = false;
            startWork();
        }

        //TODO: сделать разные шансы для анимации для разных объектов

        private function animate():void {
            _action = EnterFrame.scheduleAction(Math.random() * 2000 + 1500, animate);
            _action.name = 'RandomAnimationManager:animate';

            var view:AssetView;

            if (EnterFrame.calculatedFps < 20 || !EnterFrame.isStageActive) {
                stopAll();
                return;
            }

            _updateKeys = new Dictionary();
            // stop
            for each(view in _objects) {
                if (view && view.isOnStage) {
                    if (Math.random() < .6) {
                        view.stopAnimation();
                        _updateKeys[view] = true;
                    }
                }
            }

            // play
            for each(view in _objects) {
                if (view && view.isOnStage && !_updateKeys[view]) {
                    if (Math.random() < 0.6) {
                        view.playSimpleAnimation();
                    }
                }
            }
        }

        private function pauseWork():void {
            _isWork = false;
            stopAll();
            if (_action) {
                EnterFrame.removeScheduledAction(_action);
                _action = null;
            }
        }

        private function startWork():void {
            if (!_isWork && !_lock) {
                animate();
                _isWork = true;
            }
        }

        private function stopAll():void {
            var view:AssetView;
            var objectId:*;
            for (objectId in _objects) {
                view = _objects[objectId];
                if (view && view.isOnStage) {
                    view.stopAnimation();
                }
            }
        }
    }
}
