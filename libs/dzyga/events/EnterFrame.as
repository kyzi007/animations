package dzyga.events {

    import dzyga.pool.Pool;

    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.utils.getTimer;

    import log.logServer.KLog;

    public class EnterFrame {
        public static var dispatcher : Stage;
        public static var queue : Queue = new Queue();
        public static var schedule : Queue = new Queue();
        public static var active : Boolean = false;

        public static const DEFAULT_FPS : int = 24;
        private static var _isStageActive : Boolean = false;

        // постоянно, по энтерфрейму
        public static function addAction(priority : int, method : *, thisObject : Object = null, ...args) : Action {

            //CONFIG::debug{ KLog.log("addAction  " + name, KLog.ENTER_FRAME); }

            var action : Action = EnterFrame.queue.addAction(priority, method, thisObject);
            action.args = args;

            if (method is IInstruct) {
                action.action = null;
                action.instruct = method;
            } else {
                action.instruct = null;
            }

            EnterFrame.start();
            return action;
        }

        public static function removeAction(action : Action, keep : Boolean = false) : void {
            if (!action) return;

            //CONFIG::debug{ KLog.log("removeAction  " + action.name, KLog.ENTER_FRAME); }

            EnterFrame.queue.pop(action, keep);
            if (!(EnterFrame.queue.length || EnterFrame.schedule.length)) {
                EnterFrame.stop();
            }
        }

        // столько раз на фрейм сколько можно
        public static function addThread(priority : int, threads : int, method : *, thisObject : Object = null, ...args) : Thread {
            //CONFIG::debug{ KLog.log("addThread  " + name, KLog.ENTER_FRAME); }

            var action : Thread = new Thread();//Pool.get(Thread) as Thread;
            action.priority = priority;
            action.action = method;
            action.threads = threads;
            action.thisObject = thisObject;
            action.args = args;

            if (method is IInstruct) {
                action.action = null;
                action.instruct = method;
            } else {
                action.instruct = null;
            }

            EnterFrame.queue.put(action);
            EnterFrame.start();
            return action;
        }

        public static function removeThread(thread : Thread) : void {
            if (!thread) return;
            //CONFIG::debug{ KLog.log("removeThread  " + thread.name, KLog.ENTER_FRAME); }

            EnterFrame.queue.pop(thread);
            if (!(EnterFrame.queue.length || EnterFrame.schedule.length)) {
                EnterFrame.stop();
            }
        }

        // один раз
        public static function scheduleAction(timeOut : Number, method : *, thisObject : * = null, ...args) : Action {
            //CONFIG::debug{ KLog.log("scheduleAction  " + name, KLog.ENTER_FRAME); }

            EnterFrame.start();
            var delay : Number = getTimer() + timeOut;
            var action : Action = EnterFrame.schedule.addAction(delay, method, thisObject);
            action.args = args;

            if (method is IInstruct) {
                action.action = null;
                action.instruct = method;
            } else {
                action.instruct = null;
            }

            return action;
        }

        public static function removeScheduledAction(action : Action, keep : Boolean = false) : void {
            if (!action) return;
            //CONFIG::debug{ KLog.log("removeScheduledAction  " + action.name, KLog.ENTER_FRAME); }
            EnterFrame.schedule.pop(action, keep);
        }

        private static function start() : void {
            if (EnterFrame._disabled) {
                return;
            }
            if (!EnterFrame.active) {
                if (!_calculatedFpsCheckTimer) {
                    _calculatedFpsCheckTimer = new Timer(1000);
                    _calculatedFpsCheckTimer.addEventListener(TimerEvent.TIMER, checklFps);
                }
                _calculatedFpsCheckTimer.start();
                EnterFrame.dispatcher.addEventListener(Event.ENTER_FRAME, exec);
                EnterFrame.active = true;
            }
            dispatcher.addEventListener(Event.ACTIVATE, activate);
            dispatcher.addEventListener(Event.DEACTIVATE, deactivate);
        }

        private static function deactivate(event : Event) : void {
            _isStageActive = false;
            checklFps(null);
        }

        private static function activate(event : Event) : void {
            _isStageActive = true;
            checklFps(null);
        }

        private static function stop() : void {
            EnterFrame.dispatcher.removeEventListener(Event.ENTER_FRAME, exec);
            EnterFrame.active = false;
            if (_calculatedFpsCheckTimer) {
                _calculatedFpsCheckTimer.stop();
            }
        }

        private static var _disabled : Boolean = false;
        public static function set disabled(v : Boolean) : void {
            EnterFrame._disabled = v;
            if (EnterFrame._disabled) {
                EnterFrame.stop();
            }
            else if (!EnterFrame.empty) {
                EnterFrame.start();
            }
        }

        public static function get disabled() : Boolean {
            return EnterFrame._disabled;
        }

        private static var _interval : uint = 1000 / EnterFrame.DEFAULT_FPS * FRAME_RATIO;
        private static var _calculatedInterval : uint = 1000 / EnterFrame.DEFAULT_FPS * FRAME_RATIO;
        private static var _fps : uint = EnterFrame.DEFAULT_FPS;
        private static var _calculatedFpsCounter : uint = 0;
        private static var _calculatedFps : uint = EnterFrame.DEFAULT_FPS; // contains last calculated value
        private static var _calculatedFpsCheckTimer : Timer;

        private static var FRAME_RATIO : Number = 0.7;

        public static function set fps(val : Number) : void {
            dispatcher.frameRate = val;
            _fps = val;
            _calculatedFps = val;
            _calculatedInterval = _interval = 1000 / val * EnterFrame.FRAME_RATIO;
        }

        public static function get empty() : Boolean {
            return !(EnterFrame.queue.length || EnterFrame.schedule.length);
        }

        private static function checklFps(event : TimerEvent) : void {
            _calculatedFps = _calculatedFpsCounter;
            _calculatedFpsCounter = 0;
            if (_calculatedFps < _fps * 0.8 && _isStageActive) {
                _calculatedInterval = (_interval * (_calculatedFps / _fps)) * 0.5; // искусственно занижаем ниже пропорции
            } else {
                _calculatedInterval = _interval;
            }
            CONFIG::debug{ KLog.log("EnterFrame : checklFps  "+ _calculatedFps, KLog.ENTER_FRAME); }
        }

        public static function exec(event : Event = null) : void {
            var startTime : Number = getTimer();
            var timePassed : Number = 0;
            var timeIsOut : Boolean = false;
            var action : Action;
            var i : int = 0;
            var threadCount : int = 0;

           // CONFIG::debug{ KLog.log("EnterFrame : exec ---", KLog.ENTER_FRAME); }

            while (EnterFrame.schedule.length && !timeIsOut) {
                action = EnterFrame.schedule.queue[0];
                if (action.priority < startTime) {
                    action.run();
                    EnterFrame.removeScheduledAction(action);
                    timePassed = getTimer() - startTime;
                    timeIsOut = timePassed > EnterFrame._calculatedInterval;
                    //CONFIG::debug{ KLog.log("EnterFrame : exec  schedule "+action.name , KLog.ENTER_FRAME); }
                }
                else {
                    break;
                }
            }

            if (EnterFrame.queue.length) {
                action = EnterFrame.queue.queue[i];
                while (action && !timeIsOut) {
                    if (action is Thread) {
                        var thread : Thread = action as Thread;
                        if ((!thread.threads || thread.threads > threadCount) && thread.run()) {
                            threadCount++;
                            //CONFIG::debug{ KLog.log("EnterFrame : exec  thread "+ thread.name, KLog.ENTER_FRAME); }
                        }
                        else {
                            action = null;
                            threadCount = 0;
                        }
                    }
                    else {
                        //CONFIG::debug{ KLog.log("EnterFrame : exec  action " + action.name, KLog.ENTER_FRAME); }
                        action.run();
                        action = null;
                        threadCount = 0;
                    }

                    if (!action) {
                        if (++i >= EnterFrame.queue.length) {
                            break;
                        }
                        action = EnterFrame.queue.queue[i];
                    }

                    timePassed = getTimer() - startTime;
                    timeIsOut = (timePassed > EnterFrame._calculatedInterval);

                }
            }
            _calculatedFpsCounter++;
        }

        public static function get calculatedFps() : uint {
            return _calculatedFps;
        }

        public static function get fps() : Number {
            return EnterFrame._fps;
        }

        public static function get isStageActive() : Boolean {
            return _isStageActive;
        }
    }
}
