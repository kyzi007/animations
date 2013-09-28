package com.berry.animation.core {
    import animation.*;
    import flash.display.DisplayObject;

    public class EffectAspect implements IAssetViewAspect{
        private var _parent:AssetViewNew;

        public function EffectAspect(parent:AssetViewNew) {
            _parent = parent;
        }

        public function play():void {

        }

        public function setVisible(value:Boolean):void{

        }

        public function get view():DisplayObject {
            return null;
        }
    }
}
