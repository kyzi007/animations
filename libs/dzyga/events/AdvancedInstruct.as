package dzyga.events {
    import flash.events.TimerEvent;
    import flash.utils.Timer;

    public class AdvancedInstruct implements IInstruct {
        protected static const THREAD : String = 'thread';
        protected static const ACTION : String = 'action';
        protected static const SCHEDULE : String = 'schedule';
        protected var _type : String;
        protected var _time : uint;
        protected var _action : Action;
        private const SCHEDULE_AUTO : String = "schedule_auto";
        protected var _timer : Timer;
        protected var _finish : Boolean;

        public function AdvancedInstruct() {
        }

        public function execute() : Boolean {
            /*if (_type == SCHEDULE) {
                runAsSchedule(_time);
            }*/
            return false;
        }

        public function finish() : void {
            if(_timer) {
                _timer.stop();
                _timer.removeEventListener(TimerEvent.TIMER, onTimer);
                _timer = null;
            }
            _finish = true;
        }

        protected function runAsAction() : void {
            stop();
            _action = EnterFrame.addAction( 0, this);
            _action.name = "CreateObjectInstruct:execute action";
            _type = ACTION;
        }

        protected function runAsThread() : void {
            stop();
            _action = EnterFrame.addThread(0, 0, this);
            _action.name = "CreateObjectInstruct:execute thread";
            _type = THREAD;
        }

        protected function runAsSchedule(time : uint) : void {
            //stop();
            //_time = time;
            //_action = EnterFrame.scheduleAction("CreateObjectInstruct:execute sh", time, this);
            if(_time == time) return;
            _time = time;
            if(!_timer){
                _timer = new Timer(time);
                _timer.addEventListener(TimerEvent.TIMER, onTimer);
            } else {
                _timer.delay = time;
                _timer.reset();
            }
            _timer.start();
            _type = SCHEDULE;
        }

        private function onTimer(event : TimerEvent) : void {
            execute();
        }

        protected function runAsAutoSchedule(time : uint) : void {
            // TODO
            stop();
            _time = time;
            var percent : Number = EnterFrame.calculatedFps / EnterFrame.fps; // 0.5


            _action = EnterFrame.scheduleAction(time, this);
            _action.name = "CreateObjectInstruct:execute sh";
            _type = SCHEDULE_AUTO;
        }

        protected function stop() : void {
            if (!_action) return;
            switch (_type) {
                case THREAD:
                    EnterFrame.removeThread(_action as Thread);
                    break;
                case ACTION:
                    EnterFrame.removeAction(_action);
                    break;
                case SCHEDULE:
                    _timer.stop();
                    break;
            }
            _action = null;
        }

        public function get name() : String {
            return "";
        }
    }
}
