package com.adobe.utils {
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	public class CallLater extends Sprite {
		
		protected static var _instance:CallLater;
		
		protected var callLaterHash:Dictionary;
		
		public function CallLater() {
			callLaterHash = new Dictionary();
		}
	
		// Public Methods:
		public static function call(p_function:Function, p_frameDelay:uint = 1):void {
			getInstance().call(p_function, p_frameDelay);
		}
		
		public function call(p_function, p_frameDelay):void {
			callLaterHash[p_function] = {delay:p_frameDelay};
			if (hasEventListener(Event.ENTER_FRAME) == false) { this.addEventListener(Event.ENTER_FRAME, onFrame); }
		}
		
		// Protected Methods:
		protected function onFrame(p_event:Event):void {
			var hasRun:Boolean = false;
			for (var func:Object in callLaterHash) {
				hasRun = true;
				var obj:Object = callLaterHash[func];
				if (--obj.delay == 0) { func(); delete callLaterHash[func]; }
			}
			if (hasRun == false) { removeEventListener(Event.ENTER_FRAME, onFrame); }
		}
		
		protected static function getInstance():CallLater {
			if (_instance == null) { _instance = new CallLater(); }
			return _instance;
		}
	}
}