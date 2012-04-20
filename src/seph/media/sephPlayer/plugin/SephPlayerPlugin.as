package seph.media.sephPlayer.plugin {
	
	import flash.display.*;
	import flash.events.*;
	import flash.system.Security;
	
	import seph.media.sephPlayer.SephPlayer;
	
	public class SephPlayerPlugin extends MovieClip {
		
		public function get VERSION():String {
			return "N/A";
		}
		
		public function SephPlayerPlugin() {
			this.config = new Object();
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStageHandler, false, 0, true);
		}
		
		protected var _player:SephPlayer;
		public var config:Object;
		
		public function set player(player:SephPlayer):void {
			this._player = player;
		}
		public function get player():SephPlayer {
			return this._player;
		}
		
		protected function onAddedToStageHandler(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStageHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStageHandler, false, 0, true);
			Security.allowDomain(this.root.loaderInfo.loaderURL);
		}
		
		protected function onRemovedFromStageHandler(event:Event):void {
			removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStageHandler);
			this.config = null;
			this._player = null;
		}

	}
	
}
