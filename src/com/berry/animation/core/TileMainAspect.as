package com.berry.animation.core {
    import animation.*;
    import com.berry.animation.core.AssetSprite;
    import com.berry.animation.library.AssetData;

    import common.map.view.component.Cell;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;

    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayUtils;
    import org.dzyga.geom.Rect;

    public class TileMainAspect implements IAssetViewAspect {
        private var _view:Bitmap;
        private var _assetSprite:AssetSprite;
        public function TileMainAspect(parent:AssetViewNew) {
            _parent = parent;
        }

        private const _BOUNDS:Rect = new Rect(-Cell.CELL_DX, -Cell.CELL_DY, Cell.CELL_WIDTH, Cell.CELL_HEIGHT);
        private var _parent:AssetViewNew;
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
            _assetSprite = new AssetSprite(_parent._data.assetName);
            _assetData = _parent._assetLibrary.getAssetData(_parent._data.getQuery(AnimationsList.IDLE));
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
    }
}
