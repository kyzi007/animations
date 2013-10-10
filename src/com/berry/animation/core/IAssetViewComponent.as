package com.berry.animation.core {
    import flash.display.DisplayObject;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.geom.Rect;

    public interface IAssetViewComponent {
        function get view():DisplayObject

        function set animationSpeed(value:Number):void

        function get isRendered():Boolean

        function get finishRenderPromise():Promise

        function get boundsUpdatePromise():Promise

        function get bounds():Rect;

        function set x(value:int):void

        function set y(value:int):void

        /**
         * refrash all
         */
        function play():void

        function renderAndDrawLock():void

        function renderAndDrawUnLock():void

        function hitTest(globalX:int, globalY:int, checkContainer:Boolean = false):Boolean;

        function init():void;

        function clear():void;

        function applyFilter(value:ColorMatrix):void

        function removeFilter():void

        function set smoothing(value:Boolean):void
    }
}
