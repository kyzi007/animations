package com.berry.animation.core {
    import animation.*;

    import com.berry.animation.library.AssetData;

    import common.map.view.component.Cell;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayUtils;
    import org.dzyga.geom.Rect;

    public class TileMainAspect implements IAssetViewAspect {
        private var _view:Bitmap;
        private var _assetSprite:AssetSprite;
        public function TileMainAspect(parent:AssetView) {
            _parent = parent;
        }

        private const _BOUNDS:Rect = new Rect(-Cell.CELL_DX, -Cell.CELL_DY, Cell.CELL_WIDTH, Cell.CELL_HEIGHT);
        private var _parent:AssetView;
        private var _assetData:AssetData;
        private var _visible:Boolean;

        public function play():void {
            // drawn only once
            if(!_assetSprite.currentFrameData){
                _assetSprite.setVisible(true);
                _assetSprite.draw(_assetData.frames[int(Math.random()* _assetData.frames.length)]);
                _assetSprite.setVisible(_visible);
                _assetData.completeRenderPromise.callbackRemove(renderFinishCallback);
            }
        }

        public function setVisible(value:Boolean):void {
            _visible = value;
            _assetSprite.setVisible(value);
        }

        public function get view():DisplayObject {
            return _view;
        }

        public function get isRendered():Boolean {
            return _assetData.isRenderFinish;
        }

        public function get finishRenderPromise():Promise {
            return null;
        }

        public function get bounds():Rect {
            return _BOUNDS;
        }

        public function hitTest(globalX:int, globalY:int, checkContainer:Boolean = false):Boolean {
            return DisplayUtils.hitTest(_view, globalX, globalY, checkContainer);
        }

        public function init():void {
            _assetSprite = new AssetSprite(_parent.data.assetName);
            _assetData = _parent.assetLibrary.getAssetData(_parent.data.getQuery(AnimationsList.IDLE));
            _assetData.useCount++;
            if(_assetData.isRenderFinish){
                play();
            } else {
                _assetData.completeRenderPromise.callbackRegister(renderFinishCallback);
            }
        }

        private function renderFinishCallback(...patams):void {
            play();
        }

        public function clear():void {
            _assetData.useCount--;
        }

        public function get boundsUpdatePromise():Promise {
            return _assetSprite.boundsUpdatePromise;
        }

        public function set x(value:int):void {
            view.x = value;
        }

        public function set y(value:int):void {
            view.y = value;
        }

        public function applyFilter(value:ColorMatrix):void {
            // TODO
        }

        public function removeFilter():void {
        }

        public function set animationSpeed(value:Number):void {
            // none
        }
    }
}
