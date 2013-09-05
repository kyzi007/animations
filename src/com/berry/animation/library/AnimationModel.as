package com.berry.animation.library {
    import com.berry.events.SimpleEventDispatcher;

    import org.dzyga.pool.IReusable;

    public class AnimationModel extends SimpleEventDispatcher implements IReusable {
        public function AnimationModel() {
        }

        private var _startFrame:int = 0;
        private var _loopCount:int;
        private var _loop:Boolean = true;
        private var _shotName:String;
        private var _step:int = 1;
        private var _state:int = 0;
        private var _subState:int = 0;
        private var _loopList:Boolean = true;
        private var _isListEnd:Boolean = false;
        private var _loopTime:int = 0;
        private var _isFullAnimation:Boolean = true;
        private var _partList:*;
        private var _completeSubStates:Array = [];
        private var _updateCurrent:Boolean;
        private var _currentPreset:AnimationPart;
        private var _play:Boolean = true;

        public static function findClassInstance(obj:Object, classId:Class, conditionFunction:Function, ...keys):* {
            if (!obj) {
                return null;
            }
            var res:* = obj;
            if (res is classId && (conditionFunction == null || conditionFunction(res))) return res;
            for (var i:int = 0; i < keys.length; i++) {
                var key:String = keys[i];
                res = res.hasOwnProperty(key) ? res[key] : null;
                if (res == null || res == undefined) return null;
                if (res is classId && (conditionFunction == null || conditionFunction(res))) return res;
            }
            return null;
        }

        public function currentPart():AnimationPart {
            if (_updateCurrent || !_currentPreset) {
                _currentPreset = findClassInstance(_partList, AnimationPart, null, _state, _subState);
                _updateCurrent = false;
            }
            return _currentPreset;
        }

        public function nextPresetRandom():void {
            if (!isState) {
                loopEnumeration();
                return;
            }
            if(!_completeSubStates[_state]){_completeSubStates[_state] = 0}
            _isListEnd = false;
            if (isSubStates) {
                if (_completeSubStates[_state] > subStateCount*1.5) {
                    _completeSubStates[_state] = 0;
                    _state++;
                    if (isSubStates) {
                        _completeSubStates[_state]++;
                        _subState = Math.floor(subStateCount * Math.random());
                    }
                } else {
                    _completeSubStates[_state]++;
                    _subState = Math.floor(subStateCount * Math.random());
                }
            } else {
                _subState = 0;
                _state++;
            }

            if (!_partList[_state]) {
                loopEnumeration();
            }

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
            _partList = null;
            _completeSubStates = [];
            _currentPreset = null;
            _updateCurrent = false;
            _play = true;
        }

        public function setPartList(value:*):AnimationModel {
            _partList = value;
            _updateCurrent = true;
            return this;
        }

        private function loopEnumeration():void {
            _subState = 0;
            _state = 0;
            _isListEnd = true;
        }

        public function get complex():Boolean {
            return currentPart().complexSet ? currentPart().complex : complex;
        }

        public function get fullPartAnimationName():String {
            if (_subState == 2 && _state == 2) {
                trace()
            }
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

        private function get isState():Boolean {return _partList is Array;}

        public function get isSubStates():Boolean {
            return _partList ? _partList[_state] && _partList[_state] is Array : false;
        }

        public function get loop():Boolean {
            return  _loop;
        }

        public function set loop(value:Boolean):void {_loop = value;}

        public function get loopCount():int {
            return currentPart().loopSet ? currentPart().loopCount : _loopCount;
        }

        public function set loopCount(value:int):void {_loopCount = value; }

        public function get loopTime():int {return _loopTime; }

        public function set loopTime(value:int):void {_loopTime = value;}

        private function get subStateCount():int {
            return isSubStates ? _partList[_state].length : 0;
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

        public function set subState(value:int):void {
            _subState = value;
        }

        public function get totalFrame():uint {return currentPart().totalFrames;}

        public function get play():Boolean {
            return _play;
        }

        public function set play(value:Boolean):void {
            _play = value;
        }
    }
}
