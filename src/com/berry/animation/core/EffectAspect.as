package com.berry.animation.core {
    import flash.display.DisplayObject;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.geom.Rect;

    public class EffectAspect implements IAssetViewAspect{
        private var _parent:AssetView;

        public function EffectAspect(parent:AssetView) {
            _parent = parent;
        }

        public function play():void {

        }

        public function setVisible(value:Boolean):void{

        }

        public function get view():DisplayObject {
            return null;
        }

        public function get isRendered():Boolean {
            return false;
        }

        public function get finishRenderPromise():Promise {
            return null;
        }

        public function get boundsUpdatePromise():Promise {
            return null;
        }

        public function get bounds():Rect {
            return null;
        }

        public function hitTest(globalX:int, globalY:int, checkContainer:Boolean = false):Boolean {
            return false;
        }

        public function init():void {
        }

        public function clear():void {
        }

        public function set x(value:int):void {
        }

        public function set y(value:int):void {
        }

        public function applyFilter(value:ColorMatrix):void {
        }

        public function removeFilter():void {

        }

        public function set animationSpeed(value:Number):void {

        }
    }
}
