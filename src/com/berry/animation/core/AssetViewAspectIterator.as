package com.berry.animation.core {
    import org.as3commons.collections.framework.IIterator;
    import org.as3commons.collections.iterators.ArrayIterator;

    internal class AssetViewAspectIterator implements IIterator {
        private var _iterator:ArrayIterator;

        public function AssetViewAspectIterator (assetView:AssetView) {
            var aspectList:Array = [];
            if (assetView.mainAspect) {
                aspectList.push(assetView.mainAspect);
            }
            if (assetView.shadowAspect) {
                aspectList.push(assetView.shadowAspect);
            }
            if (assetView.effectAspect) {
                aspectList.push(assetView.effectAspect);
            }
            _iterator = new ArrayIterator(aspectList);
        }

        public function next ():* {
            return _iterator.next();
        }

        public function hasNext ():Boolean {
            return _iterator.hasNext();
        }
    }
}
