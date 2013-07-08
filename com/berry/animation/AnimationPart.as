package com.berry.animation {

    public dynamic class AnimationPart {
        public function AnimationPart (totalFrames:int, rotate:String):void {
            _totalFrames = totalFrames;
            addSupportRotate(rotate);
        }

        private var _isLoop:Boolean;
        private var _loopCount:int;
        private var _complex:Boolean;
        private var _randomTime:int;
        private var _totalFrames:int;
        private var _supportRotate:Array = []; // used '' in values
        private var _loopSet:Boolean;
        private var _randomTimeSet:Boolean;
        private var _complexSet:Boolean;

        public function addSupportRotate (value:String):void {
            if (_supportRotate.indexOf(value) == -1) {
                _supportRotate.push(value);
            }
        }

        public function isRotateSupport (value:String):Boolean {
            for (var i:int = 0; i < _supportRotate.length; i++) {
                if (_supportRotate[i] == value) return true;
            }
            return false;
        }

        public function get supportRotateList ():Array {
            return _supportRotate;
        }

        public function parse (obj:Object):void {
            if (!obj) return;
            if (obj.hasOwnProperty('loopCount')) {
                _loopCount = obj.loopCount;
                _isLoop = _loopCount == 0;
                _loopSet = true;
            }
            if (obj.hasOwnProperty('randomTime')) {
                _randomTime = obj.randomTime;
                _randomTimeSet = true;
            }
            if (obj.hasOwnProperty('complex')) {
                _complex = obj.complex;
                _complexSet = true;
            }
            if (obj.hasOwnProperty('totalFrames')) {
                _totalFrames = obj.totalFrames;
            }
        }

        public function get isLoop ():Boolean {
            return _isLoop;
        }

        public function get loopCount ():int {
            return _loopCount;
        }

        public function get complex ():Boolean {
            return _complex;
        }

        public function get randomTime ():int {
            return _randomTime;
        }

        public function get totalFrames ():int {
            return _totalFrames;
        }

        public function get loopSet ():Boolean {
            return _loopSet;
        }

        public function get randomTimeSet ():Boolean {
            return _randomTimeSet;
        }

        public function get complexSet ():Boolean {
            return _complexSet;
        }
    }
}
