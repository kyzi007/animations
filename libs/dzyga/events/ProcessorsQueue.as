package dzyga.events {
    import dzyga.utils.ObjectUtils;

    import flash.errors.IllegalOperationError;
    import flash.utils.Dictionary;

    public class ProcessorsQueue extends Processor {
        public static const SUBSEQUENT : int = 0;
        public static const PARALLEL : int = 0;

        public var executionMode : int = PARALLEL;
        public var stopOnFail : Boolean = false;

        private var _queue : Vector.<IProcessor> = new <IProcessor>[];
        private var _schedule : Vector.<IProcessor>;
        private var _running : Dictionary = new Dictionary();

        public function ProcessorsQueue (...args) {
            for each (var processor : IProcessor in args) {
                this.add(processor);
            }
        }

        private static const UNABLE_TO_MODIFY : IllegalOperationError =
                new IllegalOperationError('Unable to modify queue while running');

        public function add (processor : IProcessor) : void {
            if (this.active) {
                throw UNABLE_TO_MODIFY;
            }
            this._queue.push(processor);
        }

        public function remove (processor : IProcessor) : void {
            if (this.active) {
                throw UNABLE_TO_MODIFY;
            }
            var index : int = this._queue.indexOf(processor);
            if (index != -1) {
                this._queue.splice(index, 1);
            }
        }

        override public function exec () : void {
            super.exec();
            this._schedule = this._queue.slice();
            this.checkQueue();
        }

        private function checkQueue () : void {
            while (this._schedule.length) {
                var processor : IProcessor = this._schedule.shift();
                var actionOnComplete : Action = processor.onComplete.addAction(
                        int.MAX_VALUE, this.onProcessorComplete, this, processor);
                var actionOnError : Action = processor.onError.addAction(
                        int.MAX_VALUE, this.onProcessorFail, this, processor);
                this._running[processor] = new <Action>[actionOnComplete, actionOnError];
                processor.exec();
                if (this.executionMode == SUBSEQUENT) {
                    break;
                }
            }

            if (!this._schedule.length && ObjectUtils.isEmpty(this._running)) {
                this.complete();
            }
        }

        private function freeProcessor (processor : IProcessor) : void {
            var actions : Vector.<Action> = this._running[processor];
            if (actions) {
                processor.onComplete.pop(actions[0]);
                processor.onError.pop(actions[1]);
                delete this._running[processor];
            }
        }

        private function onProcessorFail (processor : IProcessor) : void {
            this.freeProcessor(processor);
            if (this.stopOnFail) {
                this.error();
            }
            else {
                this.checkQueue();
            }
        }

        private function onProcessorComplete (processor : IProcessor) : void {
            this.freeProcessor(processor);
            this.checkQueue();
        }

        override public function complete () : void {
            this.reset();
            super.complete();
        }

        override public function error () : void {
            this.reset();
            super.error();
        }

        private function reset () : void {
            this._schedule = null;
            ObjectUtils.clear(this._running);
        }

        override public function cleanUp () : void {
            /*for each (var processor : IProcessor in this._queue) {

            }*/
            this._queue.length = 0;
            this.reset();
            super.cleanUp();
        }
    }
}
