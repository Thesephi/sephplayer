package seph.media.sephPlayer.utils
{
	import com.adobe.serialization.json.JSON;
	
	import flash.xml.*;
	
	import seph.utils.Traceable;
	
	public class ConfigManager
	{		
		// this is mostly used to loop through the list of all configurations
		// and return the information to an external environment
		public var configList:Array = ["file",
									   "streamer",
									   "streamerArg",
									   "controls",
									   "autoStart",
									   "mute",
									   "smoothing",
									   "scaleMode",
									   "background",
									   "repeat",
									   "lang",
									   "plugins",
									   "start",
									   "dynamic",
									   "streams",
									   "skin",
									   "overlay",
									   "overlayPosition",
									   "live",
									   "loadBalancerUrl",
									   "allowBWCheck"
									   ];
		
		private var _file:String;
		private var _streamer:String;
		private var _streamerArg:String;
		private var _controls:String = "always"; // always | auto | none
		private var _autoStart:Boolean = false;
		private var _mute:Boolean = false;
		private var _smoothing:Boolean = true;
		private var _scaleMode:String = "showAll"; // showAll | exactFit | noScale | lossyScale
		private var _background:* = 0x000000;
		private var _repeat:String = "none"; // one | playlist | none
		private var _lang:String = "VN"; // VN | EN
		private var _plugins:*;
		private var _start:Number = 0;
		
		// dynamic means there are more than 1 stream for the clip being played
		// which is stored in the "streams" array config variable
		private var _dynamic:Boolean = false;
		private var _streams:Array = null;
		
		private var _skin:String;
		private var _overlay:String;
		private var _overlayPosition:int = 2; // 2 means the top - right corner of the display area
		private var _live:Boolean = false;
		private var _cca:String; // list of country code allowed to view the content / connect to the server, separated by colons
		private var _loadBalancerUrl:String = null;
		private var _allowBWCheck:Boolean;
		
		public function get file():String {
			return this._file;
		}
		public function set file(val:String):void {
			this._file = val;
		}
		
		public function get streamer():String {
			return this._streamer;
		}
		public function set streamer(val:String):void {
			this._streamer = val;
		}
		
		public function get streamerArg():String {
			return this._streamerArg;
		}
		public function set streamerArg(val:String):void {
			this._streamerArg = val;
		}
		
		public function get controls():String {
			return this._controls;
		}
		public function set controls(val:String):void {
			this._controls = val;
		}
		
		public function get autoStart():Boolean {
			return this._autoStart;
		}
		public function set autoStart(val:Boolean):void {
			this._autoStart = val;
		}
		
		public function get mute():Boolean {
			return this._mute;
		}
		public function set mute(val:Boolean):void {
			this._mute = val;
		}
		
		public function get smoothing():Boolean {
			return this._smoothing;
		}
		public function set smoothing(val:Boolean):void {
			this._smoothing = val;
		}
		
		public function get scaleMode():String {
			return this._scaleMode;
		}
		public function set scaleMode(val:String):void {
			this._scaleMode = val;
		}
		
		public function get background():* {
			return this._background;
		}
		public function set background(val:*):void {
			this._background = val;
		}
		
		public function get repeat():String {
			return this._repeat;
		}
		public function set repeat(val:String):void {
			this._repeat = val;
		}
		
		public function get lang():String {
			return this._lang;
		}
		public function set lang(val:String):void {
			this._lang = val;
		}
		
		public function get plugins():* {
			return this._plugins;
		}
		public function set plugins(val:*):void {
			this._plugins = val;
		}
		
		public function get start():Number {
			return this._start;
		}
		public function set start(val:Number):void {
			this._start = val;
		}
		
		public function get dynamic():Boolean {
			return this._dynamic;
		}
		public function set dynamic(val:Boolean):void {
			this._dynamic = val;
		}
		
		public function get streams():Array {
			return this._streams;
		}
		public function set streams(val:Array):void {
			this._streams = val;
		}
		
		public function set skin(val:String):void {
			this._skin = val;
		}
		public function get skin():String {
			return this._skin;
		}
		
		public function set overlay(val:String):void {
			this._overlay = val;
		}
		public function get overlay():String {
			return this._overlay;
		}
		
		public function set overlayPosition(val:int):void {
			this._overlayPosition = val;
		}
		public function get overlayPosition():int {
			return this._overlayPosition;
		}
		
		public function set live(val:Boolean):void
		{
			this._live = val;
		}
		public function get live():Boolean
		{
			return this._live;
		}
		
		public function set cca(val:String):void
		{
			this._cca = val;
		}
		public function get cca():String
		{
			return this._cca;
		}
		
		public function set loadBalancerUrl(val:String):void
		{
			this._loadBalancerUrl = val;
		}
		public function get loadBalancerUrl():String
		{
			return this._loadBalancerUrl;
		}
		
		public function set allowBWCheck(val:Boolean):void
		{
			this._allowBWCheck = val;
		}
		public function get allowBWCheck():Boolean
		{
			return this._allowBWCheck;
		}
		
		public function ConfigManager()
		{
			// constructor code
		}
		
		public function getConfig(type:String = null):*
		{
			var res:*;
			if(!type)
			{
				res = {
					file:this._file,
					streamer:this._streamer,
					streamerArg:this._streamerArg,
					controls:this._controls,
					autoStart:this._autoStart,
					mute:this._mute,
					smoothing:this._smoothing,
					scaleMode:this._scaleMode,
					background:this._background,
					repeat:this._repeat,
					lang:this._lang,
					plugins:this._plugins,
					start:this._start,
					dynamic:this._dynamic,
					streams:this._streams,
					overlay:this._overlay,
					overlayPosition:this._overlayPosition,
					live:this._live,
					cca:this._cca,
					loadBalancerUrl:this._loadBalancerUrl,
					allowBWCheck:this._allowBWCheck
				};
			}
			else
			{
				switch(type)
				{
					case "file" :
						res = this._file;
					break;
					case "streamer" :
						res = this._streamer;
					break;
					case "streamerArg" :
						res = this._streamerArg;
					break;
					case "controls" :
						res = this._controls;
					break;
					case "autoStart" :
						res = this._autoStart;
					break;
					case "mute" :
						res = this._mute;
					break;
					case "smoothing" :
						res = this._smoothing;
					break;
					case "scaleMode" :
						res = this._scaleMode;
					break;
					case "background" :
						res = this._background;
					break;
					case "repeat" :
						res = this._repeat;
					break;
					case "lang" :
						res = this._lang;
					break;
					case "plugins" :
						res = this._plugins;
					break;
					case "start" :
						res = this._start;
					break;
					case "dynamic" :
						res = this._dynamic;
					break;
					case "streams" :
						res = this._streams;
					break;
					case "overlay" :
						res = this._overlay;
					break;
					case "overlayPosition" :
						res = this._overlayPosition;
					break;
					case "live" :
						res = this._live;
					break;
					case "cca" :
						res = this._cca;
					break;
					case "loadBalancerUrl" :
						res = this._loadBalancerUrl;
					break;
					case "allowBWCheck" :
						res = this._allowBWCheck;
					break;
				}
			}
			return res;
		}
		
		public function parseXML(xml:XML):void
		{
			this._file = String(xml.file);
			this._streamer = String(xml.streamer);
			this._streamerArg = String(xml.streamerArg);
			this._controls = String(xml.controls);
			this._autoStart = (String(xml.autoStart) == "true")? true : false;
			this._mute = (String(xml.mute) == "true")? true : false;
			this._smoothing = (String(xml.smoothing) == "true")? true : false;
			this._scaleMode = String(xml.scaleMode);
			this._background = String(xml.background);
			this._repeat = String(xml.repeat);
			this._lang = String(xml.lang);
			this._start = Number(xml.start);
			
			if(xml.plugins.length() > 0)
			{
				this._plugins = [];
				for each(var pluginItm:XML in xml.plugins)
				{
					try
					{
						var thePlugin:Object = {};
						thePlugin.name = String(pluginItm.name);
						thePlugin.source = String(pluginItm.source);
						thePlugin.config = com.adobe.serialization.json.JSON.decode(String(pluginItm.config));
						this._plugins.push(thePlugin);
					}
					catch(e:Error)
					{
						Traceable.doTrace(this + ": Error loading a plugin from XML Playlist.");
						continue;
					}
				}
			}
			
			this._dynamic = (String(xml.dynamic) == "true")? true : false;
			if(xml.streams.length() > 0)
			{
				this._streams = [];
				for each(var streamItm:XML in xml.streams)
				{
					this._streams.push(String(streamItm));
				}
			}
			
			this._skin = String(xml.skin);
			this._overlay = String(xml.overlay);
			this._overlayPosition = int(xml.overlayPosition);
			this._live = (String(xml.live) == "true")? true : false;
			this._cca = String(xml.cca);
			this._loadBalancerUrl = String(xml.loadBalancerUrl);
			this._allowBWCheck = (String(xml.allowBWCheck) == "true")? true : false;
		}

	}
	
}
