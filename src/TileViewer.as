package {
    import com.berry.animation.core.AssetView;
    import animation.AnimationsList;
    import com.berry.animation.library.AnimationLibrary;
    import com.berry.animation.library.AssetLibrary;

    import explore.view.components.TileView;

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
    public class TileViewer extends Sprite {
        public function TileViewer() {
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;

            EnterFrame.dispatcher = stage;
            var loadBtn:TextField = createButton('select png', onClickSelect);
            loadBtn.x = 10;
            loadBtn.y = 10;
            addChild(loadBtn);

            _frame = createButton('1', null);
            _frame.x = 150;
            _frame.y = 10;
            _frame.selectable = true;
            _frame.border = true;
            _frame.type = TextFieldType.INPUT;
            _frame.addEventListener(Event.CHANGE, onChangeFrame)
            addChild(_frame);

            _log = new TextField();
            _log.width = 400;
            _log.height = 500;
            _log.border = true;
            _log.x = 10;
            _log.y = 50;
            addChild(_log);

        }

        private static var _log:TextField;
        private var _frame:TextField;
        private var _name:String;
        private var _assetLib:AssetLibrary = new AssetLibrary('');
        private var _animLib:AnimationLibrary = new AnimationLibrary();
        private var _asset:AssetView;
        private var _f:FileReference;
        private var i:int;

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

        private function place(i2:int, i22:int):void {
            _asset = new TileView(_name, _name);
            _asset.animationLibrary = _animLib;
            _asset.assetLibrary = _assetLib;
            _asset.cache = false;
            _asset.effectMode = true;
            _asset.preloaderMode = false;
            _asset.stepFrame = int(_frame.text);
            _asset.init();

            _asset.mainSprite.x = 600;
            _asset.mainSprite.y = 600;
            _asset.visible = true;

            addChildAt(_asset.mainSprite, 0);
            _asset.mainSprite.x = i2;
            _asset.mainSprite.y = i22;
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
            i++;
            _name = _f.name.replace('.swf', '');
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.INIT, onLoadMc, false, 0, true);
            var lc:LoaderContext = new LoaderContext(false);
            lc.allowCodeImport = true;
            loader.loadBytes(_f.data, lc);
        }

        private function onLoadMc(event:Event):void {
            _name = _f.name.replace('.png', '');
            _f = null;
            var loaderInfo:LoaderInfo = (event.target as LoaderInfo);
            _assetLib.registerAsset(loaderInfo.content, _name, loaderInfo);
            i++;
            for (var j:int = 0; j < 8; j++) {
                place(j * 95 + 100, i * 23)
            }
            i++;
            for (var j:int = 0; j < 8; j++) {
                place(j * 95 + 100 +47, i * 23)
            }
            i++;
            for (var j:int = 0; j < 8; j++) {
                place(j * 95 + 100, i * 23)
            }

        }

    }
}
