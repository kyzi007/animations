package animation {
    import animation.library.AnimationLibrary;

    import dzyga.pool.IReusable;

    import umerkiCommon.evens.SimpleEventDispatcher;

    public class AnimationModel extends SimpleEventDispatcher implements IReusable {
        public function AnimationModel() {
        }

        private var _startFrame:int = 0;
        private var _loopCount:int;
        private var _loop:Boolean;
        private var _shotName:String;
        private var _step:int = 1;
        private var _state:int = 0;
        private var _subState:int = 0;
        private var _loopList:Boolean = true;
        private var _isListEnd:Boolean = false;
        private var _loopTime:int = 0;
        private var _isFullAnimation:Boolean = true;
        private var _presetList:*;
        private var _completeStates:Array = [];
        private var _completeSubStates:Array = [];
        private var _updateCurrent:Boolean;
        private var __currentPreset:AnimationPart;
        private var _complex:Boolean = false;

        public function _currentPreset():AnimationPart {
            if (_updateCurrent || !__currentPreset) {
                __currentPreset = AnimationLibrary.findClassInstance(_presetList, AnimationPart, _state, _subState);
                _updateCurrent = false;
            }
            return __currentPreset;
        }

        public function incrementState():void {
            if (!_completeStates[_state]) {
                _completeStates[_state] = 0;
            }

            if (_completeStates[_state] >= maxPlayCount - 1) {
                _state++;
            }

            _completeStates[_state]++;

            if (!_presetList[_state]) {
                loopEnumeration();
            }
        }

        public function incrementSubState():void {
            if (isSubStates) {
                _subState++;
                if (!_presetList[_state][_subState]) {
                    loopEnumeration();
                }
            }
        }

        public function nextPreset():void {
            if (!isState) {
                loopEnumeration();
                return;
            }
            incrementState();
            incrementSubState();
            _updateCurrent = true;
        }

        public function nextPresetRandom():void {
            if (!isState) {
                loopEnumeration();
                return;
            }
            incrementState();
            incrementSubStateRandom();
            _updateCurrent = true;
        }

        public function reset():void {
            clearAllCallbacks();
            _startFrame = 0;
            _loopCount = 0;
            _loop = false;
            _shotName = null;
            _step = 1;
            _state = 0;
            _subState = 0;
            _loopList = true;
            _isListEnd = false;
            _loopTime = 0;
            _isFullAnimation = true;
            _presetList = null;
            _completeStates = [];
            _completeSubStates = [];
            __currentPreset = null;
            _updateCurrent = false;
            _complex = false;
        }

        public function setPresetList(value:*):AnimationModel {
            _presetList = value;
            _updateCurrent = true;
            return this;
        }

        private function incrementSubStateRandom():void {
            if (isSubStates) {
                _subState = int(maxPlayCount * Math.random());
            }
            if (!_completeSubStates[_subState]) {
                _completeSubStates[_subState] = 0;
            }
            _completeSubStates[_subState]++;
            if (_completeStates[_subState] > maxPlayCount) {
                loopEnumeration();
            }
        }

        private function loopEnumeration():void {
            _subState = 0;
            _state = 0;
            _isListEnd = true;
        }

        public function get complex():Boolean {
            return _currentPreset().complexSet ? _currentPreset().complex : complex;
        }

        public function set complex(value:Boolean):void {_complex = value;}

        public function get fullPartAnimationName():String {
            var name:String = _shotName;
            if (isState) {
                name += '_state_' + _state;
            }
            if (isSubStates) {
                name += '_' + _subState;
            }
            return name;
        }

        public function get isFullAnimation():Boolean {
            return _isFullAnimation;
        }

        public function set isFullAnimation(value:Boolean):void {
            _isFullAnimation = value;
        }

        public function get isListEnd():Boolean {
            return _isListEnd;
        }

        public function set isListEnd(value:Boolean):void {
            _isListEnd = value;
        }

        private function get isState():Boolean {return _presetList is Array;}

        public function get isSubStates():Boolean {return _presetList ? _presetList[_state] && _presetList[_state] is Array : -1;}

        public function get loop():Boolean {
            return _currentPreset().loopSet ? _currentPreset().isLoop : _loop;
        }

        public function set loop(value:Boolean):void {_loop = value;}

        public function get loopCount():int {
            return _currentPreset().loopSet ? _currentPreset().loopCount : _loopCount;
        }

        public function set loopCount(value:int):void {_loopCount = value; }

        public function get loopTime():int {return _loopTime; }

        public function set loopTime(value:int):void {_loopTime = value;}

        private function get maxPlayCount():int {
            return isSubStates ? _presetList[_state].length : 1;
        }

        public function get reflection():Class {return AnimationModel;}

        public function get shotName():String {return _shotName;}

        public function set shotName(value:String):void {_shotName = value;}

        public function get startFrame():int {return _startFrame;}

        public function set startFrame(value:int):void {_startFrame = value;}

        public function get state():int {return _state;}

        public function set state(value:int):void {_state = value;}

        public function get step():int {return _step;}

        public function set step(value:int):void {_step = value; }

        public function get subState():int {return _subState;}

        public function set subState(value:int):void {_subState = value;}

        public function get totalFrame():uint {return _currentPreset().totalFrames;}
    }
}
