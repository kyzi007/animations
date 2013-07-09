package com.berry.animation.library {
    import com.berry.animation.AnimationModel;
    import com.berry.animation.AnimationPart;
    import com.berry.animation.graphic.AnimationsList;
    import com.berry.animation.graphic.RotateEnum;

    import flash.display.MovieClip;

    import org.dzyga.pool.Pool;

    public class AnimationLibrary {
        /**
         * клип для анимации может называться idle_state_1_1_rotate, коротким именем анимации будет в этом случае авляться idle
         * state[0] будет использоваться для последовательного проигрывания частей анимации state[1] используется для проигрывания вариантов последовательной анимации
         * например - лошадь умеет сидеть и стоять, стоя она качает головой и перебирает ногами, сидя - только мотать головой и есть анимация процесса вставания
         * лошадь сидит - idle_state_0
         * лошадь встает idle_state_1
         * лошадь стоит idle_state_2_0, idle_state_2_1
         * для того чтобы проиграть эту последовательность корректно существуют дополнительные параметры анимации
         * в клипе с анимациями animationData (необязательный, в нем может указываться только часть анимаций)
         * по умолчанию анимация проигрывается бесконечно, но можно задать - loopCount, randomTime, complex
         * loopCount - количество повторений после котого пройдет попытка найти следующую анимацию (рыцарь может только раз посмотреть в зеркало)
         * randomTime - если движения равномерны, например лошадь начала покачивать головой то можно проигрывать в течении некоторого времени (randomTime*random + 0.5*randomTime)
         * complex - анимации которые нежелательно прерывать, например рыцарь смотрит в зеркало, пока не досмотрит не стоит начинать анимацию движения ибо криво
         */

        /**
         * список всех пресетов анимаций
         */
        public static var _animationPresetList:Object = {};
        private static var _interactAnimations:Object = {
            interact: 'interact',
            hatchet: 'hatchet',
            pickaxe: 'pickaxe',
            shovel: 'shovel',
            hammer: 'hammer',
            magic_wood: 'magic_wood',
            magic_wood_fight: 'magic_wood_fight'
        };

        /**
         * Записываем список возможных анимаций, вычисляем для них параметры, забираем вручную заданные параметры анимаций из swf
         * @param clip
         * @param assetName
         */
        public static function parseWyseClip (clip:MovieClip, assetName:String):void {
            _animationPresetList[assetName] = [];
            clip.gotoAndStop(1);

            var data:Object = clip['animationData'];
            for (var frame:int = 1; frame < clip.totalFrames + 1; frame++) {
                var clipData:Object = data && data[frame - 1] ? data[frame - 1] : {};
                clip.gotoAndStop(frame);
                _animationPresetList[assetName][frame] = parseClipFrame(clipData, clip, assetName);
            }
        }

        /**
         * @param assetName
         * @param animationName
         * @param step
         * @return существует ли пресет на анимацию
         */
        public static function hasAnimationQuery (assetName:String, animationName:String, step:uint = 1):Boolean {
            return _animationPresetList[assetName] && _animationPresetList[assetName][step] && _animationPresetList[assetName][step][animationName];
        }

        /**
         *
         * @param assetName
         * @param animationName
         * @param step
         * @return пресет для анимации по ее короткому имени
         * _animationPresetList имя ассета / степ / анимация / часть анимации / случайный вариант части
         */
        public static function getAnimationQueryInstance (assetName:String, animationName:String, step:uint = 1):AnimationModel {
            if (assetName == "npc_angree_tree") {
                trace()
            }
            var animationData:AnimationModel = Pool.get(AnimationModel) as AnimationModel;
            var presets:* = findInPath(_animationPresetList, assetName, step, animationName);

            /*
             CONFIG::debug{
             if (!presets) {
             KLog.log('AnimationLibrary : getAnimationQueryInstance invalid animation ( ' + assetName + '/' + animationName + '/' + step + ' )', KLog.ERROR);
             return null;
             }
             }
             */

            animationData.step = step;
            animationData.setPresetList(presets);
            animationData.shotName = animationName;
            return animationData;
        }

        public static function findInPath (obj:Object, ...keys):* {
            var res:* = obj;
            for (var i:int = 0; i < keys.length; i++) {
                var key:String = keys[i];
                res = res.hasOwnProperty(key) ? res[key] : null;
                if (res == null || res == undefined) return null;
            }
            return res;
        }

        public static function getInteractAnimationById (asset:String, id:String):String {
            var result:String = _interactAnimations[id];
            if (!result) {
                // CONFIG::debug{ KLog.log("AnimationLibrary : getInteractAnimationById  " + 'invalid interact key ' + id, KLog.ERROR); }
                return AnimationsList.INTERACT;
            }
            if (!getAnimationQueryInstance(asset, result)) {
                // CONFIG::debug{ KLog.log("AnimationLibrary : getInteractAnimationById  " + 'invalid animation in ' + asset + ' ' + result, KLog.ERROR); }
                return AnimationsList.INTERACT;
            }
            return result;
        }

        public static function findClassInstance (obj:Object, classId:Class, ...keys):* {
            if (!obj) {
                return null;
            }
            var res:* = obj;
            if (res is classId) return res;
            for (var i:int = 0; i < keys.length; i++) {
                var key:String = keys[i];
                res = res.hasOwnProperty(key) ? res[key] : null;
                if (res == null || res == undefined) return null;
                if (res is classId) return res;
            }
            return null;
        }

        private static function parseClipFrame (clipData:Object, clip:MovieClip, assetName:String):Object {

            var result:Object = {}; // shotName // state // sub state
            result.animations = [];

            for (var i:int = 0; i < clip.numChildren; i++) {
                var child:MovieClip = clip.getChildAt(i) as MovieClip;
                if (child) {

                    var nameParse:Array;
                    var shotName:String;
                    var states:Array;
                    var state:int;
                    var subState:int;
                    var rotation:String
                    var name:String = child.name;
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

                    var otherRotate:AnimationPart = findClassInstance(result, AnimationPart, shotName, state, subState) as AnimationPart;
                    if (otherRotate) {
                        otherRotate.addSupportRotate(rotation);
                        continue;
                    }

                    var animFlag:Boolean = true;
                    for each (var anim:String in result.animations) {
                        if (shotName == anim) {
                            animFlag = false;
                        }
                    }
                    if (animFlag)result.animations.push(shotName);

                    var preset:AnimationPart = new AnimationPart(child.totalFrames, rotation);
                    preset.parse(clipData[name]);

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
            }
            return result;
        }
    }
}
