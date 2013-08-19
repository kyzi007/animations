package com.berry.animation.library {
    import com.berry.animation.data.AnimationsList;
    import com.berry.animation.data.RotateEnum;

    import flash.display.Bitmap;
    import flash.display.MovieClip;

    import log.logServer.KLog;

    import org.dzyga.pool.Pool;

    public class AnimationLibrary {
        public function AnimationLibrary() {
        }

        private var _animationPresetList:Object = {};
        private var _effectCache:Object = {};
        public var tileWidth:int = 45;
        public var tileHeight:int = 90;
        private var _partMode:Array = [];



        public function getAnimationModel(assetName:String, animationName:String, step:uint = 1):AnimationModel {
            var animationModel:AnimationModel = Pool.get(AnimationModel) as AnimationModel;
            var parts:* = findInPath(_animationPresetList, assetName, step, animationName);

            if (!parts) {
                CONFIG::debug{
                    KLog.log('AnimationLibrary : getAnimationQueryInstance invalid animation ( ' + assetName + '/' + animationName + '/' + step + ' )', KLog.ERROR);
                }
                return null;
            }

            animationModel.step = step;
            animationModel.setPartList(parts);
            animationModel.shotName = animationName;
            return animationModel;
        }

        public function findInPath(obj:Object, ...keys):* {
            var res:* = obj;
            for (var i:int = 0; i < keys.length; i++) {
                var key:String = keys[i];
                res = res.hasOwnProperty(key) ? res[key] : null;
                if (res == null || res == undefined) return null;
            }
            return res;
        }

        public function getAnimationEffects(assetName:String, animationName:String, step:uint = 1):Object {
            if (_effectCache[assetName + animationName + step]) {
                return _effectCache[assetName + animationName + step];
            } else {
                _effectCache[assetName + animationName + step] = {};
                var assetPresets:Object = _animationPresetList [assetName] ? _animationPresetList [assetName][step] : null;
                for each (var animationParts:Object in assetPresets) {
                    if(animationParts is AnimationPart){
                        // плоская структура
                        if (animationParts.isEffect && animationParts.effectStates.indexOf(animationName) != -1) {
                            var animationData:AnimationModel = Pool.get(AnimationModel) as AnimationModel;
                            animationData.step = step;
                            animationData.setPartList(animationParts);
                            animationData.shotName = animationParts.fullName;
                            _effectCache[assetName + animationName + step][animationData.shotName] = animationData;
                        }
                    } else {
                        if(!(animationParts[0] is String)){
                            var animationDataAdvanced:AnimationModel = Pool.get(AnimationModel) as AnimationModel;
                            animationDataAdvanced.step = step;
                            animationDataAdvanced.setPartList(animationParts);
                            animationDataAdvanced.shotName = AnimationPart(animationParts[0][0]).fullName.split('_state')[0];// TODO наебнется на точном порядке
                            _effectCache[assetName + animationName + step][animationDataAdvanced.shotName] = animationDataAdvanced;
                        }
                    }
                }
                return _effectCache[assetName + animationName + step];
            }
        }

        public function parseAsset(assetName:String, source:*):void {
            _animationPresetList[assetName] = [];
            if (source is MovieClip) {
                source.gotoAndStop(1);

                var data:Object = source['animationData'];

                if(data && data.partMode){
                    _partMode[assetName] = true;
                    var result:Object = {};
                    result.animations = [];
                    for (var step:int = 0; step < data.stepsCount; step++) {
                        for (var clipName:String in data[step]) {
                            createData(clipName, data[step][clipName].totalFrames, result, data[step][clipName]);
                        }
                    }
                    _animationPresetList[assetName][step] = result;
                } else {
                    for (var frame:int = 1; frame < source.totalFrames + 1; frame++) {
                        var clipData:Object = data && data[frame - 1] ? data[frame - 1] : {};
                        source.gotoAndStop(frame);
                        _animationPresetList[assetName][frame] = parseClipFrame(clipData, source, assetName);
                    }
                }
            } else if(source is Bitmap){
                // force create animation structure
                _animationPresetList[assetName][1] = {animations:[AnimationsList.IDLE]}
                _animationPresetList[assetName][1][AnimationsList.IDLE] = new AnimationPart(int(source.width / tileHeight), RotateEnum.NONE);
            }
        }

        public function getIsComplexAsset(assetName:String):Boolean
        {
            return _partMode[assetName];
        }

        protected function parseClipFrame(clipData:Object, clip:MovieClip, assetName:String):Object {
            var result:Object = {}; // shotName // state // sub state or // fullName // effects
            result.animations = [];
            for (var i:int = 0; i < clip.numChildren; i++) {
                var child:MovieClip = clip.getChildAt(i) as MovieClip;
                if (child) {
                    createData(child.name, child.totalFrames, result, clipData[child.name]);
                }
            }
            return result;
        }

        private function createData(name:String, totalFrames:int, result:Object, clipData:Object):void {
            var nameParse:Array;
            var shotName:String;
            var states:Array;
            var state:int;
            var subState:int;
            var rotation:String
            var name:String = name;

            if (name.indexOf('_state_') != -1 || AnimationsList.isComplexName(name)) {
                nameParse = name.split('_state_');
                shotName = nameParse[0];
                states = nameParse[1] ? nameParse[1].split('_') : [];
                state = states[0] ? states[0] : -1;
                subState = states[1] ? states[1] : -1;
                rotation = states[2] ? states[2] : '';
            } else {
                var index:int = name.indexOf('_');
                if (index != -1) {
                    nameParse = [name.slice(0, index), name.slice(index, name.length)];
                } else {
                    nameParse = [name, RotateEnum.NONE];
                }
                shotName = nameParse[0];
                state = -1;
                subState = -1;
                rotation = nameParse[1];
            }

            if (!new RotateEnum().isExists(rotation)) {
                trace('аа, шото пошло не так в парсинге клипа');
            }

            var otherRotate:AnimationPart = findClassInstance(result, AnimationPart, null, shotName, state, subState) as AnimationPart;
            if (otherRotate) {
                otherRotate.addSupportRotate(rotation);
                return;
            }

            var animFlag:Boolean = true;
            for each (var anim:String in result.animations) {
                if (shotName == anim) {
                    animFlag = false;
                }
            }
            if (animFlag)result.animations.push(shotName);

            var preset:AnimationPart = new AnimationPart(totalFrames, rotation);

            preset.parse(clipData, name.replace(rotation, ''));

            if (state == -1) {
                result[shotName] = preset;
            } else {
                if (!result[shotName]) {
                    result[shotName] = [];
                }
                if (subState != -1 && !result[shotName][state]) {
                    result[shotName][state] = [];
                }
                if (subState != -1) {
                    result[shotName][state][subState] = preset;
                } else {
                    result[shotName][state] = preset;
                }
            }
        }

        private function findClassInstance(obj:Object, classId:Class, conditionFunction:Function, ...keys):* {
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
    }
}
