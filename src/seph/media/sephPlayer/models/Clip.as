package seph.media.sephPlayer.models
{
	import seph.media.sephPlayer.utils.SephPlayerUtils;
	import seph.utils.Traceable;
	
	public class Clip
	{
		protected var _title:String;
		protected var _url:String; // fully-qualified URL to the clip
		protected var _streamNameWithPrefix:String;
		protected var _file:String; // equals the "file" property of the ConfigManager class
		protected var _streamer:String; // of course, this equals the "streamer" property of the ConfigManager class
		protected var _durationInSeconds:int; // this should be the "duration" property of the MetadataManager class whenever it's available
		protected var _playerConfig:Object;
		protected var _metadata:Object;
		protected var _clipType:String = "untyped"; // "main" or "ad" (or w/e you'll need)
		protected var _start:Number = 0; // the second offset from which this clip is played
		protected var _dynamic:Boolean = false;
		protected var _streams:Array;
		
		// array containing the instruction for loading specific plugins to the clip
		// this will has the form of
		// [
		//		{
		//			name:"xxx",
		//			source:"xxx",
		//			config:{}
		//		},
		//		{
		//			name:"xxx",
		//			source:"xxx",
		//			config:{}
		//		}
		// ]
		//
		protected var _plugins:Array;
		
		public function Clip(file:String = null,
							 streamer:String = null,
							 playerConfig:Object = null,
							 metadata:Object = null,
							 clipType:String = null,
							 durationInSeconds:int = 0,
							 title:String = null,
							 streamNameWithPrefix:String = null,
							 url:String = null,
							 plugins:Array = null,
							 start:Number = 0,
							 dynamic:Boolean = false,
							 streams:Array = null)
		{	
			this._title = title;
			this._url = url;
			this._streamNameWithPrefix = streamNameWithPrefix;
			this._file = file;
			this._streamer = streamer;
			this._durationInSeconds = durationInSeconds;
			this._playerConfig = playerConfig;
			this._metadata = metadata;
			this._clipType = clipType;
			this._plugins = plugins;
			this._start = start;
			this._dynamic = dynamic;
			this._streams = streams;
			
			/*c.setPropertyIsEnumerable("file", true);
			c.setPropertyIsEnumerable("streamer", true);
			c.setPropertyIsEnumerable("clipType", true);
			c.setPropertyIsEnumerable("title", true);
			c.setPropertyIsEnumerable("streamNameWithPrefix", true);
			c.setPropertyIsEnumerable("url", true);*/
		}
		
		public function initializeFromObject(obj:*):void
		{
			if(obj["file"])
				this._file = String(obj["file"]);
			if(obj["streamer"])
			{
				var streamerArg:String = (obj["streamerArg"])? String(obj["streamerArg"]) : null;
				this._streamer = SephPlayerUtils.getStreamerFromStreamerAndStreamerArg(String(obj["streamer"]),streamerArg);
			}
			// tranfer the appropriate clip-specific settings to the "playerConfig" property
			if(obj["playerConfig"])
				this._playerConfig = obj["playerConfig"];
			else
				this._playerConfig = new Object();
			
			if(obj["controls"])
				this._playerConfig.controls = obj["controls"];
			
			if(obj.hasOwnProperty("autoStart"))
			{
				if(String(obj["autoStart"]) == "true")
					this._playerConfig.autoStart = true;
				else
					this._playerConfig.autoStart = false;
			}
			else
			{
				this._playerConfig.autoStart = false;
			}
			
			if(obj["mute"])
			{
				if(String(obj["mute"]) == "true")
					this._playerConfig.mute = true;
				else
					this._playerConfig.mute = false;
			}
			
			if(obj["dynamic"])
			{
				if(String(obj["dynamic"]) == "true")
					this._dynamic = true;
				else
					this._dynamic = false;
			}
			
			if(obj["scaleMode"])
				this._playerConfig.scaleMode = obj["scaleMode"];
			
			if(obj["background"])
				this._playerConfig.background = obj["background"];
			
			if(obj["lang"])
				this._playerConfig.lang = obj["lang"];
			
			
			if(obj["metadata"])
				this._metadata = obj["metadata"];
			
			if(obj["clipType"])
				this._clipType = String(obj["clipType"]);
			
			if(obj["duration"])
				this._durationInSeconds = uint(obj["duration"]);
			
			if(obj["movieTitle"])
				this._title = String(obj["movieTitle"]);
			
			if(obj["streamNameWithPrefix"])
				this._streamNameWithPrefix = String(obj["streamNameWithPrefix"]);
			
			if(obj["url"])
				this._url = String(obj["url"]);
			
			if(obj["plugins"])
			{
				if(obj["plugins"] is Array)
					this._plugins = obj["plugins"] as Array;
				else
					this._plugins = [obj["plugins"]];
			}
			
			if(obj["start"])
			{
				this._start = Number(obj["start"]);
				if(isNaN(this._start))
					this._start = 0;
			}
			
			if(obj["streams"] && obj["streams"] is Array)
				this._streams = obj["streams"];
		}
		
		public function dispose():void
		{
			this._title = null;
			this._url = null;
			this._streamNameWithPrefix = null;
			this._file = null;
			this._streamer = null;
			this._durationInSeconds = 0;
			this._playerConfig = null;
			this._metadata = null;
			this._clipType = null;
			this._plugins = null;
			this._start = NaN;
			this._streams = null;
		}
		
		public function get title():String
		{
			return this._title;
		}
		public function set title(title:String):void
		{
			this._title = title;
		}
		
		public function get url():String
		{
			return this._url;
		}
		public function set url(url:String):void
		{
			this._url = url;
		}
		
		public function get streamNameWithPrefix():String
		{
			return this._streamNameWithPrefix;
		}
		public function set streamNameWithPrefix(val:String):void
		{
			this._streamNameWithPrefix = val;
		}
		
		public function get file():String
		{
			return this._file;
		}
		public function set file(val:String):void
		{
			this._file = val;
		}
		
		public function get streamer():String
		{
			return this._streamer;
		}
		public function set streamer(streamer:String):void
		{
			this._streamer = streamer;
		}
		
		public function get durationInSeconds():int
		{
			return this._durationInSeconds;
		}
		public function set durationInSeconds(dur:int):void
		{
			this._durationInSeconds = dur;
		}
		
		public function get playerConfig():Object
		{
			return this._playerConfig;
		}
		public function set playerConfig(conf:Object):void
		{
			this._playerConfig = conf;
		}
		
		public function get metadata():Object
		{
			return this._metadata;
		}
		public function set metadata(dat:Object):void
		{
			this._metadata = dat;
		}
		
		public function get clipType():String
		{
			return String(this._clipType);
		}
		public function set clipType(clipType:String):void
		{
			this._clipType = clipType;
		}
		
		public function get plugins():Array
		{
			return this._plugins;
		}
		public function set plugins(val:Array):void
		{
			this._plugins = val;
		}
		
		public function get start():Number
		{
			return this._start;
		}
		public function set start(val:Number):void
		{
			this._start = val;
		}
		
		public function get dynamic():Boolean
		{
			return this._dynamic;
		}
		public function set dynamic(val:Boolean):void
		{
			this._dynamic = val;
		}
		
		public function get streams():Array
		{
			return this._streams;
		}
		public function set streams(val:Array):void
		{
			this._streams = val;
		}
	}
}
