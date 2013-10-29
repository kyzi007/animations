package com.berry.animation.library {

    public dynamic class AnimationPart {
        public function AnimationPart(totalFrames:int, rotate:String):void {
            _totalFrames = totalFrames;
            addSupportRotate(rotate);
        }

        private var _fullName:String = null;
        private var _isLoop:Boolean = true;
        private var _loopCount:int = 0;
        private var _pauseTime:int = 0;
        private var _randomTime:int = 0;
        private var _totalFrames:int = 0;
        private var _supportRotate:Array = [];
        private var _complex:Boolean = false;
        private var _isEffect:Boolean = false;
        private var _effectStates:Array = null;

        public function addSupportRotate(value:String):void {
            if (_supportRotate.indexOf(value) == -1) {
                _supportRotate.push(value);
            }
        }

        public function isRotateSupport(value:String):Boolean {
            for (var i:int = 0; i < _supportRotate.length; i++) {
                if (_supportRotate[i] == value) return true;
            }
            return false;
        }

        public function parse(obj:Object, fullName:String):void {
            _fullName = fullName;
            if (!obj) return;
            if (obj.hasOwnProperty('loopCount')) {
                _loopCount = obj.loopCount;
                _isLoop = _loopCount == 0;
            }
            if (obj.hasOwnProperty('loop')) {
                _isLoop = obj.loop;
            }
            if (obj.hasOwnProperty('randomTime')) {
                _randomTime = obj.randomTime;
                _isLoop = true;
                _loopCount = 0;
            }
            if (obj.hasOwnProperty('complex')) {
                _complex = obj.complex;
            }
            if (obj.hasOwnProperty('totalFrames')) {
                _totalFrames = obj.totalFrames;
            }
            if (obj.hasOwnProperty('effect')) {
                _isEffect = obj['effect'];
            }
            if (obj.hasOwnProperty('pauseTime')) {
                _pauseTime = obj['pauseTime'];
            }
            if (_isEffect) {
                _effectStates = obj.states;
            }
        }

        public function get isLoop():Boolean {
            return _isLoop;
        }

        public function get loopCount():int {
            return _loopCount;
        }

        public function get complex():Boolean {
            return _complex;
        }

        public function get randomTime():int {
            return _randomTime;
        }

        public function get totalFrames():int {
            return _totalFrames;
        }

        public function get isEffect():Boolean {
            return _isEffect;
        }

        public function get effectStates():Array {
            return _effectStates;
        }

        public function get fullName():String {
            return _fullName;
        }

        public function get pauseTime():int {
            return _pauseTime;
        }
    }
}
