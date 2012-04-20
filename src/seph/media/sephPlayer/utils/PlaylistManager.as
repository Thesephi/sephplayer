package seph.media.sephPlayer.utils
{	
	import flash.events.Event;
	
	import seph.events.ItemEvent;
	import seph.media.sephPlayer.SephPlayer;
	import seph.media.sephPlayer.events.SephPlayerEvent;
	import seph.media.sephPlayer.models.Clip;
	import seph.utils.Traceable;
	
	public class PlaylistManager
	{		
		protected var _player:SephPlayer;
		protected var _clips:Array;
		protected var _currentPlayingIndex:uint = 0;
		protected var _initialized:Boolean = false;
		public function get initialized():Boolean
		{
			return this._initialized;
		}

		public function PlaylistManager(player:SephPlayer)
		{
			this._player = player;
			_clips = new Array();
			
			// add the event listeners that handle file-play-complete
			// so that the next file in the list is played
			_player.evtMngr.addEventListener(SephPlayerEvent.FILE_PLAY_COMPLETE, onFilePlayCompleteHandler, false, 0, true);
		}
		
		public function getClipAt(i:uint):Clip
		{
			if(i < this.length)
				return this._clips[i];
			return null;
		}
		
		public function getCurrentClip():Clip
		{
			return this.getClipAt(this._currentPlayingIndex);
		}
		
		public function addClip(clip:Clip):void
		{
			this._clips.push(clip);
			_player.evtMngr.dispatchEvent(new ItemEvent(SephPlayerEvent.PLAYLIST_UPDATED, this.length));
		}
		
		public function removeClip(toRemove:Clip):void
		{
			var i:uint = 0;
			for each(var clip:Clip in _clips)
			{
				if(clip != null)
				{
					if(clip == toRemove)
						this.removeClipAt(i);
				}
				i++;
			}
		}
		
		public function removeClipAt(i:uint):void
		{
			if(i < this.length - 1)
				_clips.splice(i,1);
			_player.evtMngr.dispatchEvent(new ItemEvent(SephPlayerEvent.PLAYLIST_UPDATED, this.length));
		}
		
		public function get length():uint
		{
			return this._clips.length;
		}
		
		public function clear():void
		{
			for each(var clip:Clip in _clips)
			{
				if(clip != null)
					clip.dispose();
			}
			this._clips = new Array();
		}
		
		public function initializeFromArray(arr:Array):void
		{
			this.clear();
			for each(var itm:* in arr)
			{
				if(itm is Clip)
					this.addClip(itm as Clip);
			}
			
			// reset the currentPlayingIndex
			this._currentPlayingIndex = 0;
			
			this._initialized = true;
			_player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.PLAYLIST_INITIALIZED));
			Traceable.doTrace(this + ": << Playlist initialized. >>");
		}
		
		public function get currentPlayingIndex():uint
		{
			return this._currentPlayingIndex;
		}
		
		public function set currentPlayingIndex(val:uint):void
		{
			if(val <= this.length - 1)
				this._currentPlayingIndex = val;
			else
				this._currentPlayingIndex = 0;
		}
		
		public function onFilePlayCompleteHandler(event:Event = null):void
		{
			// updated from version 2.10.0: SephPlayer now has the ability to "playInStream"
			// so, after file playback is completed, it should check if the file is an actual Clip
			// in the playlist, or just an "inStream" Clip, and take proper measures
			if(_player.isInInStreamSession)
			{
				// remove the inStream clip that has just been completed
				_player.playInStreamMngr.removeFinishedInStreamClip();
				
				// if the clip being completed is the last "inStream" clip, resume playing the "playListManager.currentClip"
				// else play the next inStream clip
				if(_player.playInStreamMngr.hasNextInStreamClip())
				{
					_player.playFile(_player.playInStreamMngr.getCurrentInStreamClip());
				}
				else
				{
					Traceable.doTrace(this + ": InStream session ended. Resume current clip.", "info");
					_player.isInInStreamSession = false;
					
					// restore the current clip's metadata
					_player.replaceMetadata(_player.playInStreamMngr.getInformationBeforeInStreamSession('metadata') as MetadataManager);
					
					// actually play, or resume, the current clip
					_player.playFile(_player.playlistMngr.getCurrentClip());
				}
			}
			else
			{
				// no inStream session, process everything as normal
				if(_player.playlistMngr.length > 0)
				{
					if(_player.playlistMngr.currentPlayingIndex == _player.playlistMngr.length - 1)
					{
						// if this is the only Clip, or the last Clip in the list						
						_player.evtMngr.onPlaylistPlayCompleteHandler();
						if(_player.config.repeat == "playlist")
						{
							Traceable.doTrace(this + ": \"repeat\" is currently set to \"playlist\". Calling \"playNext\".", "info"); 
							_player.playNext();
						}
						else if(_player.config.repeat == "one")
						{
							Traceable.doTrace(this + ": \"repeat\" is currently set to \"one\". Playing the Clip item again.", "info");
							_player.playFile(this.getCurrentClip())
						}
						else if(_player.config.repeat == "none")
						{
							Traceable.doTrace(this + ": \"repeat\" is currently set to \"playlist\". Disposing PlayModel.", "info");
							if(_player.playModel)
								_player.playModel.dispose();
						}
					}
					else
					{
						Traceable.doTrace(this + ": Playback complete. Prepare to play next Clip item in the list...", "info");
						_player.playNext();
					}
				}
			}
		}
		
		public function get clips():Array
		{
			return this._clips;
		}

	}
	
}
