package com.berry.animation.core {
    import flash.display.DisplayObject;

    import org.dzyga.callbacks.Promise;
    import org.dzyga.geom.Rect;

    public interface IAssetViewAspect {
        function get view():DisplayObject

        function get isRendered():Boolean

        function get finishRenderPromise():Promise
        function get boundsUpdatePromise():Promise

        function get bounds():Rect;

        function play():void

        function setVisible(value:Boolean):void

        function hitTest(globalX:int, globalY:int, checkContainer:Boolean = false):Boolean;

        function init():void;

        function clear():void;
    }
}
