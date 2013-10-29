package com.berry.animation.library {
    import com.berry.animation.utils.Search;
    import com.berry.animation.utils.Search;
    import com.berry.events.SimpleEventDispatcher;

    import org.dzyga.pool.IReusable;

    public class AnimationSequenceData extends SimpleEventDispatcher implements IReusable {
        public function AnimationSequenceData() {
        }

        private var data:*;
        private var _animationShotName:String;

        private var _loop:Boolean = true;
        private var _loopTime:int = 0;
        private var _sequenceLoopCount:int;

        private var _startFrame:int = 0;
        private var _assetFrame:int = 1;

        private var _animationState:int = 0;
        private var _animationSubState:int = 0;

        private var _isListEnd:Boolean = false;
        private var _completeSubStates:Array = [];

        private var _updateCurrent:Boolean;
        private var _currentPreset:AnimationPart;

        private var _play:Boolean = true;
        private var _isFullAnimation:Boolean = true;

        public function currentPart():AnimationPart {
            if (_updateCurrent || !_currentPreset) {
                _currentPreset = Search.findClassInstance(data, AnimationPart, null, _animationState, _animationSubState);
                _updateCurrent = false;
                if (Search.getCountClassInstance(data, AnimationPart, null) == 1) {
                    _isListEnd = true;
                }
            }
            return _currentPreset;
        }

        public function nextPresetRandom():void {
            if (!isState) {
                _animationSubState = 0;
                _animationState = 0;
                _isListEnd = true;
                return;
            }
            if (!_completeSubStates[_animationState]) {_completeSubStates[_animationState] = 0}
            _isListEnd = false;
            if (isSubStates) {
                if (_completeSubStates[_animationState] > subStateCount * 1.5) {
                    _completeSubStates[_animationState] = 0;
                    _animationState++;
                    if (isSubStates) {
                        _completeSubStates[_animationState]++;
                        _animationSubState = Math.floor(subStateCount * Math.random());
                    }
                } else {
                    _completeSubStates[_animationState]++;
                    _animationSubState = Math.floor(subStateCount * Math.random());
                }
            } else {
                _animationSubState = 0;
                _animationState++;
            }

            if (!data[_animationState]) {
                _animationSubState = 0;
                _animationState = 0;
                _isListEnd = true;
            }
            _updateCurrent = true;
        }

        public function reset():void {
            clearAllCallbacks();
            _startFrame = 0;
            _sequenceLoopCount = 0;
            _loop = false;
            _animationShotName = null;
            _assetFrame = 1;
            _animationState = 0;
            _animationSubState = 0;
            _isListEnd = false;
            _loopTime = 0;
            _isFullAnimation = true;
            data = null;
            _completeSubStates = [];
            _currentPreset = null;
            _updateCurrent = false;
            _play = true;
        }

        public function setPartList(value:*):AnimationSequenceData {
            data = value;
            _updateCurrent = true;
            return this;
        }

        public function get complex():Boolean {
            return currentPart().complex;
        }

        public function get fullAnimationName():String {
            var name:String = _animationShotName;
            if (isState) {
                name += '_state_' + _animationState;
            }
            if (isSubStates) {
                name += '_' + _animationSubState;
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

        private function get isState():Boolean {return data is Array;}

        public function get isSubStates():Boolean {
            return data ? data[_animationState] && data[_animationState] is Array : false;
        }

        public function get loop():Boolean {
            return  _loop;
        }

        public function set loop(value:Boolean):void {_loop = value;}

        // todo delete magic
        public function get sequenceLoopCount():int {
            return currentPart().loopSet ? currentPart().loopCount : _sequenceLoopCount;
        }

        public function set sequenceLoopCount(value:int):void {_sequenceLoopCount = value; }

        public function get loopTime():int {return _loopTime; }

        public function set loopTime(value:int):void {_loopTime = value;}

        private function get subStateCount():int {
            return isSubStates ? data[_animationState].length : 0;
        }

        public function get reflection():Class {return AnimationSequenceData;}

        public function get animationShotName():String {return _animationShotName;}

        public function set animationShotName(value:String):void {_animationShotName = value;}

        public function get startFrame():int {return _startFrame;}

        public function set startFrame(value:int):void {_startFrame = value;}

        public function get animationState():int {return _animationState;}

        public function set animationState(value:int):void {_animationState = value;}

        public function get assetFrame():int {return _assetFrame;}

        public function set assetFrame(value:int):void {_assetFrame = value; }

        public function get animationSubState():int {return _animationSubState;}

        public function set animationSubState(value:int):void {
            _animationSubState = value;
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
