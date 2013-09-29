package com.berry.animation.test {
    import com.berry.animation.core.AssetView;
    import com.berry.animation.data.RotateEnum;
    import com.berry.animation.library.AnimationModel;

    public class MyGameObjectView extends AssetView{
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
            if(data.animationModel){
                _flipWaitUpdate = false;
                if (data.animationModel.currentPart().isRotateSupport(RotateEnum.FLIP)) {

                } else {
                    shadow.scaleX = _flip ? -1 : 1;
                    view.scaleX = _flip ? -1 : 1;
                }
                var tmp:Number = _widthInCell;
                _widthInCell = _heightInCell;
                _heightInCell = tmp;
                //rotation = _flip ? AssetViewOld.ROTATE_FLIP : AssetViewOld.ROTATE_NONE;

            } else {
                _flipWaitUpdate = true;
            }
        }


        override public function playByModel(animationModel:AnimationModel):void {
            if(_flipWaitUpdate && animationModel){
                data.animationModel = animationModel;
                flip = _flip;
            }
            super.playByModel(animationModel);
        }
    }
}
