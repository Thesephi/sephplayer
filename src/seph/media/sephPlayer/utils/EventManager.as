package seph.media.sephPlayer.utils {
	
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.utils.Timer;
	
	import seph.events.ItemEvent;
	import seph.media.sephPlayer.SephPlayer;
	import seph.media.sephPlayer.SephPlayerGlobal;
	import seph.media.sephPlayer.events.SephPlayerEvent;
	import seph.media.sephPlayer.models.Clip;
	import seph.utils.Traceable;
	
	public class EventManager extends EventDispatcher {
		
		private var _player:SephPlayer;
		private var _failTimer:Timer;

		public function EventManager(p:SephPlayer) {
			this._player = p;
			this.addEventListener(SephPlayerEvent.NETCONNECTION_CONNECT_FAILED, onFilePlayFailedHandler, false, 0, true);
			this.addEventListener(SephPlayerEvent.NETCONNECTION_CONNECT_REJECTED, onFilePlayFailedHandler, false, 0, true);
			this.addEventListener(SephPlayerEvent.STREAM_NOT_FOUND, onFilePlayFailedHandler, false, 0, true);
		}
		
		// this function sends an event with the specified type to the GUIManager instance of the player
		// mostly used to implement buttons on the GUI being clicked
		public function sendEvent(type:String, details:* = null):void {
			
			// specifically deals with failTimer
			if(type == SephPlayerEvent.STOP) {
				if(this._failTimer) {
					this._failTimer.stop();
					this._failTimer.removeEventListener(TimerEvent.TIMER, onFilePlayFailedHandler);
					this._failTimer = null;
				}
			}
			
			// dispatch the event to the GUIManager
			_player.guiMngr.receiveGUIEvent(type,details);
		}
		
		public function onFilePlayStartHandler(event:Event = null):void
		{
			// ga report that the clip has begun to play
			var curClip:Clip = this._player.playlistMngr.getCurrentClip();
			if(String(curClip.clipType) == "ad")
			{
				if(this._player.tracker)
					this._player.tracker.trackEvent("TVC","FilePlayStart",curClip.file);
				this._player.sephGaTracker.trackEvent("TVC","FilePlayStart",curClip.file);
			}
			else
			{
				if(this._player.tracker)
					this._player.tracker.trackEvent("Video","FilePlayStart",curClip.file);
				this._player.sephGaTracker.trackEvent("Video","FilePlayStart",curClip.file);
			}
			
			this.dispatchEvent(new Event(SephPlayerEvent.FILE_PLAY_START));
			if(ExternalInterface.available)
			{
				try
				{
					ExternalInterface.call(SephPlayerGlobal.EXTERNAL_FILE_PLAY_START_FUNC_NAME, ExternalInterface.objectID, _player.currentPlaying, _player.config.file, _player.config.streamer);
				}
				catch(e:Error)
				{
					//
				}
			}
		}
		
		public function onFilePlayCompleteHandler(event:Event = null):void
		{
			// ga report that the clip has finished playing back
			// remember to DO THIS FIRST, before the currentClip value is updated with the next one
			var curClip:Clip = this._player.playlistMngr.getCurrentClip();
			if(String(curClip.clipType) == "ad")
			{
				if(this._player.tracker)
					this._player.tracker.trackEvent("TVC","FilePlayComplete",curClip.file);
				this._player.sephGaTracker.trackEvent("TVC","FilePlayComplete",curClip.file);
			}
			else
			{
				if(this._player.tracker)
					this._player.tracker.trackEvent("Video","FilePlayComplete",curClip.file);
				this._player.sephGaTracker.trackEvent("Video","FilePlayComplete",curClip.file);
			}
			
			// notify the upper layers about this event (OVA-SephPlayer, Flex Wrapper, etc.)
			this.dispatchEvent(new Event(SephPlayerEvent.PLAYER_STOP));
			this.dispatchEvent(new Event(SephPlayerEvent.FILE_PLAY_COMPLETE));
			if(ExternalInterface.available)
			{
				try
				{
					ExternalInterface.call(SephPlayerGlobal.EXTERNAL_FILE_PLAY_COMPLETE_FUNC_NAME, ExternalInterface.objectID, _player.currentPlaying, _player.config.file, _player.config.streamer);
				}
				catch(e:Error)
				{
					//
				}
			}
		}
		
		public function onPlayTimeUpdatedHandler(event:ItemEvent):void
		{
			this.dispatchEvent(event.clone());
			// we might or might not dispatch this event via ExternalInterface...
		}
		
		public function onPlaylistPlayCompleteHandler(event:Event = null):void
		{
			Traceable.doTrace(this + ": Playlist completed.","info");
			this.dispatchEvent(new Event(SephPlayerEvent.PLAYLIST_PLAY_COMPLETE));
			if(ExternalInterface.available)
			{
				try
				{
					ExternalInterface.call(SephPlayerGlobal.EXTERNAL_PLAYLIST_PLAY_COMPLETE_FUNC_NAME, ExternalInterface.objectID);
				}
				catch(e:Error)
				{
					//
				}
			}
		}
		
		protected function onFilePlayFailedHandler(event:Event = null):void
		{
			// call recordLastError if available
			if(ExternalInterface.available && event)
			{
				try
				{
					// for some reason, the NetConnection.Connect.Failed happens way too often
					// making it a terrible experience to receive error report of this type
					// and so we have to exclude it from the report, until we find a better solution
					/*if(event.type != SephPlayerEvent.NETCONNECTION_CONNECT_FAILED)
					{
						var clipBeingPlayed:Clip = _player.playlistMngr.getCurrentClip();
						var fileBeingPlayed:String = "";
						if(clipBeingPlayed)
							fileBeingPlayed = " : " + clipBeingPlayed.file;
						var desc:String = "";
						if(event.type == SephPlayerEvent.NETCONNECTION_CONNECT_REJECTED)
							desc = " - Reason: " + event["id"];
						ExternalInterface.call("recordLastError",event.type + fileBeingPlayed + desc);
					}*/
				}
				catch(e:Error)
				{
					//
				}
			}
			
			// wait for a few seconds, then dispatch PlayComplete
			// so that the player can automatically play the next
			// clip in the playlist (if the currently playing file is an ad
			// or play an alternative stream (if the currently playing file is a Clip with a streams array of length > 2
			if(!_failTimer)
			{
				_failTimer = new Timer(1300,1);
				_failTimer.addEventListener(TimerEvent.TIMER, onPlayFailTimerHandler);
				_failTimer.start();
			}
		}
		
		protected function onPlayFailTimerHandler(event:TimerEvent):void
		{			
			_failTimer.stop();
			_failTimer.removeEventListener(TimerEvent.TIMER, onPlayFailTimerHandler);
			_failTimer = null;
			
			if(_player.playlistMngr.getCurrentClip() && _player.playlistMngr.getCurrentClip().clipType && _player.playlistMngr.getCurrentClip().clipType.toLowerCase() == "ad")
			{
				this.dispatchEvent(new Event(SephPlayerEvent.AD_NOT_FOUND));
				
				////////////////////////////////////////////////////////////////////
				// this will notice the player to play the next file in the playlist
				////////////////////////////////////////////////////////////////////
				
				// to be safe, call "STOP" first
				//this.sendEvent(SephPlayerEvent.STOP);
				
				// we don't call _player.playNext() right here
				// because it's better processed in the PlaylistManager class
				_player.playlistMngr.onFilePlayCompleteHandler();
				
			}
			else
			{
				/////////////////////////////////////////////////////////////////////////
				// if there's an alternative in the currentClip's streams array, play it
				/////////////////////////////////////////////////////////////////////////
				
				// we'll get back to this later
				//SephPlayerUtils.windowAlert("Clip khong xem duoc: " + this._player.playlistMngr.getCurrentClip().file);
				
				var curClip:Clip = this._player.playlistMngr.getCurrentClip();
				if(curClip.streams && curClip.streams.length > 1)
				{					
					// mark the stream item that failed to play just now
					for each(var itm:Object in curClip.streams)
					{
						if(itm["name"] == _player.config.file)
						{
							itm["status"] = "bad";
							break;
						}
					}
					
					// play an item that's not been marked as 'bad'
					for each(var itm1:Object in curClip.streams)
					{
						if(String(itm1["status"]) != "bad")
						{
							curClip.file = itm1["name"];
							_player.playFile(curClip);
							break;
						}
					}
				}				
			}
		}
	}
}