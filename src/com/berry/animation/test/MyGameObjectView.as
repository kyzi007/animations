package com.berry.animation.test {
    import com.berry.animation.core.GameObjectView;
    import com.berry.animation.data.RotateEnum;
    import com.berry.animation.library.AnimationModel;

    public class MyGameObjectView extends GameObjectView{
        private var _flip:Boolean;
        private var _flipWaitUpdate:Boolean;
        private var _widthInCell:int;
        private var _heightInCell:int;


        public function MyGameObjectView(id:String, name:String, widthInCell:int = 0, heightInCell:int = 0) {
            super(id, name);
            _widthInCell = widthInCell;
            _heightInCell = heightInCell;
        }

        public function get flip():Boolean {
            return _flip;
        }

        public function set flip(value:Boolean):void {
            _flip = value;
            if(_data.animationModel){
                _flipWaitUpdate = false;
                if (_data.animationModel.currentPart().isRotateSupport(RotateEnum.FLIP)) {

                } else {
                    shadowSprite.scaleX = _flip ? -1 : 1;
                    mainSprite.scaleX = _flip ? -1 : 1;
                }
                var tmp:Number = _widthInCell;
                _widthInCell = _heightInCell;
                _heightInCell = tmp;
                rotation = _flip ? GameObjectView.ROTATE_FLIP : GameObjectView.ROTATE_NONE;

            } else {
                _flipWaitUpdate = true;
            }
        }


        override public function playByModel(animationModel:AnimationModel):void {
            if(_flipWaitUpdate && animationModel){
                _data.animationModel = animationModel;
                flip = _flip;
            }
            super.playByModel(animationModel);
        }
    }
}
