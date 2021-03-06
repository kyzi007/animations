package {
    import com.berry.animation.library.AnimationSequenceData;
    import com.berry.animation.library.AnimationsList;
    import animation.MidnightAssetView;

    import com.berry.animation.core.AssetView;
    import com.berry.animation.library.AnimationLibrary;
    import com.berry.animation.library.AssetLibrary;

    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.FileReference;
    import flash.system.LoaderContext;
    import flash.text.TextField;
    import flash.text.TextFieldType;

    import org.dzyga.events.EnterFrame;

    [SWF(width=900, height=800)]
    public class EffectViewer extends Sprite {
        private var _flip:Boolean;
        public function EffectViewer() {
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;

            EnterFrame.dispatcher = stage;
            var loadBtn:TextField = createButton('select swf', onClickSelect);
            loadBtn.x = 10;
            loadBtn.y = 10;
            addChild(loadBtn);

            _frame = createButton('1', null);
            _frame.x = 150;
            _frame.y = 10;
            _frame.selectable = true;
            _frame.border = true;
            _frame.type = TextFieldType.INPUT;
            _frame.addEventListener(Event.CHANGE, onChangeFrame);
            addChild(_frame);

            var flip:TextField = createButton('flip', flipUpdate);
            flip.x = 300;
            flip.y = 10;
            addChild(flip);

            _log = new TextField();
            _log.width = 400;
            _log.height = 500;
            _log.border = true;
            _log.x = 10;
            _log.y = 50;
            addChild(_log);

        }

        private function flipUpdate(e):void {
            _flip =!_flip;
            _asset.flip = _flip
        }

        private static var _log:TextField;
        private var _frame:TextField;
        private var _name:String;
        private var _assetLib:AssetLibrary = new AssetLibrary('');
        private var _animLib:AnimationLibrary = new AnimationLibrary();
        private var _asset:MidnightAssetView;
        private var _f:FileReference;

        public static function log(...strings):void {
            //return;
            for each (var string:String in strings) {
                if (_log) _log.appendText(string + ' ');
                //trace(string);
            }
            if (_log) _log.appendText('\n');
        }

        private function createButton(label:String, callback:Function):TextField {
            var tf:TextField = new TextField();
            tf.text = label;
            tf.width = 120;
            tf.height = 20;
            tf.background = true;
            tf.selectable = false;
            tf.backgroundColor = 0xcccccc;
            if (callback != null) {
                tf.addEventListener(MouseEvent.CLICK, callback);
            }
            return tf;
        }

        private function onChangeFrame(event:Event):void {
            if (_asset) {
                _asset.stepFrame = int(_frame.text);
                _asset.playByName(AnimationsList.IDLE)
            }
        }

        private function onClickSelect(event:Event):void {
            _f = new FileReference();
            _f.browse();
            _f.addEventListener(Event.SELECT, onSelect);
            _f.addEventListener(Event.COMPLETE, onLoad);
        }

        private function onSelect(event:Event):void {
            _f.load();
        }

        private function onLoad(event:Event):void {
            _name = _f.name.replace('.swf', '');
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.INIT, onLoadMc, false, 0, true);
            var lc:LoaderContext = new LoaderContext(false);
            lc.allowCodeImport = true;
            loader.loadBytes(_f.data, lc);
        }

        private function onLoadMc(event:Event):void {
            _f = null;
            var loaderInfo:LoaderInfo = (event.target as LoaderInfo);
            var clipClass:Class;
            try {
                clipClass = loaderInfo.applicationDomain.getDefinition(_name) as Class;
            } catch (err:Error) {
                log(_name + ' некорректное имя внутри');
            }
            if (clipClass) {
                if (_asset) {
                    removeChild(_asset.view);
                    removeChild(_asset.shadow);
                    _asset.clear();
                    _assetLib.gcForce();
                }

                _assetLib.registerAsset(clipClass, _name, loaderInfo);
                _animLib.parseAsset(_name, new clipClass);

                _asset = new MidnightAssetView(_name, _name);
                _asset.shadowAspectInit()
                        .classicMainAspectInit()
                        .effectAspectInit();
                _asset.cache = false;
                _asset.effectMode = true;
                _asset.stepFrame = int(_frame.text);
                _asset.init(_assetLib, _animLib);

                _asset.shadow.alpha = 0.4;

                _asset.x = 600;
                _asset.y = 600;


                //_asset.flip = true;
                var animationModel:AnimationSequenceData = _animLib.getAnimationModel(_name,'idle', int(_frame.text));
                animationModel.loop =false;
                _asset.animationSpeed = 2;
                _asset.playByModel(animationModel);

                addChildAt(_asset.view, 0);
                addChildAt(_asset.shadow, 0);
            }

        }

        private function enteframe(event:Event):void {
            trace(_asset.shadow.y)
        }

    }
}
