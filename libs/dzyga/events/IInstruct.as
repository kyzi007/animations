package dzyga.events {
    /**
     * и без кеша классов
     * создание 100 обьектов нас не прогнет
     */
    public interface IInstruct {

        function execute() : Boolean

        function finish() : void

        function get name ():String
    }
}
