package seph.media.sephPlayer.models
{	
	import flash.events.*;
	import flash.net.Responder;
	import flash.utils.Timer;
	
	import seph.media.sephPlayer.SephPlayer;
	import seph.media.sephPlayer.SephPlayerGlobal;
	import seph.media.sephPlayer.events.SephPlayerEvent;
	import seph.media.sephPlayer.utils.ConfigManager;
	import seph.media.sephPlayer.utils.GUIManager;
	import seph.utils.Traceable;
	
	public class AbstractPlayModel extends EventDispatcher implements IPlayModel
	{		
		protected var _player:SephPlayer;
		protected var _guiMngr:GUIManager;
		
		protected var _time:Number;
		public function get time():Number
		{
			return this._time;
		}
		protected var _isPlaying:Boolean = false;
		public function get isPlaying():Boolean
		{
			return this._isPlaying;
		}
		protected var _pausePosition:Number = 0;
		public function get pausePosition():Number
		{
			return this._pausePosition;
		}
		protected var _mute:Boolean;
		public function get mute():Boolean
		{
			return this._mute;
		}
		public function set mute(flag:Boolean):void
		{
			this._mute = flag;
		}
		protected var _timer:Timer;
		public function get timer():Timer
		{
			return this._timer;
		}
		protected var _appConnCountTimer:Timer;
		
		//---------------------------------------------------------------------
		// Responder for methods invoking function from server
		//---------------------------------------------------------------------
		protected var _appConnCountResponder:Responder;
		
		public function get display():* {}
		
		protected var _isPausing:Boolean = false;
		public function get isPausing():Boolean
		{
			return this._isPausing;
		}

		public function AbstractPlayModel(player:SephPlayer, guiMngr:GUIManager)
		{
			this._player = player;
			this._guiMngr = guiMngr;
			this.addEventListener(SephPlayerEvent.PLAY_STATUS, onPlayStatus, false, 0, true);
			this.addEventListener(SephPlayerEvent.METADATA_RECEIVED, onMetadataReceived, false, 0, true);
			
			this._appConnCountResponder = new Responder(onAppConnCountResHandler);
			
		}
		
		public function doConnect(streamer:String = null, streamerArg:String = null, cca:String = null):void {} // this is used when the PlayModel contains a NetConnection
		
		public function play(file:String = null, start:Number = 0):void
		{
			_isPausing = false;
		}
		
		public function pause():void
		{
			if(_timer)
			{
				_timer.stop();
				_isPausing = true;
			}
			else
			{
				Traceable.doTrace("Warning while trying to pause: no Timer.","warn");
			}
		}
		
		public function stop():void
		{
			this.pause();
		}
		
		public function togglePause():void
		{
			if(_timer.running)
			{
				_timer.stop();
			}
			else
			{
				_timer.start();
			}
		}
		
		public function resume():void
		{
			if(_timer)
			{
				_timer.start();
				_isPausing = false;
			}
			else
			{
				Traceable.doTrace("Warning while trying to resume: no Timer.","warn");
			}
		}
		
		public function seek(pos:Number):void
		{
			//
		}
		
		public function onPlayStatus(obj:*):void
		{
			//
		}
		
		public function onMetadataReceived(event:Event):void
		{
			// by default, upon receiving metadata, the RESIZE event will be called from stage
			// so that the player can update the display properly according to the
			// metadata of the media file, esp. width and height
			this._player.stage.dispatchEvent(new Event(Event.RESIZE));
		}
		
		public function onTimerHandler(event:TimerEvent):void
		{
			//
		}
		
		// this ONLY HAPPEN ONCE per playback session
		protected function onPlayFirstStart():void
		{			
			this._player.evtMngr.onFilePlayStartHandler();
			Traceable.doTrace("Play First Start");
		}
		
		// this ONLY HAPPENS ONCE per playback session
		protected function onPlayFinalComplete():void
		{			
			this._player.evtMngr.onFilePlayCompleteHandler();
			Traceable.doTrace("Play Final Complete");
		}
		
		public function getStreamInfo():Object
		{
			Traceable.doTrace(this + ": the getStreamInfo() method is supposed to be called from its subclasses.");
			return null;
		}
		
		public function getApplicationConnectionCount(event:Event = null):void
		{
			Traceable.doTrace(this + ": the getApplicationConnectionCount() method is supposed to be called from its subclasses.");
		}
		
		// this may be dispatched many times in 1 session
		protected function onPlayStart():void
		{
			//
		}
		
		// this may be dispatched many times in 1 session
		protected function onPlayComplete():void
		{
			//
		} 
		
		public function switchToStreamName(name:String):void
		{
			Traceable.doTrace(this + ": the method switchToStreamName() needs to be overriden and used only by the VideoPlayModel.");
		}
		
		public function getProgPerc():Number
		{
			// to be implemented by subclasses
			return 0;
		}
		
		public function getLoadPerc():Number
		{
			// to be implemented by subclasses
			return 0;
		}
		
		protected function onAppConnCountResHandler(count:Number):void
		{
			// to be implemented by subclasses
		}
		
		public function dispose():Boolean
		{			
			this.removeEventListener(SephPlayerEvent.PLAY_STATUS, onPlayStatus);
			_player.clearPlayModel();
			_player = null;
			_guiMngr = null;
			
			if(_timer)
			{
				_timer.removeEventListener(TimerEvent.TIMER, onTimerHandler);
				_timer.stop();
				_timer = null;
			}
			
			if(this._appConnCountTimer)
			{
				this._appConnCountTimer.stop();
				this._appConnCountTimer = null;
			}
			
			this._appConnCountResponder = null;
			
			return true;
		}
	}	
}
