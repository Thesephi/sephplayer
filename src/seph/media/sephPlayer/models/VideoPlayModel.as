package seph.media.sephPlayer.models
{
	import com.wowza.encryptionAS3.TEA;
	
	import flash.display.Stage;
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import seph.Utilities;
	import seph.events.ItemEvent;
	import seph.media.sephPlayer.SephPlayer;
	import seph.media.sephPlayer.SephPlayerGlobal;
	import seph.media.sephPlayer.events.SephPlayerEvent;
	import seph.media.sephPlayer.models.Clip;
	import seph.media.sephPlayer.utils.ConfigManager;
	import seph.media.sephPlayer.utils.GUIManager;
	import seph.media.sephPlayer.utils.NetStatusClient;
	import seph.media.sephPlayer.utils.PlaylistManager;
	import seph.media.sephPlayer.utils.SephPlayerUtils;
	import seph.utils.Traceable;
	
	public class VideoPlayModel extends AbstractPlayModel implements IPlayModel
	{		
		public static var NUM_OF_MODEL:Number = 0;
		
		protected var _firstConnect:Boolean = true;
		protected var _reConnectTimer:Timer;
		protected var _bufferEmptyTimer:Timer;
		
		protected var stageVideoUsed:Boolean = false;
		
		protected var _nc:NetConnection;
		protected var _ns:NetStream;
		protected var _vid:Video;
		//protected var _stageVid:StageVideo;
		
		// this is to fix the problem when NetStream.Play.Stop is dispatched too soon before the movie actually ends
		// which mostly happens during streaming media online
		protected var _isNetStreamPlayStopDispatched:Boolean = false;
		protected var _isNetStreamPlayStartDispatched:Boolean = false;
		protected var _isPlayFinalCompleteDispatched:Boolean = false;
		public function get isPlayFinalCompleteDispatched():Boolean
		{
			return this._isPlayFinalCompleteDispatched;
		}
		
		protected var _isPlayTransitioning:Boolean = false;
		public function get isPlayTransitioning():Boolean
		{
			return this._isPlayTransitioning;
		}
		protected var _bwcheckTimer:Timer;
		
		protected var _isRTMP:Boolean = false;
		public function get isRTMP():Boolean
		{
			return this._isRTMP;
		}
		
		// use to dispatch onPlayFinalComplete if it's not automatically done so
		protected var _playCompleteTimer:Timer;
		
		public override function get display():*
		{
			return this._vid;
		}

		public function VideoPlayModel(p:SephPlayer, g:GUIManager)
		{			
			super(p,g);
			
			VideoPlayModel.NUM_OF_MODEL++;
			g.notice("This is VideoPlayModel number " + VideoPlayModel.NUM_OF_MODEL + ". Make sure there is ONLY 1 of this for any time!");
			
			this.createVid(p);
			
			// set default value for the _firstConnect property
			this._firstConnect = true;
			
			// originally the playModel will call this function automatically,
			// but we have noticed that the _playModel was not inited until
			// the connection has been made and all its subsequent function calls
			// has been carried out properly, which may be too late to register
			// _player.display, making it difficult to handle things. So, we should
			// connect manually upon creation of VideoPlayModel if we wish to access
			// the _player.display or _playModel right after cration
			doConnect(p.config.streamer, p.config.streamerArg, p.config.cca);
			
			this._reConnectTimer = new Timer(6000, 1);
			this._reConnectTimer.addEventListener(TimerEvent.TIMER_COMPLETE, doReconnect, false, 0, true);
			
			this._bufferEmptyTimer = new Timer(14000, 1);
			this._bufferEmptyTimer.addEventListener(TimerEvent.TIMER_COMPLETE, doReconnect, false, 0, true);
			
		}
		
		protected function createVid(vidParent:SephPlayer):void
		{			
			_vid = new Video(4,3);
			_vid.smoothing = vidParent.config.smoothing;
			if(vidParent.numChildren != 0)
				vidParent.addChildAt(_vid,1); // make sure the _vid is above the background layer
			else
				vidParent.addChild(_vid);
			
			// only set video visible to true once the first Buffer.Full received
			_vid.visible = false;
			
			// put the video in the middle of the stage by default
			_vid.x = vidParent.width/2 - _vid.width/2;
			_vid.y = vidParent.height/2 - _vid.height/2;
			
			/* This is still in its beta, thus very unstable
			if(SephPlayerUtils.isFlash10Point2())
				_vid.addEventListener(VideoEvent.RENDER_STATE, onVideoRenderStateHandler, false, 0, true);
			*/
		}
		
		/*
		protected function onVideoRenderStateHandler(event:VideoEvent):void
		{
			this.handleHardwareAccelerationCapability(event.status);
		}
		*/
		
		public function exploreVideoDecodingCapability():void
		{
			/*
			var explorer:SWFExplorer = new SWFExplorer();
			var bytes:ByteArray;
			if(_player.root.loaderInfo)
			{
				bytes = _player.root.loaderInfo.bytes;
				explorer.parse(bytes, SWFExplorer.ACCELERATION);
				this.handleHardwareAccelerationCapability(explorer.acceleration);
			}
			*/
			
			switch(_player.root.loaderInfo.parameters["wmode"])
			{
				case "transparent" :
				case "opaque" :
				{
					this.handleHardwareAccelerationCapability(SephPlayerEvent.VIDEO_DECODING_SOFTWARE);
					break;
				}
					
				case "direct" :
				{
					this.handleHardwareAccelerationCapability(SephPlayerEvent.VIDEO_DECODING_HARDWARE);
					break;
				}
					
				case "gpu" :
				{
					this.handleHardwareAccelerationCapability(SephPlayerEvent.VIDEO_DECODING_HARDWARE);
					break;
				}
				
				default :
				{
					this.handleHardwareAccelerationCapability(SephPlayerEvent.VIDEO_DECODING_SOFTWARE);
					break;
				}
			}
			
		}
		
		/**
		 * 
		 * @param info the video accleration state returned by either SWFExplorer or VideoEvent.renderState
		 * 
		 */
		protected function handleHardwareAccelerationCapability(info:*):void
		{
			switch(String(info))
			{
				//case VideoStatus.ACCELERATED :
				//case String(SWFExplorer.GPU) :
				case SephPlayerEvent.VIDEO_DECODING_HARDWARE :
				{
					_player.evtMngr.dispatchEvent(new ItemEvent(SephPlayerEvent.VIDEO_DECODING_CAPABILITY_STATUS, SephPlayerEvent.VIDEO_DECODING_HARDWARE));
					break;
				}
					
				//case VideoStatus.SOFTWARE :
				//case String(SWFExplorer.DIRECT) :
				case SephPlayerEvent.VIDEO_DECODING_SOFTWARE :
				{
					_player.evtMngr.dispatchEvent(new ItemEvent(SephPlayerEvent.VIDEO_DECODING_CAPABILITY_STATUS, SephPlayerEvent.VIDEO_DECODING_SOFTWARE));
					break;
				}
					
				//case VideoStatus.UNAVAILABLE :
				//case String(SWFExplorer.NONE) :
				case SephPlayerEvent.VIDEO_DECODING_UNAVAILABLE :
				{
					_player.evtMngr.dispatchEvent(new ItemEvent(SephPlayerEvent.VIDEO_DECODING_CAPABILITY_STATUS, SephPlayerEvent.VIDEO_DECODING_UNAVAILABLE));
					break;
				}
			}
		}
		
		override public function get time():Number
		{
			// the use of this is ok, but we don't wanna mess up with the _ns.time offset
			//this._time = (_ns)? _ns.time + _player.config.start : _player.config.start;
			this._time = (_ns)? _ns.time : 0;
			return this._time;
		}
		
		override public function doConnect(streamer:String = null, streamerArg:String = null, cca:String = null):void
		{
			Traceable.doTrace(this + ": VideoPlayModel is making a connection...","info");
			_guiMngr.notice(SephPlayer.LANG.CONNECTING, true);
			if(!_nc)
			{
				_nc = new NetConnection();
				_nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusHandler, false, 0, true);
				_nc.client = this;
			}
			_nc.connect(streamer, streamerArg, cca);
		}
		
		protected function doReconnect(event:TimerEvent = null):void
		{
			if(_nc)
			{
				_nc.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatusHandler);
				_nc.client = {};
			}
			_nc = new NetConnection();
			_nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusHandler, false, 0, true);
			_nc.client = this;
			_nc.connect(_player.config.streamer, _player.config.streamerArg);
		}
		
		private function streamingStatusHandler(event:NetStatusEvent):void
		{
			var code:String = String(event.info.code);
			var details:* = event.info.details;
			var description:* = event.info.description;

			_guiMngr.streamingStatusHandler(event);
			
			switch(code)
			{
				case "NetConnection.Connect.Success" :
				{
					if(_firstConnect) // this is a "doConnect" result
					{
						_firstConnect = false;
						this.play();
					}
					else // this is a "doReconnect" result
					{
						if(_ns && SephPlayerUtils.isFlash10Point1() && SephPlayerGlobal.SERVER_TYPE == "fms")
						{
							_ns["attach"](_nc);
							var npo:NetStreamPlayOptions = new NetStreamPlayOptions();
							npo.transition = NetStreamPlayTransitions["RESUME"]; //APPEND_AND_WAIT
							npo.streamName = _player.config.file;
							npo.start = 0;
							npo.len = -1;
							_ns.play2(npo);	
						}
						else
						{
							var clip:Clip = _player.playlistMngr.getCurrentClip();
							clip.start = this._pausePosition;
							_player.playFile(clip);
						}
					}
					break;
				}
					
				case "NetConnection.Connect.Closed" :
				{
					// implement stream reconnect if this is RTMP
					// !important: make sure this doesnt get called when the connection is closed when video finishes playing
					// currently we do that by always invalidating NetStream BEFORE NetConnection
					
					// we can only update the pausePosition here
					// when the _ns.time is still a valid number
					this._pausePosition = this.time;
					
					if(this._isRTMP && this._ns && !this._isPlayFinalCompleteDispatched)
						_reConnectTimer.start();
					
					break;
				}
					
				case "NetConnection.Connect.Rejected" :
				{
					var desc:String = String(description);
					switch(SephPlayerGlobal.SERVER_TYPE)
					{
						case "wowza" :
						{
							desc = event.info.application;
							break;
						}
					}
					this._player.evtMngr.dispatchEvent(new ItemEvent(SephPlayerEvent.NETCONNECTION_CONNECT_REJECTED, desc));
					break;
				}
					
				case "NetConnection.Connect.Failed" :
				{
					this._player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.NETCONNECTION_CONNECT_FAILED));
					if(_isRTMP)
						_reConnectTimer.start();
					break;
				}
					
				case "NetStream.Play.Complete" :
				{
					onPlayFinalComplete();
					break;
				}
					
				case "NetStream.Play.Start" :
				{
					onPlayStart();
					break;
				}
					
				case "NetStream.Play.StreamNotFound" :
				{
					this._player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.STREAM_NOT_FOUND));
					break;
				}
					
				case "NetStream.Play.Transition" :
				{
					_isPlayTransitioning = true;
					break;
				}
					
				case "NetStream.Play.TransitionComplete" :
				{
					_isPlayTransitioning = false;
					break;
				}
					
				case "NetStream.Play.InsufficientBW" :
				{
					/*if(this.isRTMP && _ns && _ns.bufferTime < 7)
						_ns.bufferTime += 1;*/
					break;
				}
					
				case "NetStream.Seek.Notify" :
				{
					if(!this._isPlaying)
					{
						onPlayStart();
						_guiMngr.streamingStatusHandler("NetStream.Play.Start");
						if(_timer && !_timer.running)
							_timer.start();
					}
					else
					{ 
						if(event.info.description && String(event.info.description).indexOf("client-inBufferSeek") >= 0) 
							_guiMngr.notice("smart seek"); 
						else 
							_guiMngr.notice("standard seek");
					}
					break;
				}
					
				case "NetStream.Seek.InvalidTime" :
				{
					if(details && !isNaN(Number(details)) && _ns)
						_ns.seek(Number(details));
					break;
				}
					
				case "NetStream.Pause.Notify" :
				{
					
					break;
				}
					
				case "NetStream.Play.Stop" :
				{
					Traceable.doTrace(this + ": Play.Stop dispatched.","info");
					this._isNetStreamPlayStopDispatched = true;
					
					// if we're not streaming from an RTMP source
					// this code info means the file is really completed
					// else, wait for the "NetStream.Play.Complete" event
					if(!_isRTMP)
					{
						this.onPlayFinalComplete();
					}
					
					break;
				}
					
				case "NetStream.Buffer.Full" :
				{
					if(!_isNetStreamPlayStartDispatched)
					{
						// start of playback, useful when for some reason the NetStream.Play.Start isn't dispatched
						Traceable.doTrace("NetStream.Play.Start wasn't dispatched. This message should appear once per item played.\nPlayer config: " + _player.getConfig(),"info");
						onPlayStart();						
					}
					
					// reset the bufferEmptyTimer now that everything is fine again
					this._bufferEmptyTimer.stop();
					this._bufferEmptyTimer.reset();
					
					break;
				}
					
				case "NetStream.Buffer.Empty" :
				{
					// this is only to make sure
					// onPlayFinalComplete still gets called
					// even if, for some reasons, the NetStream.Play.Complete event
					// doesn't dispatch
					if(_ns)
					{
						if(this._isNetStreamPlayStopDispatched ||
						  (!isNaN(this.time) && this.time > 0 && this.time >= _player.metadata.duration - 0.3))
						{
							// end of playback, useful when for some reason the NetStream.Play.Stop event isn't dispatched
							onPlayFinalComplete();
						}
					}
					
					// start the bufferEmptyTimer so that if there's no data from the NetStream for
					// a certain amount of time, then the Stream Reconnect feature is used
					// notice: we only do this when the problem occurs during playback,
					// meaning the _isPlaying flag has a value of "true"
					
					// we can only update the pausePosition here
					// when the _ns.time is still a valid number
					this._pausePosition = this.time;
					
					if(this.isRTMP && !this._bufferEmptyTimer.running && this._isPlaying)
						this._bufferEmptyTimer.start();
					
					break;
				}
			}			
		}
		
		public function onNetStatusHandler(event:NetStatusEvent):void
		{
			Traceable.doTrace("NetStatus dispatched from " + event.currentTarget + ": ", "info");
			Traceable.doTrace("\t" + event.info.code, "info");
			
			// apply Wowza SecureToken
			// please do this before anything else (play / publish etc)
			if(SephPlayerGlobal.SERVER_TYPE == "wowza")
			{
				if (event.info.secureToken != null)
					this._nc.call("secureTokenResponse", null, TEA.decrypt(event.info.secureToken, "_______________"));
			}
			
			this.streamingStatusHandler(event);
		}
		
		override public function play(file:String = null, start:Number = 0):void
		{			
			_player.stage.dispatchEvent(new Event(Event.RESIZE)); // apply setDisplaySize immediately so the scaleMode is updated correctly
			
			if(this._ns)
			{
				_ns.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatusHandler); // !very important
				if(_ns.client && _ns.client is NetStatusClient)
				{
					// only works with NetStatusClient
					_ns.client.dispose();
				}
				_ns.client = {};
				_ns.pause();
				_ns.close();
				_vid.clear();
				_vid.attachCamera(null);
				_ns = null;
			}
			
			if(!_nc || !_nc.connected)
			{
				Traceable.doTrace(this + ": NetConnection isn't connected yet!","error");
			}
			else
			{
				_ns = new NetStream(_nc);
				_ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusHandler, false, 0, true);
				_ns.bufferTime = (_player.config.live)? 0.25 : 3;
				_ns.client = new NetStatusClient(_player);
				_vid.attachNetStream(_ns);
				this.mute = _player.config.mute;
				
				// the use of this is ok, but users cannot seek back to the time before the value of start
				//_ns.play(((file)? file : _player.config.file), ((start)? start : _player.config.start));
				_ns.play( (file)? file : _player.config.file );
				
				// !important: let the player know that
				// it is playing a progressive or an RTMP clip
				// so it can provide a proper implementation at playback end
				if(_player.config.streamer)
				{
					this._isRTMP = true;
					_ns.bufferTime = 5;
				}
				else
				{
					this._isRTMP = false;
				}
			}
		}
		
		override public function switchToStreamName(name:String):void
		{			
			if(!this._ns || !name)
			{
				Traceable.doTrace(this + ": Unable to switchToStreamName. There's either no NetStream or any bitrate name specified.");
				return;
			}
			
			// the advanced way (not supported by RED5)
			
			var npo:NetStreamPlayOptions = new NetStreamPlayOptions();
			npo.oldStreamName = this._player.config.file;
			npo.streamName = name;
			npo.transition = NetStreamPlayTransitions.SWITCH;
			this._ns.play2(npo);
			this._player.config.file = name;			
			
			// the 'lame' way, supported by RED5
			// however this might not be the best way yet
			//this.pause();
			/*
			_ns.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatusHandler); // !very important
			_ns.client.dispose(); // only works with NetStatusClient
			_ns.pause();
			_ns.close();
			_ns = new NetStream(_nc);
			_ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusHandler, false, 0, true);
			_ns.bufferTime = 3;
			_ns.client = new NetStatusClient(_player);
			_vid.attachNetStream(null);
			_vid.attachNetStream(_ns);
			*/
			
			// The currently working way for RED5
			// the below works well, just that somehow we cannot switch back
			// from low quality to high quality (the other direction seems ok)
			/*this._pausePosition = this._ns.time;
			this._player.config.file = name;
			_ns.play(name,this.pausePosition,-1,1);*/
			
			/*var c:Clip = this._player.playlistMngr.getCurrentClip();
			c.file = name;
			c.start = this.pausePosition;
			this._player.playFile(c);*/
			
			//this.disposeVid();
			//this.createVid(this._player);			
			//_vid.attachNetStream(_ns);
			
			//this.resume();
		}
		
		override public function pause():void
		{			
			super.pause();
			
			// we could check for the flag _isPlaying here
			// but _isPlaying will only be true after NetStream.Play.Start is dispatched
			// so it's not completely reliable. Check the existence of _ns
			// here would better reflect if it's safe to pause or not
			if(this._ns)
			{
				this._pausePosition = this.time;
				this._ns.pause();
			}
		}
		
		override public function togglePause():void
		{			
			super.togglePause();
			
			if(this._ns)
			{
				this._pausePosition = this.time;
				this._ns.togglePause();
			}
		}
		
		override public function resume():void
		{			
			super.resume();			
			if(this._ns)
				this._ns.resume();
		}
		
		/**
		 * This means to really stop playing the video
		 * and remove it from the player's playlist completely
		 * the next time play() is called, it will actually call playFile()
		 * and look for a new file to play 
		 * 
		 */		
		override public function stop():void
		{			
			if(this._isPlaying)
				this.pause();
			
			// we might call onPlayFinalComplete here
			// but we dont really need to dispatch such an event
			// if it isn't a program-generated one
			// the STOP event always comes from the external environment
		}
		
		override public function seek(pos:Number):void
		{
			if(!isNaN(pos) && pos != 0 && this._ns)
				this._ns.seek(pos);
		}
		
		override protected function onPlayStart():void
		{
			if(!_isPlaying)
			{
				this._isPlaying = true;
				
				if(_ns.time <= 0.5)
				{
					
					if(this._vid)
						this._vid.visible = true;
					
					// the first NetStream.Play.Start called (there might be more than once when this event is called during playback of 1 certain file)
					if(!_timer)
					{
						_timer = new Timer(50);
						_timer.addEventListener(TimerEvent.TIMER, onTimerHandler, false, 0, true);
					}
					else
					{
						_timer.reset();
					}
					_timer.start();
					
					this.onPlayFirstStart();
					this._isPlayFinalCompleteDispatched = false;					
				}
				
				super.onPlayStart();
				//_isPlaying = true; this line is here, together with the two lines below, simply as a reminder
				_isNetStreamPlayStopDispatched = false;
				_isNetStreamPlayStartDispatched = true;
			}
		}
		
		override protected function onPlayFirstStart():void
		{
			if(_player.config.live)
			{
				// first time 
				this.getApplicationConnectionCount();
				
				// repeating
				if(!this._appConnCountTimer)
				{
					this._appConnCountTimer = new Timer(30000);
					this._appConnCountTimer.addEventListener(TimerEvent.TIMER, this.getApplicationConnectionCount, false, 0, true);
					this._appConnCountTimer.start();
				}
				else
				{
					this._appConnCountTimer.reset();
					this._appConnCountTimer.start();
				}
			}
			
			// this serves stream reconnect or inStream playing
			// either case, since start > 0, metadata might not be received, so we gotta explicitly update the GUI
			if(_player.config.start > 0)
			{
				this._guiMngr.updateRightTF(SephPlayerUtils.convertFromSecToMin(_player.metadata.duration));
				this._player.stage.dispatchEvent(new Event(Event.RESIZE));
				this.seek(_player.config.start);
			}
			
			super.onPlayFirstStart();
		}
		
		override protected function onPlayFinalComplete():void
		{
			if(this._isPlayFinalCompleteDispatched)
				return;
			else
				this._isPlayFinalCompleteDispatched = true;
			
			if(_isPlaying)
			{
				_isPlaying = false;
				
				this._isNetStreamPlayStopDispatched = true;
				this._isNetStreamPlayStartDispatched = false;
				
				if(_timer)
					_timer.stop();

				if(_vid)
				{
					_vid.clear();
					_vid.attachNetStream(null);
				}
				
				// if the _player.config.start is set to be greater than 0
				// it could be the mechanism of the custom stream reconnect feature
				// in which case we should reset the start back to 0 when playback is done
				// however we don't want to interfere with the player's playInStream feature
				if(!this._firstConnect && !_player.isInInStreamSession)
				{
					_player.playlistMngr.getCurrentClip().start = 0;
					_player.config.start = 0;
				}
				
				_player.guiMngr.notice(SephPlayer.LANG.PLAYBACK_END);
				
				// this should be called last, since it will invalidate all
				// the remaining references to other classes and objects
				super.onPlayFinalComplete();				
			}			
		}
		
		override protected function onPlayComplete():void
		{			
			Traceable.doTrace(this + ": Play.Complete dispatched","info");
			
			//if(this._isPlaying)
			//{				
				/*
				if((_ns && _player.metadata.duration > 0 &&
				   _ns.time >= _player.metadata.duration - 0.3) ||
				   this._isNetStreamPlayStopDispatched)
				{
					// end of playback, useful when for some reason the NetStream.Play.Stop event isn't dispatched	
					Traceable.doTrace("Letting external know this is the playFinalComplete");
					if(!_isPlayFinalCompleteDispatched)
					{
						this.onPlayFinalComplete();
						_isPlayFinalCompleteDispatched = true;
					}
				}
				*/
				
				this._isNetStreamPlayStopDispatched = true;
				this._isNetStreamPlayStartDispatched = false;
				
			//}
			
			super.onPlayComplete();
		}
		
		override public function onPlayStatus(obj:*):void
		{
			if(obj["id"] && obj["id"]["code"])
			{
				_guiMngr.streamingStatusHandler(String(obj["id"]["code"]));
				switch(String(obj["id"]["code"]))
				{
					case "NetStream.Play.Complete" :
					{
						onPlayFinalComplete();
						break;
					}
					
				}
			}
		}
		
		override public function onMetadataReceived(event:Event):void
		{
			/*if(this._vid)
				this._vid.visible = true;*/
			_guiMngr.updateRightTF(SephPlayerUtils.convertFromSecToMin(_player.metadata.duration));
			super.onMetadataReceived(event);
			
			this.exploreVideoDecodingCapability();
			
			Traceable.doTrace(this + ": Metadata received.", "info");
		}
		
		public function onBWDone(kbitDown:Number = NaN, deltaDown:Number = NaN, deltaTime:Number = NaN, latency:Number = NaN):void
		{
			//trace("onBWDone: " + kbitDown);
			//_player.guiMngr.notice("Speed: " + kbitDown);
			Traceable.doTrace("onBWDone: kbitDown:"+kbitDown+" deltaDown:"+deltaDown+" deltaTime:"+deltaTime+" latency:"+latency);
			// app logic based on the bandwidth detected follows here
			if(!isNaN(kbitDown))
			{				
				_player.usrDetailsMngr.bandwidth = kbitDown;
				
				if(!this._isPlayTransitioning &&
				   this._player.playlistMngr.getCurrentClip().streams &&
				   this._player.playlistMngr.getCurrentClip().streams.length > 1)
				{
					if(kbitDown < SephPlayerGlobal.BITRATE_THRESHOLD_SIMPLE)
					{
						// low bitrate
						_player.guiMngr.receiveGUIEvent(SephPlayerEvent.BITRATE_GUI_CHANGE_REQUEST, 1);
					}
					else
					{
						// high bitrate
						var highestIndex:int = this._player.playlistMngr.getCurrentClip().streams.length;
						_player.guiMngr.receiveGUIEvent(SephPlayerEvent.BITRATE_GUI_CHANGE_REQUEST, highestIndex);
					}
				}				
			}
			
			this._player.evtMngr.dispatchEvent(new ItemEvent(SephPlayerEvent.BANDWIDTH_DETECTED, kbitDown));
			// close the Netconnection to bwcheck
			
			if(this._bwcheckTimer)
			{
				this._bwcheckTimer.reset();
				this._bwcheckTimer.start();
			}
			else
			{
				if(this._player.config.allowBWCheck)
				{
					this._bwcheckTimer = new Timer(300000, 1);
					this._bwcheckTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onBWCheckTimerHandler, false, 0, true);
					//this._bwcheckTimer.start();
					// since this is the first time, we should call bwcheck immediately (so we wont have to wait for 30 seconds
					this.doCheckBW();
				}
			}			
		}
		
		override public function onTimerHandler(event:TimerEvent):void
		{
			//trace("Timer info: time " + _ns.time + " duration " + _player.metadata.duration);
			var progPerc:Number = this.getProgPerc();
			var loadPerc:Number = this.getLoadPerc();
			_guiMngr.updateBar(progPerc, loadPerc);
			_guiMngr.updateLeftTF(SephPlayerUtils.convertFromSecToMin(this.time));
			this._player.evtMngr.onPlayTimeUpdatedHandler(new ItemEvent(SephPlayerEvent.PLAY_TIME_UPDATED, this.time));
		}
		
		override public function getProgPerc():Number
		{
			if(_ns)
				return (!isNaN(_player.metadata.duration))? this.time / Number(_player.metadata.duration) * 100 : 0;
			return 0;
		}
		
		override public function getLoadPerc():Number
		{
			if(_ns)
				return _ns.bytesLoaded / _ns.bytesTotal * 100;
			return 0;
		}
		
		override public function set mute(flag:Boolean):void
		{
			this._mute = flag;
			_player.config.mute = this.mute;
			
			if(!_ns)
				return;
			
			if(this._mute)
				_ns.soundTransform = new SoundTransform(0);
			else
				_ns.soundTransform = new SoundTransform(1);
		}
		
		override public function getStreamInfo():Object
		{
			if(this._ns)
				return this._ns.info;
			return null;
		}
		
		override public function dispose():Boolean
		{			
			if(_ns)
			{
				_ns.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatusHandler); // !very important
				_ns.pause();
				_ns.close();
				if(_ns.client && _ns.client is NetStatusClient)
					_ns.client.dispose(); // only works with NetStatusClient
				_ns.client = {};
				_ns = null;
			}
			
			this.disposeVid();
			
			if(_nc)
			{
				try
				{
					_nc.close();
				}
				catch(e:Error)
				{
					Traceable.doTrace(this + ": Error while trying to close NetConnection.", "error");
				}
				_nc.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatusHandler);
				if(_nc.client)
					_nc.client = {};
				_nc = null;
			}
			
			if(this._bwcheckTimer)
			{
				this._bwcheckTimer.stop();
				this._bwcheckTimer.removeEventListener(TimerEvent.TIMER, onBWCheckTimerHandler);
				this._bwcheckTimer = null;
			}
			
			if(this._reConnectTimer)
			{
				this._reConnectTimer.stop();
				this._reConnectTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, doReconnect);
				this._reConnectTimer = null;
			}
			
			if(this._bufferEmptyTimer)
			{
				this._bufferEmptyTimer.stop();
				this._bufferEmptyTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, doReconnect);
				this._bufferEmptyTimer = null;
			}
			
			return super.dispose();
		}
		
		protected function disposeVid():void
		{
			if(_vid)
			{
				/*
				if(SephPlayerUtils.isFlash10Point2())
					_vid.removeEventListener(VideoEvent.RENDER_STATE, onVideoRenderStateHandler);
				*/
				
				_vid.clear();
				if(_vid.parent)
					_vid.parent.removeChild(_vid);
				_vid = null;
			}
		}
		
		
		/* The following methods are for compatibility with Wowza */
		public function onBwCheck(param:*):void
		{
			//trace("onBwCheck:\n");
			/*
			for(var key:String in param)
			{
				trace("\t" + key + ": " + param[key]);
			}
			*/
		}
		
		public function onBWCheck(param:*):void
		{
			//trace("onBWCheck:\n");
			/*
			for(var key:String in param)
			{
				trace("\t" + key + ": " + param[key]);
			}
			*/
		}
		
		public function setTitle():String
		{
			return "media";
		}
		
		/* The following methods are for compatibility with FMS */
		
		/*
		public function onBWDone():void
		{
			trace("onBwDone");
		}
		*/
		
		public function close():void
		{
			Traceable.doTrace(this + ": NetConnection closed by server.");
		}
		
		protected function onBWCheckTimerHandler(event:TimerEvent):void
		{
			if(!this._isPausing)
				doCheckBW();
		}
		
		protected function doCheckBW():void
		{
			try
			{
				this._nc.call("checkBandwidth", null);
			}
			catch(e:Error)
			{
				Traceable.doTrace(this + ": Error calling \"checkBandwidth\" on server.","error");
			}
		}
		
		override public function getApplicationConnectionCount(event:Event = null):void
		{
			if(this._nc)
				this._nc.call("getApplicationConnectionCount", this._appConnCountResponder);
		}
		
		override protected function onAppConnCountResHandler(count:Number):void
		{
			_player.evtMngr.dispatchEvent(new ItemEvent(SephPlayerEvent.CONNECTED_USERS_COUNT_RESULT, count));
		}
		
	}	
}