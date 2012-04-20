////////////////////////////////////////////////////////////////////////////////
//
//  PHAN VIET ADVERTISING AND COMMUNICATION
//  Copyright 2011 Khang Dinh
//  All Rights Reserved.
//
//  NOTICE: as of April 19th, 2012 this has become an Open Source software
//  You are allowed to edit, recompile and use SephPlayer core in your project
//  provided that this header copy is always left intact.
//  Thank you for your understanding! Cheers
//
////////////////////////////////////////////////////////////////////////////////

/**
 * 
 * @author Khang Dinh
 * @version $Id: SephPlayer.as
 * 
 */

package seph.media.sephPlayer
{	
	import com.google.analytics.AnalyticsTracker;
	import com.google.analytics.GATracker;
	
	import flash.display.*;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.Security;
	
	import mx.core.UIComponent;
	
	import seph.URLGrabber;
	import seph.Utilities;
	import seph.media.sephPlayer.events.SephPlayerEvent;
	import seph.media.sephPlayer.lang.*;
	import seph.media.sephPlayer.models.AbstractPlayModel;
	import seph.media.sephPlayer.models.Clip;
	import seph.media.sephPlayer.models.VideoPlayModel;
	import seph.media.sephPlayer.parsers.SmilParser;
	import seph.media.sephPlayer.utils.ClassResolver;
	import seph.media.sephPlayer.utils.ConfigManager;
	import seph.media.sephPlayer.utils.EventManager;
	import seph.media.sephPlayer.utils.GUIManager;
	import seph.media.sephPlayer.utils.MetadataManager;
	import seph.media.sephPlayer.utils.PlayInStreamManager;
	import seph.media.sephPlayer.utils.PlaylistManager;
	import seph.media.sephPlayer.utils.PluginManager;
	import seph.media.sephPlayer.utils.SephPlayerUtils;
	import seph.media.sephPlayer.utils.UserDetailsManager;
	import seph.utils.MemoryTester;
	import seph.utils.Traceable;
	
	[SWF(width="640", height="360", frameRate="24", backgroundColor="#000000")]
	public class SephPlayer extends Sprite
	{		
		include "Version";
		public static var LANG:Class = Vn;
		
		/**
		 * Application.application.parameters will point to this property
		 * on Flex ApplicationComplete handler
		 */
		public var flashvarsFromFlexApp:*;
		
		//----------------------------------
		//  methods to set the size of the
		//  player
		//----------------------------------
		private var _width:Number;
		private var _height:Number;
		override public function get width():Number
		{
			return this._width;
		}
		override public function set width(w:Number):void
		{
			this._width = w;
			if(_guiMngr)
				_guiMngr.setSize(this._width, this._height);
		}
		override public function get height():Number
		{
			return this._height;
		}
		override public function set height(h:Number):void
		{
			this._height = h;
			if(_guiMngr)
				_guiMngr.setSize(this._width, this._height);
		}
		public function setSize(wid:Number, hei:Number):void
		{
			this._width = wid;
			this._height = hei;
			if(_guiMngr)
				_guiMngr.setSize(this._width, this._height);
		}
		
		private var _selfDomain:String;
		
		//----------------------------------
		//  internal core elements
		//----------------------------------
		private var _metaMngr:MetadataManager;
		private var _guiMngr:GUIManager;
		private var _confMngr:ConfigManager;
		private var _evtMngr:EventManager;
		private var _pluginMngr:PluginManager;
		private var _playlistMngr:PlaylistManager;
		private var _usrDetailsMngr:UserDetailsManager;
		private var _playInStreamMngr:PlayInStreamManager;
		private var _playModel:AbstractPlayModel;
		
		//----------------------------------
		//  keep track of system memory
		//----------------------------------
		private var _memTest:MemoryTester;
		
		//----------------------------------
		// Google Analytics for Flash
		//----------------------------------
		private var _tracker:AnalyticsTracker;
		public function get tracker():AnalyticsTracker
		{
			return this._tracker;
		}
		private var _sephGaTracker:AnalyticsTracker;
		public function get sephGaTracker():AnalyticsTracker
		{
			return this._sephGaTracker;
		}
		
		//----------------------------------------------------------
		// we don't want to init() the player once it's already been
		//----------------------------------------------------------
		private var __init:Boolean = false;
		
		/**
		 * This is a description of whatever media the player is CURRENTLY playing.
		 * it can be used to denote that the player is playing a TVC or the main media 
		 * or an mp3 file or ogg file with streamer, etc.
		 * Its value should be the same as the title of the clip being played
		 */
		protected var _currentPlaying:String;
		public function get currentPlaying():String
		{
			return this._currentPlaying;
		}
		public function set currentPlaying(val:String):void
		{
			this._currentPlaying = val;
		}
		
		/**
		 * Indicate if the player is playing through a session of inStream clip(s)
		 */
		public function get isInInStreamSession():Boolean
		{
			return this._isInInStreamSession;
		}
		public function set isInInStreamSession(val:Boolean):void
		{
			this._isInInStreamSession = val;
		}
		private var _isInInStreamSession:Boolean = false;
		
		/**
		 * Class pointing to the skin and loading animation that's used throughout the player
		 */
		public var DefaultSkin:Class;
		
		/*
		 * Create a new instance of SephPlayer
		 * After the player inits successfully, its EventManager will dispatch the "SephPlayerEvent.READY" event
		 * So please listen to this event if you plan to explicitly call methods on SephPlayer
		 * Otherwise, the player should behave according to what is specified in the flashvars (file, autoStart, etc.)
		 * @param skin can be a Class or a String to the URL of the GUI swf file
		 */
		public function SephPlayer(skin:*=null)
		{	
			this._width = (super.width > 0)? super.width : 640;
			this._height = (super.height > 0)? super.height : 360;
			
			// this will be changed later by the flashvars, if available
			Traceable.TRACE_LEVEL = Traceable.TRACE_LEVEL_NONE;
			
			//this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStageHandler, false, 0, true);
			
			// specify skin information if you dont need init() to be called explicitly
			// (in Vivo player it's called explicitly)
			if(skin)
				this.init(skin);
			
			// doing like the below will FAIL miserably when the flash is embedded in Firefox
			// with "wmode" set to "transparent" or "opaque"
			//this.loaderInfo.addEventListener(Event.COMPLETE, onLoadCompleteHandler, false, 0, true);
			
		}
		
		public function init(skin:*=null):void
		{
			if(this.__init)
				return;
			else
				this.__init = true;
			
			// do this first to make sure all FlashVars are put into placed
			initVars();
			
			if(skin && skin is Class)
			{
				this.DefaultSkin = skin;
				initExternals();
				initGUI();
				initApp();
			}
			else
			{
				// logically this means skin == null or skin != Class (we're expecting a String)
				// so if it's a String, assign it to config.skin (so we're not depending on the "skin" flashvar
				if(skin is String)
					this._confMngr.skin = String(skin);
				
				// if there is not a SkinClass yet (i.e. SephPlayer is instantiated as a Document Class)
				// try to load it from FlashVar or external SWF
				// before initializing other things
				resolveSkinClass();
			}
			
			//_memTest = new MemoryTester();			
		}
		
		/**
		 * This registers the Classes loaded into Flex (from a SWC file)
		 * so that they can be instantiated properly
		 * 
		 */		
		private function resolveSkinClass():void
		{
			try
			{
				ClassResolver.registerClass(DefaultSkin,"DefaultSkin");
			}
			catch(e:Error)
			{
				Traceable.doTrace("Failed to retrieve embedded skin for this application. Now try to load external skin via the FlashVar \"skin\". Error detail: " + e, "error");
			}
			
			if(!DefaultSkin)
			{
				// try to load an external SWF file for the skin elements
				var skinLdr:Loader = new Loader();
				skinLdr.contentLoaderInfo.addEventListener(Event.COMPLETE, onSkinLoadCompleteHandler, false, 0, true);
				skinLdr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onSkinLoadErrorHandler, false, 0, true);
				skinLdr.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSkinLoadErrorHandler, false, 0, true);
				
				// the skin SWF file should be loaded to the same ApplicationDomain as this's, so we can freely refer to it from anywhere
				var ctx:LoaderContext = new LoaderContext(false, this.root.loaderInfo.applicationDomain, null);
				skinLdr.load(new URLRequest(this.config.skin), ctx);
			}
		}
		
		private function onSkinLoadCompleteHandler(event:Event):void
		{
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, this.onSkinLoadErrorHandler);
			event.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onSkinLoadErrorHandler);
			event.target.removeEventListener(Event.COMPLETE, this.onSkinLoadCompleteHandler);
			
			Traceable.doTrace("Skin SWF load complete.","info");
			
			this.dispatchEvent(new Event(SephPlayerEvent.SKIN_ASSET_LOAD_COMPLETE));
			
			this.initExternals();
			this.initGUI();
			this.initApp();
		}
		
		private function onSkinLoadErrorHandler(event:Event):void
		{
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, this.onSkinLoadErrorHandler);
			event.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onSkinLoadErrorHandler);
			event.target.removeEventListener(Event.COMPLETE, this.onSkinLoadCompleteHandler);
			
			Traceable.doTrace("Failed to retrieve skin for this application. Error detail: " + event, "error");
			this.dispatchEvent(new Event(SephPlayerEvent.SKIN_ASSET_LOAD_FAIL));
		}
		
		private function initExternals():void
		{
			try
			{
				ExternalInterface.marshallExceptions = true;
				ExternalInterface.addCallback(SephPlayerGlobal.EXTERNAL_SEND_EVENT_FUNC_NAME, this.evtMngr.sendEvent);
				ExternalInterface.addCallback(SephPlayerGlobal.EXTERNAL_PLAYFILE_FUNC_NAME, this.playFile);
				ExternalInterface.addCallback(SephPlayerGlobal.EXTERNAL_SET_SOURCE_FUNC_NAME, this.setSource);
				ExternalInterface.addCallback(SephPlayerGlobal.EXTERNAL_LOAD_PLUGIN_FUNC_NAME, this.pluginMngr.loadPlugin);
				ExternalInterface.addCallback(SephPlayerGlobal.EXTERNAL_SWITCH_TO_STREAM_NAME_FUNC_NAME, this.switchToStreamName);
				
				ExternalInterface.call(SephPlayerGlobal.DECLARE_JS_FUNC_RECORD_LAST_ERROR);
			}
			catch(e:Error)
			{
				Traceable.doTrace(this + ": Failed to init ExternalInterface components. Probably wrong \"allowScriptAccess\" value.", "error"); 
			}
		}
		
		private function initVars():void
		{			
			_metaMngr = new MetadataManager();
			_confMngr = new ConfigManager();
			_evtMngr = new EventManager(this);
			_pluginMngr = new PluginManager(this);
			_playlistMngr = new PlaylistManager(this);
			_usrDetailsMngr = new UserDetailsManager();
			_playInStreamMngr = new PlayInStreamManager();
			
			_selfDomain = URLGrabber.getSelfDomain();
			if(!_selfDomain)
				_selfDomain = "null";
			
			var flashvars:* = flashvarsFromFlexApp;
			if(!flashvars && this.root && this.root.loaderInfo)
				flashvars = this.root.loaderInfo.parameters;
			
			if(flashvars["debug"])
				Traceable.TRACE_LEVEL = String(flashvars["debug"]);
			
			Traceable.doTrace("SephPlayer version " + VERSION + ". Double click to enter Fullscreen mode.\n" +
				"Requested file: " + flashvars["file"] + ", autoStart: " + flashvars["autoStart"] + ", scaleMode: " + flashvars["scaleMode"] + ", selfDomain: " + _selfDomain, "info"
			);
			
			Traceable.doTrace("Inspect the \"streamer\" flashvar... This will overwrite whatever \"streamer\" value defined in the \"file\" flashvar","info");
			if(flashvars["streamer"] && flashvars["streamer"] != "" && flashvars["streamer"] != "null")
			{				
				/*
				var streamer:String = flashvars["streamer"];
				var ampsIndex:int = streamer.indexOf("#");
				if(ampsIndex != -1) // there is a letter "#" in the rtmp link -> security check!
				{
					_confMngr.streamer = streamer.substring(0,ampsIndex);
					_confMngr.streamerArg = streamer.substr(ampsIndex + 1, streamer.length - ampsIndex);
				}
				else
				{
					// there is no letter "#" in the rtmp link -> carry out as normal
					_confMngr.streamer = streamer;
					if(flashvars["streamerArg"])
					{
						_confMngr.streamerArg = flashvars["streamerArg"];
					}
				}				
				Traceable.doTrace("\nSecuredStreamer: " + ((ampsIndex != -1 || _confMngr.streamerArg)? "yes" : "no") + ". Processed streamer: " + _confMngr.streamer + "#" + _confMngr.streamerArg, "info");
				*/
				
				var streamer:Object = SephPlayerUtils.getStreamerNameAndArg(String(flashvars["streamer"]));
				_confMngr.streamer = streamer["streamer"];
				_confMngr.streamerArg = streamer["streamerArg"];
				
				Traceable.doTrace("\nSecuredStreamer: " + ((_confMngr.streamerArg)? "yes" : "no") + ". Processed streamer: " + _confMngr.streamer + "#" + _confMngr.streamerArg, "info");
			}
			
			Traceable.doTrace("Done inspecting \"streamer\" flashvar.","info");
			
			Traceable.doTrace("Inspect the \"file\" flashvar...","info");
			if(flashvars["file"])
			{
				//if(flashvars["file"].indexOf("{") == 0 || flashvars["file"].indexOf("[") == 0) {
				var res:* = this.breakdownFileFlashvar(unescape(String(flashvars["file"])));
				if(res)
				{
					if(res is Clip)
					{						
						// just to be careful...
						if(res["file"])
							this._confMngr.file = res["file"];
						else
							this._confMngr.file = null;
						
						if(res["streamer"] && res["streamer"] != "" && res["streamer"] != "null")
						{
							var streamerObj:Object = SephPlayerUtils.getStreamerNameAndArg(res["streamer"]);
							this._confMngr.streamer = streamerObj["streamer"];
							this._confMngr.streamerArg = streamerObj["streamerArg"];
						}
						else if(res["streamer"] && res["streamer"] == "null")
						{
							this._confMngr.streamer = null;
						}
						
						// this makes sure the OVA plugin will not get the data from _confMngr
						// which is mostly null by now
						this._playlistMngr.initializeFromArray([res]);
						
					}
					else if(res is Array)
					{						
						// notice that this should be a Clip Array!
						
						// just to be careful...
						if(res.length > 0 && res[0] != null)
						{
							if(res[0]["file"])
								this._confMngr.file = res[0]["file"];
							else
								this._confMngr.file = null;

							if(res[0]["streamer"] && res[0]["streamer"] != "" && res[0]["streamer"] != "null")
							{
								streamerObj = SephPlayerUtils.getStreamerNameAndArg(res[0]["streamer"]);
								this._confMngr.streamer = streamerObj["streamer"];
								this._confMngr.streamerArg = streamerObj["streamerArg"];
							}
							else if(res[0]["streamer"] && res[0]["streamer"] == "null")
							{
								this._confMngr.streamer = null;
							}
						}
						
						// this makes sure the OVA plugin will not get the data from _confMngr
						// which is mostly null by now
						this._playlistMngr.initializeFromArray(res);
						
					}
					else if(res == "XML_PLAYLIST")
					{
						// TODO: manage XML playlist implementation
						// MAKE SURE the playlist is built
						// or the OVA plugin might not work well with the player
						this._confMngr.file = flashvars["file"];
					}
					else if(res == "SMIL_PLAYLIST")
					{
						this._confMngr.file = flashvars["file"];
					}
				}
				else
				{					
					// flashvar is just an ordinary String, most often the "file" config property
					
					// build an Array so that the OVA plugin wouldn't mistake this
					// for a "non-playlist" case
					// and thus loading the player's base plugin again
					this._confMngr.file = flashvars["file"];
					var c:Clip = new Clip(this._confMngr.file,
						SephPlayerUtils.getStreamerFromStreamerAndStreamerArg(this._confMngr.streamer, this._confMngr.streamerArg),
						null,null,null,0,
						this._confMngr.file,
						SephPlayerUtils.attachPrefix(this._confMngr.file),
						SephPlayerUtils.getQualifiedURLFromFileAndStreamer(this._confMngr.file, this._confMngr.streamer, this._confMngr.streamerArg),
						null);
					this.playlistMngr.initializeFromArray([c]);
				}
			}
			Traceable.doTrace("Done inspecting \"file\" flashvar.","info");
			
			Traceable.doTrace("Inspect other flashvars...","info");
			if(flashvars["controls"])
				_confMngr.controls = String(flashvars["controls"]);
			
			if(flashvars["autoStart"] && String(flashvars["autoStart"]).toLowerCase() == "true")
				_confMngr.autoStart = true;
			else
				_confMngr.autoStart = false;
			
			if(flashvars["mute"] && String(flashvars["mute"]).toLowerCase() == "true")
				_confMngr.mute = true;
			else
				_confMngr.mute = false;
			
			if(flashvars["scaleMode"])
				_confMngr.scaleMode = String(flashvars["scaleMode"]);
			
			if(flashvars["background"])
			{
				if(String(flashvars["background"]).indexOf("0x") == 0)
					_confMngr.background = Number(flashvars["background"]);
				else
					_confMngr.background = String(flashvars["background"]);
			}
			
			if(flashvars["lang"])
				_confMngr.lang = String(flashvars["lang"]);
			
			if(flashvars["dynamic"] && String(flashvars["dynamic"]).toLowerCase() == "true")
				_confMngr.dynamic = true;
			else
				_confMngr.dynamic = false;
			
			if(flashvars["skin"])
				_confMngr.skin = flashvars["skin"];
			
			if(flashvars["overlay"])
				_confMngr.overlay = String(flashvars["overlay"]);
			
			if(flashvars["overlayPosition"])
				_confMngr.overlayPosition = int(flashvars["overlayPosition"]);
			
			if(flashvars["live"] && String(flashvars["live"]).toLowerCase() == "true")
				_confMngr.live = true;
			else
				_confMngr.live = false;
			
			if(flashvars["cca"])
				_confMngr.cca = String(flashvars["cca"]);
			
			if(flashvars["gaWebId"])
			{
				var gaWebId:String = String(flashvars["gaWebId"]);
				this._tracker = new GATracker(this.root, gaWebId, "AS3", false);
				this._tracker.setDomainName("none");
				this._tracker.setAllowLinker(true);
				this._tracker.trackPageview();
			}
			this._sephGaTracker = new GATracker(this.root, "UA-23348048-3", "AS3", false);
			this._sephGaTracker.setDomainName("none");
			this._sephGaTracker.setAllowLinker(true);
			this._sephGaTracker.trackPageview();
			
			if(flashvars["loadBalancerUrl"])
				_confMngr.loadBalancerUrl = String(flashvars["loadBalancerUrl"]);
			
			// allow user defined callback function on some API events
			if(flashvars["onPlayComplete"])
				SephPlayerGlobal.EXTERNAL_FILE_PLAY_COMPLETE_FUNC_NAME = String(flashvars["onPlayComplete"]);
			
			if(flashvars["onPlaylistComplete"])
				SephPlayerGlobal.EXTERNAL_PLAYLIST_PLAY_COMPLETE_FUNC_NAME = String(flashvars["onPlaylistComplete"]);

			if(flashvars["onLoad"])
				SephPlayerGlobal.EXTERNAL_ON_LOAD_COMPLETE_FUNC_NAME = String(flashvars["onLoad"]);
			
			Traceable.doTrace("Done inspecting other flashvars.","info");
			
			Traceable.doTrace("Inspect \"plugins\" flashvar...","info");
			// since this might produce errors, i decided to put it at the bottom
			// where it won't interfere with other stuff
			// NOTICE that we only add the definition of the plugins to be loaded here
			// we will actually load the plugins later in the method initApp()
			// IF YOU DO THAT NOW THERE WILL BE AN ERROR!!!
			if(flashvars["plugins"] && String(flashvars["plugins"]).toLowerCase() != "null")
			{
				try
				{
					_confMngr.plugins = SephPlayerUtils.decodeJSONstring(unescape(flashvars["plugins"]),false);
					Traceable.doTrace("Plugins input from flashvars is an " + ((_confMngr.plugins is Array)? "array" : "object") + ": " + _confMngr.plugins.toString(),"info");
					Traceable.doTrace("Done inspecting \"plugins\" flashvar.","info");
				}
				catch(e:Error)
				{
					_confMngr.plugins = null;
					Traceable.doTrace("Error while inspecting \"plugins\" flashvar: " + e, "error");
				}
			}
		}
		
		/**
		 * This function takes the flashvars provided in the Clip item (via JavaScript objects)
		 * and pass them to the _confMngr where they are actually used to playback the Clip
		 */
		private function applyFlashvarsFromClip(c:Clip):void
		{
			// file, streamer and plugins are taken care of separately (refer playFile() function)
			if(!c.playerConfig)
			{
				c.playerConfig = {};
				Traceable.doTrace("This Clip item doesn't have specific playerConfig attached.", "warn");
				return;
			}
			if(c.playerConfig["controls"])
				this._confMngr.controls = String(c.playerConfig["controls"]);
			// below we use hasOwnProperty instead of the 'traditional' way (like the others) and it seems to work ok. Just a test.
			if(c.playerConfig.hasOwnProperty("autoStart"))
				this._confMngr.autoStart = (String(c.playerConfig["autoStart"]) == "true")? true : false;
			if(c.playerConfig["mute"])
				this._confMngr.mute = (c.playerConfig["mute"] || c.playerConfig["mute"] == "true")? true : false;
			if(c.playerConfig["scaleMode"])
				this._confMngr.scaleMode = String(c.playerConfig["scaleMode"]);
			if(c.playerConfig["background"])
				this._confMngr.background = c.playerConfig["background"];
			if(c.playerConfig["lang"])
				this._confMngr.lang = String(c.playerConfig["lang"]);
			this.guiMngr.applyConfig();
		}
		
		private function initGUI():void
		{			
			// since _width and _height has never been specified,
			// let's give them a default value now
			this._width = stage.stageWidth;
			this._height = stage.stageHeight;
			
			switch(_confMngr.lang)
			{
				case "EN" :
				case "En" :
				case "en" :
				{
					SephPlayer.LANG = En;
					break;
				}
				case "VN" :
				case "Vn" :
				case "vn" :
				default :
				{
					SephPlayer.LANG = Vn;
					break;
				}
			}
			
			var SkinClass:*;
			if(this.loaderInfo.applicationDomain.hasDefinition("DefaultSkin"))
				SkinClass = this.loaderInfo.applicationDomain.getDefinition("DefaultSkin");
			else
				SkinClass = DefaultSkin;
			
			_guiMngr = new GUIManager(this, new SkinClass());
			_guiMngr.notice("stageWidth: " + stage.stageWidth + ", stageHeight: " + stage.stageHeight);
			_guiMngr.notice("SephPlayer version " + VERSION + ". Double click to enter Fullscreen mode.\n" +
				"Requested file: " + _confMngr.file + ", autoStart: " + _confMngr.autoStart + ", scaleMode: " + _confMngr.scaleMode + ", selfDomain: " + _selfDomain +
				"\nSecuredStreamer: " + ((_confMngr.streamerArg)? "yes" : "no") + ". Processed streamer: " + _confMngr.streamer + "#" + _confMngr.streamerArg
			);
			
			stage.addEventListener(Event.RESIZE, onStageResizedHandler, false, 0, true);
			stage.dispatchEvent(new Event(Event.RESIZE));			
		}
		
		protected function initApp():void
		{			
			// !important. Make sure this is done BEFORE any ExternalInterface.call invocation
			// or it will fail miserably if cross-scripting
			Security.allowDomain(URLGrabber.getSelfDomain());
			
			Utilities.createCustomContextMenu(this, [{label:"SephPlayer " + SephPlayer.VERSION, breakLine:true, func:null, enabled:false, visible:true}]);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStageHandler, false, 0, true);
			
			// load the plugins specified in the flashvars
			// we can do it now since everything has been initialized already
			if(this._confMngr.plugins)
			{
				Traceable.doTrace("Begin to load plugins specified in the flashvars.","info");
				if(this._confMngr.plugins is Array)
					this._pluginMngr.loadPlugins(this._confMngr.plugins as Array);
				else
					this._pluginMngr.loadPlugins([this._confMngr.plugins]);
			}
			
			this._evtMngr.dispatchEvent(new Event(SephPlayerEvent.READY));
			if(ExternalInterface.available)
			{
				try
				{
					ExternalInterface.call(SephPlayerGlobal.EXTERNAL_ON_LOAD_COMPLETE_FUNC_NAME, ExternalInterface.objectID, "SephPlayer " + SephPlayer.VERSION + " has been inited.");	
				}
				catch(e:Error)
				{
					//
				}
			}
			
			// a few testbeds for file playback.
			// Make sure you test 2 successive calls on playFile() too!
			//this._confMngr.autoStart = true;
			//this.config.streamer = "rtmp://host.pvachouse.com/htv3_vod";
			//this.config.streamerArg = "sephVivo";
			//this.config.file = "resources/sikgaek_01_1.flv";
			//playFile("resources/cp1_1.flv");
			
			//playFile({file: "resources/sample2.f4v", movieTitle:"Sample2_F4V", scaleMode:"lossyScale"});
			
			//playFile("resources/sample2.f4v");
			//playFile("http://data.vivo.vn/files/upload/files/ads/2712_Omo_Tet_2011_Promotion_15s.flv");
			//Traceable.TRACE_LEVEL = Traceable.TRACE_LEVEL_ALL;
			
			//Traceable.TRACE_LEVEL = Traceable.TRACE_LEVEL_ALL;
			//this.config.streamer = "rtmp://115.84.182.85/vivo_all#sephVivo";
			//this.playFile("resources/sample2.f4v");
			//this.playFile("you_are_beautiful/hbf1_1.flv");
			//this.config.streamerArg = "sephVivo";
			//playFile("resources/1_30.f4v");
			//playFile("pasta_tmp.mp4");
			//playFile("sample_1280_720.flv");
			//playFile("sample_bit_rate_3.6mb.flv");
			//playFile("sample_bit_rate_900kb.flv");
			//this.config.streamer = "rtmp://115.84.182.85:80/vod";
			//this.playFile("mp4:sample.mp4");
			//playFile("bitrateSwitchTest.smil");
			
			// a few testbeds for playlist and clip-specific plugin(s)
			
			/*this.playFile([
			{
			file: "resources/sample2.f4v",
			movieTitle:"Sample2_F4V",
			plugins:[
			{
			name:"SubReader",
			source:"plugin_2-0/subReader/subReaderPlugin.swf",
			config:{
			source:"resources/sikgaek_01_P1.srt", 
			movieTitle:"Sample2_F4V", 
			textColor:0xFFFFFF, 
			marginBottom:20
			}
			}
			]
			},
			{
			file: "hk1_1-1.flv", 
			movieTitle:"HK",
			streamer: "rtmp://112.78.4.212/vivo_all#sephVivo",
			plugins:[
			{
			name:"SubReader",
			source:"plugin_2-0/subReader/subReaderPlugin.swf",
			config:{
			source:"resources/sikgaek_01_P1.srt", 
			movieTitle:"HK", 
			textColor:0xFFCC00, 
			marginBottom:20
			}
			}
			]
			}
			]);*/
			
			//playFile({file: "resources/sample2.f4v", movieTitle:"Sample2_F4V", scaleMode:"lossyScale"});
			//playFile({file: "bitrateSwitchTest.smil", streamer:"rtmp://115.84.182.85/vivo_all#sephVivo", movieTitle:"Sample2_F4V", scaleMode:"lossyScale"});
			
			// testbed for flashvar as a String (that is trying to implement itself as an object)
			//this._confMngr.file = "{file: 'resources/sample2.f4v', streamer:null, movieTitle:\"Sample2_F4V\"}";
			
			// a few testbeds for plugins
			//this._pluginMngr.loadPlugin("SubReader", "plugin_2-0/subReader/subReaderPlugin.swf", {source:"resources/sub.srt", movieTitle:"Sample2_F4V", textColor:0xFFFFFF, marginBottom:20});
			/*
			var t:Timer = new Timer(3000,1);
			t.addEventListener(TimerEvent.TIMER, onTestPluginTimer, false, 0, true);
			t.start();
			*/
			//this._pluginMngr.loadPlugin("AdRoll", "plugin_2-0/adRoll/adRollPlugin.swf", {type:"PreRoll", source:"resources/ad.mp4", clickTag:"http://www.htc.com"});
			/*this._pluginMngr.loadPlugin("OvaSephPlayer", "plugin_2-0/ova-sephPlayer/ova-sephPlayer.swf",
			{
			ads:
			{
			servers:
			[
			{
			type: "OpenX",
			apiAddress: "http://vietadsense.com/www/delivery/fc.php"
			}
			]
			},
			streams:
			[
			{
			file:"test1.mp4", 
			blah:"blah1"
			},
			{
			file:"test2.mp4", 
			blah:"blah2"
			}
			]
			}
			);*/
			
			//this._pluginMngr.loadPlugin("LiveNoticer", "../plugin_2-0/liveNoticer/liveNoticerPlugin.swf");
			
			/*this._pluginMngr.loadPlugin("OvaSephPlayer", "plugin_2-0/ova-sephPlayer/ova-sephPlayer.swf",
			{
			"overlays": {
			"regions": [
			{
			"id": "adNotice",
			"verticalAlign": "top",
			"horizontalAlign": "right",
			"backgroundColor": "#333333",
			"padding": "0 5 2 5",
			"width": 213,
			"height": 23,
			"style": ".adNoticeText { font-family: Tahoma; font-size: 10px; color:#CCCCCC; }"
			},
			{
			"id": "clickSign",
			"verticalAlign": "center",
			"horizontalAlign": "center",
			"backgroundColor": "#000000",
			"padding": "7 7 7 7",
			"width": 300,
			"height": 130,
			"style": ".adNoticeText { font-family: Tahoma; font-size: 10px; color:#FFFFFF; }"
			}
			]
			},
			
			"ads": {
			"servers": [
			{
			"type": "OpenX",
			"apiAddress": "http://localhost/openx/www/delivery/fc.php"
			}
			],
			"schedule": [
			{
			"zone": "2",
			"position": "pre-roll"
			}
			],
			"clickSign": {
			"region": "clickSign",
			"enabled": "true", 
			"verticalAlign": "center",
			"horizontalAlign": "center",
			"width": 300,
			"height": 150,
			"opacity": 0.5,
			"borderRadius": 20,
			"backgroundColor": "#000000",
			"html": "<p class=\"adNoticeText\" align=\"center\">CLICK ĐỂ BIẾT THÊM CHI TIẾT!</p>",
			"scaleRate": 0.75
			},
			"notice": {
			"region": "adNotice",
			"show": "true",
			"type": "countdown",
			"textStyle": "adNoticeText",
			"message":"<p align=\"right\">Còn _countdown_ giây đên nôi dung chính...</p>"
			}
			},
			
			"debug": {
			"debugger": "firebug",
			"levels": "clickthrough_events, vast_template, display_events, mouse_events" // "fatal, config, vast_template" //all // region_formation, display_events
			}
			}
			);*/
			
			/*
			this.playFile({file: "../resources/sample.mp4", movieTitle:"Sample", scaleMode:"lossyScale"});
			this._pluginMngr.loadPlugin("OvaSephPlayer", "../plugin_2-0/ova-sephPlayer/ova-sephPlayer.swf",
				{
					"overlays": {
						"regions": [
							{
								"id": "adNotice",
								"verticalAlign": "top",
								"horizontalAlign": "right",
								"backgroundColor": "#333333",
								"padding": "0 5 2 5",
								"width": 213,
								"height": 23,
								"style": ".adNoticeText { font-family: Verdana; font-size: 10px; color:#CCCCCC; }"
							},
							{
								"id": "clickSign",
								"verticalAlign": "center",
								"horizontalAlign": "center",
								"backgroundColor": "#000000",
								"padding": "7 7 7 7",
								"width": 300,
								"height": 130,
								"style": ".adNoticeText { font-family: Verdana; font-size: 10px; color:#FFFFFF; }"
							}
						]
					},
					
					"ads": {
						"servers": [
							{
								"type": "OpenX",
								"apiAddress": "http://localhost/openx/www/delivery/fc.php"
							}
						],
						"schedule": [
							{
								"zone": "2",
								"position": "pre-roll"
							},
							{
								"zone": "3",
								"startTime": "00:00:05",
								"position": "auto:center",
								"duration": "10"
							}
						],
						"clickSign": {
							"region": "clickSign",
							"enabled": "true", 
							"verticalAlign": "center",
							"horizontalAlign": "center",
							"width": 300,
							"height": 30,
							"opacity": 0.7,
							"borderRadius": 10,
							"backgroundColor": "#000000",
							"html": "<p class=\"adNoticeText\" align=\"center\">CLICK DE BIET THEM CHI TIET</p>",
							"scaleRate": 0.75
						},
						"notice": {
							"region": "adNotice",
							"show": "true",
							"type": "countdown",
							"textStyle": "adNoticeText",
							"message":"<p align=\"right\">Còn _countdown_ giây đên nôi dung chính...</p>"
						}
					},
					
					"debug": {
						"debugger": "firebug",
						"levels": "all" // "fatal, config, vast_template" //all // region_formation, display_events
					}
				}
				
			);
			*/
			
			//Security.allowDomain(this.root.loaderInfo.loaderURL);
			//this._pluginMngr.loadPlugin("SubReader","http://data.vivo.vn/files/flash/subReaderPlugin.swf",{source:"http://pvachouse.com/sephPlayer/resources/cp1_1.vn.srt", textColor:0xFFFFFF, backgroundColor:0x222222, marginBottom:13});
			//this._pluginMngr.loadPlugin("AdRoll","http://pvachouse.com/sephPlayer/resources/plugins/adRollPlugin.swf?rand=" + String(Math.random()),{type:"PreRoll", source:"http://pvachouse.com/sephPlayer/resources/ad.mp4", clickTag:"http://vivo.vn"});
			
			if(_confMngr.autoStart)
				this.evtMngr.sendEvent(SephPlayerEvent.PLAY_BTN_CLICKED);
			
			// various uses
			stage.addEventListener(KeyboardEvent.KEY_UP, onStageKeyUpHandler, false, 0, true);
		}
		
		private function onTestPluginTimer(event:TimerEvent):void
		{
			/*
			// this is to test the prevention of 2 or more plugins are forcifully loaded
			this._pluginMngr.loadPlugin("SubReader", "plugin_2-0/subReader/subReaderPlugin.swf", {source:"resources/sikgaek_01_P1.srt", movieTitle:"Sample2_F4V", textColor:0xFFFFFF, marginBottom:20});
			this._pluginMngr.loadPlugin("SubReader", "plugin_2-0/subReader/subReaderPlugin.swf", {source:"resources/sikgaek_01_P1.srt", movieTitle:"Sample2_F4V", textColor:0xFFFFFF, marginBottom:20});
			this._pluginMngr.loadPlugin("SubReader", "plugin_2-0/subReader/subReaderPlugin.swf", {source:"resources/sikgaek_01_P1.srt", movieTitle:"Sample2_F4V", textColor:0xFFFFFF, marginBottom:20});
			this._pluginMngr.loadPlugin("SubReader", "plugin_2-0/subReader/subReaderPlugin.swf", {source:"resources/sikgaek_01_P1.srt", movieTitle:"Sample2_F4V", textColor:0xFFFFFF, marginBottom:20});
			this._pluginMngr.loadPlugin("SubReader", "plugin_2-0/subReader/subReaderPlugin.swf", {source:"resources/sikgaek_01_P1.srt", movieTitle:"Sample2_F4V", textColor:0xFFFFFF, marginBottom:20});
			
			// this is to test the plugin removal ability
			var removed:Boolean = this._pluginMngr.removePlugin("SubReader");
			if(removed) {
			trace("Plugin Removal Done!");
			event.target.removeEventListener(TimerEvent.TIMER, onTestPluginTimer);
			}
			*/
		}
		
		private function breakdownFileFlashvar(file:String):*
		{
			try
			{
				// file can have many formats and forms, such as a url pointing to a specific media file,
				// or a url pointing to an XML playlist,
				// or a javascript Object containing the file and streamer that needs to be updated
				// let's take care of this in each and every possible manner
				
				// the value of SephPlayerUtils.getStreamerNameAndArg()
				// will be passed into this variable for use at many locations below
				var streamerObj:Object;
				
				// in each of the cases where a player can play a file instantly
				// (the file variable does NOT point to a playlist or something other
				// than a playable movie clip)
				// let's create a clip and play it.
				// It's done this way for consistency across various implementations
				var c:Clip;
				
				if(SephPlayerUtils.getFileExtension(String(file)).toLowerCase() == "xml")
				{
					// file is an external XML playlist
					if(_guiMngr)
						_guiMngr.notice(SephPlayer.LANG.REQUESTING_XML_PLAYLIST);
					Traceable.doTrace("Requesting an XML playlist...");
					// TODO: process external XML playlist
					// We might have to return null or a notice
					// so that the player knows this is an XML playlist scenario
					// then waits for the XML to load
					// on whose completion will build the playlist and play the first
					return "XML_PLAYLIST";
					
				}
				else if(SephPlayerUtils.getFileExtension(String(file)).toLowerCase() == "smil")
				{
					if(_guiMngr)
						_guiMngr.notice(SephPlayer.LANG.REQUESTING_SMIL_PLAYLIST);
					Traceable.doTrace("Requesting a SMIL playlist...");
					return "SMIL_PLAYLIST";
				}
				else if((file.indexOf("{") == 0) || (file.indexOf("[") == 0))
				{				
					// file is a JavaScript or JSON Object
					if(_guiMngr)
						_guiMngr.notice(SephPlayer.LANG.REQUESTING_JASON_OBJECT);
					Traceable.doTrace("Requesting a JSON Object as a string...");
					
					// this is old-school, boy ;)
					//var fileObj:* = SephPlayerUtils.convertStringObject(file,"Object");
					// THIS. IS. THE POWER!
					var res:*;
					//try {
					res = SephPlayerUtils.decodeJSONstring(file, false);
					//ExternalInterface.call("window.alert(" + String(res) + ")");
					//} catch(e:Error) {
					//Traceable.doTrace(e);
					//}
					
					if(res is Array)
					{					
						var resPlaylist:Array = [];
						for each(var obj:Object in res)
						{
							var aClip:Clip = new Clip();
							aClip.initializeFromObject(obj);
							resPlaylist.push(aClip);
						}
						
						return resPlaylist;
						
					}
					else if(res is Object)
					{					
						c = new Clip();
						c.initializeFromObject(res);
						return c;					
					}				
				}
				/* turns out you dont need it since the string gets automatically decoded as it gets passed to the flashvars
				else if((file.toUpperCase().indexOf("%7B") == 0) || (file.toUpperCase().indexOf("%5B") == 0))
				{
					Traceable.doTrace("Requesting a JSON Object as a decoded string...", "info");
					var req:Object = SephPlayerUtils.decodeJSONstring(file, false);
					if(req is Array)
					{
						var ret:Array = [];
						for each(var jsonObj:Object in req)
						{
							var jsonClip:Clip = new Clip();
							jsonClip.initializeFromObject(jsonObj);
							ret.push(jsonClip);
						}
						return ret;
					}
					else
					{
						c = new Clip();
						c.initializeFromObject(req);
						return c;
					}
				}
				*/
				else
				{				
					// if file is just an ordinary String
					if(_guiMngr) _guiMngr.notice(SephPlayer.LANG.REQUESTING_STRING);
					Traceable.doTrace("Requesting a URL...");
					
					_confMngr.file = file;
					this._currentPlaying = this._confMngr.file;
					
					// and since the supplied "file" is only a String, it will not
					// include the "streamer" or "streamerArg" with it
					// so let's get that from the corresponding flashvars
					var aFullStreamer:String = SephPlayerUtils.getStreamerFromStreamerAndStreamerArg(this._confMngr.streamer, this._confMngr.streamerArg);
					
					c = new Clip(_confMngr.file,
						aFullStreamer,
						this._confMngr,
						null,
						null,
						0,
						this._confMngr.file,
						SephPlayerUtils.attachPrefix(_confMngr.file), 
						SephPlayerUtils.getQualifiedURLFromFileAndStreamer(_confMngr.file, null, null),
						null
					);
					return c;				
				}
			}
			catch(e:Error)
			{
				//Utilities.windowAlert("Error parsing: " + file);
				Traceable.doTrace(this + ": Error while parsing file flashvars:\n" + file + "\n","error");
			}
			return null;			
		}
		
		private function onSmilLoadCompleteHandler(event:Event):void
		{
			Traceable.doTrace("SMIL data loaded.","info");
			event.target.removeEventListener(Event.COMPLETE, onSmilLoadCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, onSmilLoadErrorHandler);
			var smilDat:Array = SmilParser.toArray(new XML(event.target.data));
			if(smilDat && smilDat[0])
			{
				smilDat.reverse();
				this._confMngr.streams = smilDat;
				this._guiMngr.receiveGUIEvent(SephPlayerEvent.BITRATE_OPTIONS_SET, smilDat);
				
				// set to zero if wanting to play the lowest quality first
				// set to smilDat.length - 1 to play the highest quality first
				var indexToPlay:int = 0;
				
				// Use this if you would want to choose the stream to play
				// judging from the extract-eps attribute in the smil file
				// SINCE version 2.9.1 we disable this feature and periodical BWCheck
				// we want to always start with LOW quality
				// and leave users the choice to interactively switch to HIGH as they wish
				/*
				for each(var itm:Object in smilDat)
				{
					//---------------------------------------------------------
					// we need to determine which stream index to play first
					// since SephPlayer is fine-tuned for use on vivo.vn
					// it will use the "extract-eps" attribute's value
					// found inside the smil file video blocks to do this
					//---------------------------------------------------------
					if(String(itm["extractEps"]) == "true")
					{
						indexToPlay = smilDat.indexOf(itm);
						_guiMngr.receiveGUIEvent(SephPlayerEvent.BITRATE_GUI_CHANGE_REQUEST, indexToPlay + 1);
					}
				}
				*/
				
				/*
				// Use this if you would want to choose the stream to play
				// judging from the detected user bandwidth
				if(!isNaN(this._usrDetailsMngr.bandwidth) && this._usrDetailsMngr.bandwidth != 0)
				{					
					if(this._usrDetailsMngr.bandwidth < SephPlayerGlobal.BITRATE_THRESHOLD_SIMPLE) // low bitrate
					{
						//_guiMngr.receiveGUIEvent(SephPlayerEvent.BITRATE_GUI_CHANGE_REQUEST, 1);
						indexToPlay = 0;
					}
					else // high bitrate
					{
						//_guiMngr.receiveGUIEvent(SephPlayerEvent.BITRATE_GUI_CHANGE_REQUEST, smilDat.length);
						indexToPlay = smilDat.length - 1;
					}					
				}
				*/
				
				var c:Clip = new Clip(smilDat[indexToPlay]["name"],
					SephPlayerUtils.getStreamerFromStreamerAndStreamerArg(this._confMngr.streamer, this._confMngr.streamerArg),
					this._confMngr,
					null,
					null,
					0,
					this._currentPlaying,
					SephPlayerUtils.attachPrefix(this._confMngr.file),
					SephPlayerUtils.getQualifiedURLFromFileAndStreamer(this._confMngr.file, this._confMngr.streamer),
					this._confMngr.plugins,
					this._confMngr.start,
					true,
					smilDat);
				
				// !this is deadly important, without it the player will play a file without
				// actually registering its properties in the currentClip
				if(this._playlistMngr.length == 0)
					this._playlistMngr.initializeFromArray([c]);
				else
					this._playlistMngr.clips[_playlistMngr.currentPlayingIndex] = c; // since this is a SMIL scenario, we replace whatever clip currently in the currentPlayingIndex slot with the new clip with its "file" property actually pointing to a playable media file
				
				// now let's play the file
				this.playFile(_playlistMngr.getCurrentClip());
			}
		}
		
		private function onSmilLoadErrorHandler(event:IOErrorEvent):void
		{
			event.target.removeEventListener(Event.COMPLETE, onSmilLoadCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, onSmilLoadErrorHandler);
			Traceable.doTrace(this + ": Failed to load SMIL Playlist.");
		}
		
		private function onXMLLoadCompleteHandler(event:Event):void
		{
			event.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, onXMLLoadErrorHandler);
			event.currentTarget.removeEventListener(Event.COMPLETE, onXMLLoadCompleteHandler);
			var data:XML = new XML(event.currentTarget.data);
			data.ignoreWhitespace = true;
			this._confMngr.parseXML(data);
			// play the first item in the playlist
			Utilities.windowAlert("Sorry, but XML Parsing isn't fully supported.");
		}
		
		private function onXMLLoadErrorHandler(event:IOErrorEvent):void
		{
			event.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, onXMLLoadErrorHandler);
			event.currentTarget.removeEventListener(Event.COMPLETE, onXMLLoadCompleteHandler);
			Traceable.doTrace(this + ": Failed to load XML Playlist.");
		}
		
		/**
		 * Pass in a String, a JavaScript object, or an AS3 native Clip item
		 * and this function will set everything up for you.
		 * It will also build the playlist for SephPlayer, where required.
		 * 
		 * This function does NOT call "playFile", but if you explicitly call "playFile", it will call this function before actually playing the file.
		 * For convenience, this function returns the first Clip item to be played after it has processed the 'source',
		 * or 'false' if the player should not do anything (for example waiting for XML or SMIL to load).
		 * 
		 * @param buildPlayList: (default true) If false, the function simply returns the Clip item
		 * or an array of Clip items that should be played, but WITHOUT building the playlist.
		 * This is first used for processing "inStream" Clips, which we don't want to put in our playlist
		 *  
		 */
		public function setSource(file:*, buildPlayList:Boolean=true):*
		{
			if(!file)
			{
				Traceable.doTrace(this + ": \"setSource\" was called without any parameter!");
				return false;
			}
			
			// parse at least the "file" and "streamer" (including "streamerArg")
			// properties of the player config
			// if the "file" requested is of playlist type (xml or Javascript Array)
			// then build the appropriate playlist
			
			// the value of SephPlayerUtils.getStreamerNameAndArg()
			// will be passed into this variable for use at many locations below
			var streamerObj:Object;
			
			// in each of the cases where a player can play a file instantly
			// (the file variable does NOT point to a playlist or something other
			// than a playable movie clip)
			// let's create a clip and play it.
			// It's done this way for consistency across various implementations
			var c:Clip;
			
			if(file is String)
			{					
				var res:* = this.breakdownFileFlashvar(file);
				if(res)
				{
					if(res is Clip)
					{
						// file is a single String
						// or a JSON Object that points to a specific clip
						// with at least the "file" property
						if(buildPlayList)
						{
							this._playlistMngr.initializeFromArray([res]);
							return this._playlistMngr.getClipAt(0);
							// this used to be
							//return this.playFile(this._playlistMngr.getClipAt(0));
						}
						else
						{
							return res;
						}
					}
					else if(res is Array)
					{
						// file is a JSON Array
						if(buildPlayList)
						{
							this._playlistMngr.initializeFromArray(res as Array);
							return this._playlistMngr.getClipAt(0);
							// this used to be
							//return this.playFile(this._playlistMngr.getClipAt(0));
						}
						else
						{
							return res;
						}
					}
					else if(res == "XML_PLAYLIST" && buildPlayList)
					{
						// file is an XML playlist
						// manage XML playlist implementation
						// MAKE SURE the playlist is built
						// and the first item is played
						var xmlLdr:URLLoader = new URLLoader(new URLRequest(file));
						xmlLdr.addEventListener(Event.COMPLETE, onXMLLoadCompleteHandler, false, 0, true);
						xmlLdr.addEventListener(IOErrorEvent.IO_ERROR, onXMLLoadErrorHandler, false, 0, true);
						return false;
					}
					else if(res == "SMIL_PLAYLIST" && buildPlayList)
					{
						// file is a .smil playlist
						var smilLdr:URLLoader = new URLLoader(new URLRequest(file));
						smilLdr.addEventListener(Event.COMPLETE, onSmilLoadCompleteHandler, false, 0, true);
						smilLdr.addEventListener(IOErrorEvent.IO_ERROR, onSmilLoadErrorHandler, false, 0, true);
						// now we return false; the "onSmilLoadCompleteHandler" function will
						// parse the smil data and call "playFile" again
						return false;
					}
				}
				else
				{
					c = new Clip(file,
						_confMngr.streamer,
						_confMngr,
						null,
						null,
						0,
						file,
						SephPlayerUtils.attachPrefix(file),
						SephPlayerUtils.getQualifiedURLFromFileAndStreamer(file, _confMngr.streamer, _confMngr.streamerArg),
						null,
						0,
						false
					);
					if(buildPlayList)
					{
						this._playlistMngr.initializeFromArray([c]);
						return this._playlistMngr.getClipAt(0);
						// this used to be
						//return this.playFile(this._playlistMngr.getClipAt(0));
					}
					else
					{
						return c;
					}
				}
			}
			else if(file is Array)
			{					
				// file is a playlist from Javascript Array
				_guiMngr.notice(SephPlayer.LANG.REQUESTING_ARRAY);
				Traceable.doTrace("Requesting an Array...");
				
				var clipArray:Array = [];
				for each(var obj:Object in file)
				{
					var aClip:Clip = new Clip();
					aClip.initializeFromObject(obj);
					clipArray.push(aClip);
				}
				
				if(buildPlayList)
				{
					this._playlistMngr.initializeFromArray(clipArray);
					return this._playlistMngr.getClipAt(0);
					// this used to be...
					// we'll play the first item in the list now
					//return this.playFile(this._playlistMngr.getClipAt(0));
				}
				else
				{
					return clipArray;
				}
			}
			else if(file is Clip)
			{
				// though it sounds funny, sometimes people (like you) would pass a native Clip item
				// to this setSource function. In these cases it should just return the clip item!
				_guiMngr.notice(SephPlayer.LANG.REQUESTING_CLIP);
				Traceable.doTrace("Requesting a single native clip item");
				
				if(buildPlayList)
				{
					this._playlistMngr.initializeFromArray([file]);
					return this._playlistMngr.getClipAt(0);
				}
				else
				{
					return file;
				}
			}
			else
			{
				// this is the case when a JavaScript Object is passed directly into the playFile() function
				
				_guiMngr.notice(SephPlayer.LANG.REQUESTING_JAVASCRIPT_OBJECT);
				Traceable.doTrace("Requesting a single Object...");
				
				c = new Clip();
				
				// NOTICE: we currently do NOT allow this feature
				// if "streamerArg" is not specified in the file parameter
				// use the default in the _confMngr
				/*if(!file["streamerArg"]) {
				file["streamerArg"] = this._confMngr.streamerArg;
				}*/
				c.initializeFromObject(file);
				
				if(buildPlayList)
				{
					// do this to overwrite any playlist that has been initialized
					// before this (even by a mistakenly placed "file" value when playFile()
					// is called explicitly)
					this._playlistMngr.initializeFromArray([c]);
					return this._playlistMngr.getClipAt(0);
					// this used to be
					//return this.playFile(c);
				}
				else
				{
					return c;
				}
			}
			return false;
		}
		
		/**
		 * Plays a file right from beginning. Mostly used when the user requests a new item to be played
		 * Can be used externally to request playing a new file
		 * Will definitely create a new playModel upon invoked 
		 * @param file anything you want to play: a String, a JavaScript object, a SMIL / XML file, etc.
		 * @return true if the file playback was successful
		 * 
		 */		
		public function playFile(file:* = null):Boolean
		{
			// if the user doesn't specify a "file" parameter,
			// play the current item in the playlist
			// else, play whatever is stored in the player config
			if(!file)
			{
				if(this._playlistMngr.length > 0)
				{
					return this.playFile(this._playlistMngr.getCurrentClip());
				}
				else
				{
					// respect the original flashvars passed into the player
					if(SephPlayerUtils.getFileExtension(this._confMngr.file) == "xml")
					{
						// most often this is the result of breaking down "flashvars"
						// and if it contains an XML Playlist URL, here's where it gets processed
						file = this._confMngr.file;
					}
					else if(SephPlayerUtils.getFileExtension(this._confMngr.file) == "smil")
					{
						// most often this is the result of breaking down "flashvars"
						// and if it contains a SMIL Playlist URL, here's where it gets processed
						file = this._confMngr.file;
					}
					else
					{
						file = new Clip(this._confMngr.file,
							SephPlayerUtils.getStreamerFromStreamerAndStreamerArg(this._confMngr.streamer, this._confMngr.streamerArg),
							this._confMngr,
							null,
							null,
							0,
							((this._currentPlaying)? this._currentPlaying : this._confMngr.file),
							SephPlayerUtils.attachPrefix(this._confMngr.file),
							SephPlayerUtils.getQualifiedURLFromFileAndStreamer(this._confMngr.file, this._confMngr.streamer, this._confMngr.streamerArg),
							null);
						return this.playFile(file);
					}
				}
			}
			
			// if file is not of type Clip, call setSource to process file, build playlist,
			// then call this function again to play the resulted Clip
			var c:Clip;
			var streamerObj:Object;
			if(file)
			{
				if(!(file is Clip))
				{
					// call setSource, parse flashvars, build playlist
					var res:* = this.setSource(file);
					if(res)
						return this.playFile(res);
				}
				else
				{
					// pass the to-be-played Clip's information to _confMngr and prepare to playback
					_guiMngr.notice(SephPlayer.LANG.REQUESTING_CLIP);
					Traceable.doTrace("Requesting a Clip item...");
					
					c = file as Clip;
					
					// !IMPORTANT
					// pass the clip's "file" and "streamer" property into
					// the player config for playback
					if(c.file)
						_confMngr.file = c.file;
					else
						_confMngr.file = null;
					
					if(c.streamer && c.streamer != "" && c.streamer != "null")
					{
						streamerObj = SephPlayerUtils.getStreamerNameAndArg(c.streamer);
						_confMngr.streamer = streamerObj["streamer"];
						_confMngr.streamerArg = streamerObj["streamerArg"];
					}
					else
					{
						_confMngr.streamer = null;
					}
					
					// setup currentPlaying so the external knows what movie the player is currently playing
					// useful for subReader plugin for example.
					if(c.title)
					{
						this._currentPlaying = c.title;
					}
					else
					{
						// set the currentPlaying to the "file" config if there's no "movieTitle" specified
						c.title = _confMngr.file;
						this._currentPlaying = c.title;
					}
					
					// the second offset from which the clip is played back
					_confMngr.start = c.start;
					// apply the flashvars specified with this specifiec Clip
					applyFlashvarsFromClip(c);
					// load plugin(s) specific to the clip
					// note that you should do this before trying to load
					// the XML or SMIL playlist, since we should have
					// all plugins ready before such plugins as OVA
					if(c.plugins && c.plugins.length > 0)
						this._pluginMngr.loadPlugins(c.plugins);
					
					// in case the playFile() function is called explicitly
					// with a SMIL file as the file flashvar
					// or somehow OVA returns the playlist with a Clip item
					// having its "file" property set as a SMIL file
					// this will solve such problems and allow the proper
					// implementation of SMIL Playlist
					if(c.file && SephPlayerUtils.getFileExtension(c.file) == "smil")
					{
						Traceable.doTrace("Requesting a Clip item with file pointing to SMIL...");
						// passing the smil file into the "playFile" method
						// will cause the player to load the smil file, then play an item
						// included in it; however it won't save such information
						// as 'streamer', 'streamerArg', etc.
						// and that's why we should do it here before calling "playFile" again
						this._confMngr.streamer = SephPlayerUtils.getStreamerNameAndArg(c.streamer)["streamer"];
						this._confMngr.streamerArg = SephPlayerUtils.getStreamerNameAndArg(c.streamer)["streamerArg"];
						this._confMngr.plugins = c.plugins;
						this._confMngr.start = c.start;
						this._currentPlaying = c.title;
						// now that all the specific, important property from the Clip item
						// has been passed into the player's ConfigManager
						// let's call "playFile" again with the smil file as the parameter
						return this.playFile(c.file);
					}
					
					// announce the bitrates available to the stream going to be played
					// this will call the interface method "defineStreamOptions"
					// from the skin element "settingSlidePanel", if this exists
					// otherwise hide everything related
					if(c.streams && c.streams.length > 1)
					{						
						this._guiMngr.receiveGUIEvent(SephPlayerEvent.BITRATE_OPTIONS_SET, c.streams);
						
						this._guiMngr.allowsQualityPanel = true;
						
						this._guiMngr.allowsQualityBtn = true;
						this._guiMngr.addControlBarItem("qualityBtn");
						
					}
					else
					{						
						// we only disable the use of the qualityPanel
						// the settingsSlidePanel is still there on the controlBar
						this._guiMngr.allowsQualityPanel = false;
						
						// we want to set allowsQualityBtn to false
						// and to also remove the qualityBtn from the controlBar
						this._guiMngr.allowsQualityBtn = false;
						this._guiMngr.removeControlBarItem("qualityBtn");
					}
					
					// ensure a playlist is built so that plugins such as
					// OVA has information to use
					if(this._playlistMngr.length == 0)
						this._playlistMngr.initializeFromArray([c]);
					
					//---------------------------------------------------------
					// !IMPORTANT: WE MUST NOT PUT return this.playFile(c) HERE
					// BECAUSE THIS IS THE CIRCUMSTANCE WHERE
					// THE PLAYER ALREADY GETS ALL INFORMATION FROM A TO-BE-PLAYED CLIP
					// SO THAT IT CAN BEGIN PLAYBACK.
					// CALLING return this.playFile(c) NOW
					// WILL GENERATE AN INFINITE LOOP
					// AND YOU'RE GONNA KICK YOURSELF MADLY!
					//---------------------------------------------------------
					
					Traceable.doTrace("Clip file: " + c.file + 
						"; clip streamer: " + String(c.streamer) + 
						"; clip title: " + String(c.title) +
						"; clip mute: " + String(c.playerConfig["mute"]) +
						"; clip scaleMode: " + c.playerConfig["scaleMode"] + 
						"; clip no. of plugins: " + ((c.plugins)? String(c.plugins.length) : "0"), "info");
					
					// NOTICE: the below TODO task is relatively old and now I basically don't even remember what it means...
					// So I'll just leave it here for any possible future reference =_=
					// TODO: usually the clip will get automatically played at this point
					// but sometimes you don't want it to (i.e. autoStart is set to false in a certain clip)
					// and you cannot just check _confMngr.autoStart here because this function is shared by the function resulted
					// from the user clicking on the "play" button
					// so you gotta find another approach. Clue: how about separating the part below where PlayModel is actually instaniated?
				}
			}
			
			// This is quite important, if the user calls no "file",
			// and the player hasn't been told any "file" to play,
			// let's NOT proceed
			if(!_confMngr.file)
			{
				_guiMngr.notice(SephPlayer.LANG.INVALID_FILE + ": " + _confMngr.file);
				return false;
			}
			
			// !important: first let's get rid of the current playModel, whatever it is
			if(this._playModel)
				_playModel.dispose(); // we should also set _playModel = null, but that's included in the dispose() method, which call SephPlayer's clearPlayModel() method, which is enough.
			
			// if there is a streamer, we will use VideoPlayModel to handle ALL kinds of media
			if(_confMngr.streamer)
			{
				// TODO: check if the file format is supported before playing
				
				_playModel = new VideoPlayModel(this, _guiMngr);
				// VideoPlayModel will automatically connect itself after creation
				// but you will not be able to access it until the connection has been carried out
				//_playModel.doConnect(_confMngr.streamer, _confMngr.streamerArg);
				
			}
			else if(!_confMngr.streamer)
			{				
				// so there's no streamer, meaning the file is played progressively,
				// then let's see what kind of media is requested
				// if it's a video file, call an VideoPlayModel to handle things
				// and AudioPlayModel for audio stuff and so on.
				
				if(_confMngr.file.indexOf(".flv") == _confMngr.file.length - 4 ||
					_confMngr.file.indexOf(".f4v") == _confMngr.file.length - 4 ||
					_confMngr.file.indexOf(".mp4") == _confMngr.file.length - 4 ||
					_confMngr.file.indexOf("mp4:") == 0)
				{
					
					// TODO: manage switching streams
					_playModel = new VideoPlayModel(this, _guiMngr);
					
				}
				else if(_confMngr.file.indexOf(".mp3") == _confMngr.file.length - 4 ||
					_confMngr.file.indexOf(".f4a") == _confMngr.file.length - 4 ||
					_confMngr.file.indexOf(".m4a") == _confMngr.file.length - 4)
				{
					
					//TODO: process playing audio files
					//TODO code here
					
				}
				else
				{					
					// meaning the file extension is not supported
					_guiMngr.notice(SephPlayer.LANG.INVALID_FILE + ": " + _confMngr.file);
					// so that proper measures can be taken when a file cannot play
					// (either go to play the next one in the list or choose an alternative stream)
					this.evtMngr.dispatchEvent(new Event(SephPlayerEvent.STREAM_NOT_FOUND));
					return false;					
				}				
			}			
			// if nothing happens on the way, meaning the file can be played, return true
			return true;			
		}
		
		/**
		 * Play a Clip item but does not add this Clip item to the PlayListManager's list
		 * After this Clip item is completed, the PlayListManager's currentClip should be resumed
		 */
		public function playInStream(c:*):Boolean
		{
			if(this.playModel && this.playModel.isPlaying)
			{
				if(this.playInStreamMngr.hasNextInStreamClip())
				{
					Traceable.doTrace(this + ": playInStream called while playing another inStream Clip!", "error");
					return false;
				}
				
				c = this.setSource(c, false); // c can be false, a Clip object, or an Array of Clip objects
				if(!c)
				{
					Traceable.doTrace(this + ": Failed to process playInStream target.", "error");
					return false;
				}
				else
				{
					Traceable.doTrace(this + ": InStream session started.", "info");
					
					// enter inStream session; this will make sure EventManager's onFilePlayCompleteHandler
					// understands what measures to take once it's called
					this.isInInStreamSession = true;
					
					// save the current clip's metadata information (because it will be overwritten by the inStream clip's
					this._playInStreamMngr.saveInformationBeforeInStreamSession(this.metadata.clone());
					
					// put all inStream clips into an Array
					this._playInStreamMngr.registerInStreamClips(c);
					
					// record the time-point to resume the currentClip later
					try
					{
						this.playlistMngr.getCurrentClip().start = this.playModel.time;
						Traceable.doTrace(this + ": Current clip paused at " + this.playModel.time + " for inStream session.", "info");
					}
					catch(e:Error)
					{
						Traceable.doTrace(this + ": Failed to set time-point for currentClip. Cannot continue playInStream process!", "error");
						return false;
					}
					
					// actually play the inStream clip(s)
					var res:Boolean = this.playFile(this.playInStreamMngr.getCurrentInStreamClip());
					if(res)
					{
						return res;
					}
					else
					{
						Traceable.doTrace(this + ": Failed to play inStream clip. Continue with current clip.", "error");
						this.isInInStreamSession = false;
						this.playFile(this.playlistMngr.getCurrentClip());
						return false;
					}
				}
			}
			else
			{
				Traceable.doTrace(this + ": playInStream called while no Clip is being played!", "error");
				return false;
			}
		}
		
		public function playNext():Boolean
		{
			if(this._playlistMngr.length > 0)
			{
				if(this._playlistMngr.currentPlayingIndex < this._playlistMngr.length - 1)
					this._playlistMngr.currentPlayingIndex += 1;
				else
					this._playlistMngr.currentPlayingIndex = 0;
			}
			return this.playFile(this._playlistMngr.getClipAt(this._playlistMngr.currentPlayingIndex));
		}
		
		public function switchToStreamName(name:String):Boolean
		{
			if(this.playModel)
			{
				this.playModel.switchToStreamName(name);
				return true;
			}
			else
			{
				Traceable.doTrace(this + "Failed to invoke switchToStreamName: there's no playModel.","error");
			}
			return false;
		}
		
		public function switchToHigherBitrate():Boolean
		{
			var c:Clip = this._playlistMngr.getCurrentClip();
			if(c && c.streams)
			{
				var dynamicStreamIndex:uint = c.streams.indexOf(this._confMngr.file);
				if(dynamicStreamIndex == 0)
				{
					Traceable.doTrace(this + ": The highest bitrate available is currently selected.");
				}
				else
				{
					dynamicStreamIndex--;
					return this.switchToStreamName(c.streams[dynamicStreamIndex]);
				}
			}
			return false;
		}
		
		public function switchToLowerBitrate():Boolean
		{
			var c:Clip = this._playlistMngr.getCurrentClip();
			if(c && c.streams)
			{
				var dynamicStreamIndex:uint = c.streams.indexOf(this._confMngr.file);
				if(dynamicStreamIndex == c.streams.length - 1)
				{
					Traceable.doTrace(this + ": The lowest bitrate available is currently selected.");
				}
				else
				{
					dynamicStreamIndex++;
					return this.switchToStreamName(c.streams[dynamicStreamIndex]);
				}
			}
			return false;
		}
		
		/**
		 * Invoke when the playBtn is clicked
		 * @return true if the file can be played or is played, false if the file cannot be played or is paused
		 * 
		 */
		public function doPlayFile():Boolean
		{
			if(!this._playModel)
			{				
				// serving first time playBtn is clicked
				// playModel doesn't exist
				// here we call playFile() function to register the file and streamer
				return this.playFile();
				
			}
			else
			{				
				if(!this._playModel.isPlaying)
				{					
					// playModel exists, file and streamer unchanged
					// serving file replay OR playNext
					if((this._confMngr.repeat == "playlist" || this._confMngr.repeat == "none") &&
						this._playlistMngr.length > 0)
					{
						// play next item in the list
						return this.playNext();
					}
					else
					{
						// play the same item again
						this._guiMngr.notice(SephPlayer.LANG.REPLAY_NOTICE);
						this._evtMngr.dispatchEvent(new Event(SephPlayerEvent.REPLAY));
						this._playModel.play();
					}
					return true;					
				}
				else
				{					
					// serving play / pause of the same file (playModel exists)
					this._playModel.togglePause();
					if(this._playModel.timer && this._playModel.timer.running)
					{
						this._guiMngr.notice(SephPlayer.LANG.UNPAUSE); // resume
						this._evtMngr.dispatchEvent(new Event(SephPlayerEvent.RESUME));
						return true;
					}
					else
					{
						this._guiMngr.notice(SephPlayer.LANG.PAUSED);
						this._evtMngr.dispatchEvent(new Event(SephPlayerEvent.PAUSE));
						return false;
					}					
				}
			}			
			return false;			
		}
		
		/**
		 * Invoked when the pauseBtn is clicked
		 * @return true if the process was succesful
		 * 
		 */
		public function doPauseFile():Boolean
		{
			if(this._playModel)
			{
				this._playModel.pause();
				return true;
			}
			else
			{
				Traceable.doTrace(this + ": There's no playModel!","error");
			}
			return false;
		}
		
		/**
		 * ONLY invoked when the "STOP" event is dispatched from an external environment
		 * This function DOES NOT dispatch "onFilePlayFinalComplete" event
		 * nor does it let any external environment know so 
		 * @return true if the process was succesful 
		 * 
		 */
		public function doStopFile():Boolean
		{
			if(this._playModel)
			{				
				this._playModel.pause(); // it's here for proper GUI handling
				this._playModel.stop(); // it's here purely for sentimental matter
				
				// !important: dispose the playModel so that the next file
				// can be play properly with a new streamer
				return this._playModel.dispose();
				
			}
			else
			{
				Traceable.doTrace(this + ": There's no playModel!","error");
			}			
			return false;			
		}
		
		private function onStageResizedHandler(event:Event = null):void
		{			
			this._width = stage.stageWidth;
			this._height = stage.stageHeight;
		}
		
		private function onRemovedFromStageHandler(event:Event):void
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStageHandler);
			this.unload();
		}
		
		private function onStageKeyUpHandler(event:KeyboardEvent):void
		{			
			//trace(Keyboard.S);
			/*
			switch(event.keyCode)
			{
				case Keyboard.NUMBER_1 :
				{
					if(event.ctrlKey && event.altKey)
					{
						// Alt + H
						//trace("Prepare to swicth");
						//trace(this.playModel.getStreamInfo());
						this.switchToStreamName("you_are_beautiful/hbf1_1.flv");
					}
					break;
				}
			
				case Keyboard.NUMBER_2 :
				{
					if(event.ctrlKey && event.altKey)
					{
						// Alt + N
						this.switchToStreamName("you_are_beautiful/hbf1_1-800.flv");
					}
					break;
				}
			}
			*/
		}
		
		/**
		 * This is mostly used from an external environment
		 * to get the configuration settings of the player
		 * @param type the name of the configuration to get
		 * @return the value of the configuration
		 * 
		 */
		public function getConfig(type:String = null):String
		{
			var res:String;
			if(!type)
			{
				res = "SephPlayer all config: \n";
				for each(var key:String in _confMngr.configList)
				{
					res += "\t" + key + ": " + ((_confMngr[key])? _confMngr[key].toString() : "null") + " \n";
				}
			}
			else
			{
				res = (_confMngr[type])? _confMngr[type].toString() : "null";
			}
			return res;
		}
		
		/**
		 * This is mostly used by other Classes who wish to access the player config
		 * @param none
		 * @return the ConfigManager instance of SephPlayer
		 * 
		 */
		public function get config():ConfigManager
		{
			return this._confMngr;
		}
		
		public function get metadata():MetadataManager
		{
			return this._metaMngr;
		}
		
		public function replaceMetadata(val:MetadataManager):void
		{
			this._metaMngr = val
		}
		
		public function get display():*
		{
			var res:* = null;
			if(_playModel)
				res = _playModel.display;
			else
				trace(this + ": No playModel was found!","warn");
			
			return res;
		}
		
		public final function get playModel():AbstractPlayModel
		{
			return this._playModel;
		}
		
		public final function clearPlayModel():void
		{
			// sometimes I think we should put playModel.dispose here, but that would currently cause
			// an overflowException. You might want to make some adjustment here, some day...
			if(this._playModel)
				this._playModel = null;
		}
		
		public function get guiMngr():GUIManager
		{
			return this._guiMngr;
		}
		
		public function get evtMngr():EventManager
		{
			return this._evtMngr;
		}
		
		public function get pluginMngr():PluginManager
		{
			return this._pluginMngr;
		}
		
		public function get playlistMngr():PlaylistManager
		{
			return this._playlistMngr;
		}
		
		public function get usrDetailsMngr():UserDetailsManager
		{
			return this._usrDetailsMngr;
		}
		
		public function get playInStreamMngr():PlayInStreamManager
		{
			return this._playInStreamMngr;
		}
		
		/**
		 * Should mostly be called when the player itself is removed from the web page 
		 * 
		 */
		private function unload():void
		{
			this.evtMngr.sendEvent(SephPlayerEvent.STOP);
			this.clearPlayModel();
			this._confMngr = null;
			this._guiMngr = null;
			this._metaMngr = null;
			this._evtMngr = null;
			this._pluginMngr = null;
			this._playInStreamMngr.clearInStreamClips();
			this._playInStreamMngr = null;
			try
			{
				Utilities.clear(this);
			}
			catch(e:Error)
			{
				//
			}
		}		
	}	
}