package com.berry.animation.utils {
    import flash.display.Sprite;

    import org.dzyga.events.Action;
    import org.dzyga.events.EnterFrame;

    public class AlphaDecorator {
        public function AlphaDecorator(sprites:Vector.<Sprite>) {
            _sprites = sprites;
        }

        private var _currentAlpha:Number = 1;
        private var _sprites:Vector.<Sprite>;
        private var _alphaAction:Action;
        private var _targetAlpha:Number;
        private var _startAlpha:Number;

        private function changeAlpha():void {
            if (_targetAlpha > _startAlpha) {
                _currentAlpha += 0.08;
                if (_currentAlpha > _targetAlpha) {
                    _currentAlpha = _targetAlpha;
                    EnterFrame.removeAction(_alphaAction);
                    _alphaAction = null;
                }
            }
            else {
                _currentAlpha -= 0.08;
                if (_currentAlpha < _targetAlpha) {
                    _currentAlpha = _targetAlpha;
                    EnterFrame.removeAction(_alphaAction);
                    _alphaAction = null;
                }
            }
            for each (var sprite:Sprite in _sprites) {
                sprite.alpha = _currentAlpha;
            }
        }

        public function set alpha(value:Number):void {
            if (_currentAlpha == value) return;
            if (_alphaAction) {
                EnterFrame.removeAction(_alphaAction);
            }
            _alphaAction = EnterFrame.addAction(0, changeAlpha);
            _targetAlpha = value;
            _startAlpha = _currentAlpha;
        }
    }
}
