package seph.media.sephPlayer.models {
	
	import flash.events.*;
	
	public interface IPlayModel {
		
		function play(file:String = null, start:Number = 0):void;
		function pause():void;
		function stop():void;
		function togglePause():void;
		function resume():void;
		function seek(pos:Number):void;
		function set mute(flag:Boolean):void;
		function get mute():Boolean;
		
		function onPlayStatus(obj:*):void;
		function onMetadataReceived(event:Event):void;
		function onTimerHandler(event:TimerEvent):void;
		
		function dispose():Boolean;

	}
	
}
