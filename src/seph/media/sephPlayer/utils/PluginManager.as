package seph.media.sephPlayer.utils
{	
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.system.System;
	
	import seph.URLGrabber;
	import seph.media.sephPlayer.SephPlayer;
	import seph.media.sephPlayer.models.Clip;
	import seph.media.sephPlayer.plugin.SephPlayerPlugin;
	import seph.utils.Traceable;
	
	public class PluginManager extends EventDispatcher
	{		
		private var _player:SephPlayer;
		private var _pluginList:Array;
		private var _ldr:Loader;
		private var _queue:Array; // an array of the plugins to be loaded ({name:"xxx", source:"xxx", config:{}});
		
		private var _isLoading:* = false;
		private var _configBuffer:Object;
		
		public function get isLoading():*
		{
			return this._isLoading;
		}

		public function PluginManager(player:SephPlayer)
		{
			this._player = player;
			this._pluginList = new Array();
			this._queue = new Array();
			_ldr = new Loader();
			_ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, onPluginLoadCompleteHandler, false, 0, true);
			_ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onPluginLoadErrorHandler, false, 0, true);
		}
		
		public function loadPlugins(plugins:*):void
		{
			for each(var plugin:* in plugins)
			{
				if(plugin["name"] && plugin["source"])
					this.loadPlugin(String(plugin["name"]),String(plugin["source"]),plugin["config"]);
				else
					Traceable.doTrace("Warning: 1 of the plugins does not have its \"name\" or \"source\" specified. Ignoring.","warn");
			}
		}
		
		public function loadPlugin(name:String, source:String, config:Object = null):void
		{
			if(Traceable.TRACE_LEVEL == Traceable.TRACE_LEVEL_ALL) _player.guiMngr.notice("Prepare to load plugin " + name);
			Traceable.doTrace("Prepare to load plugin " + name, "info");
			
			if(_isLoading != false)
			{
				if(Traceable.TRACE_LEVEL == Traceable.TRACE_LEVEL_ALL) _player.guiMngr.notice("Currently loading another plugin...");
				Traceable.doTrace("Currently loading another plugin...","info");
				
				// and so a plugin is being loaded, we need to queue up this one
				// and load it later
				_queue.push({name:name, source:source, config:config});
				
				// then do nothing else
				return;
			}
			
			// config has the format {name:"NAME", source:"SOURCE"}
			_isLoading = name;
			_configBuffer = config;
			
			// see if the plugin requested is in a different domain to the player, if true, require a policy file, else, dont require it to save some bandwidth
			var ctx:LoaderContext;
			if(URLGrabber.getDomainFromURLstring(String(source)) == String(URLGrabber.getSelfDomain()))
				ctx = new LoaderContext(true, ApplicationDomain.currentDomain, (Security.sandboxType == Security.REMOTE) ? SecurityDomain.currentDomain : null);
			else
				ctx = new LoaderContext(false, ApplicationDomain.currentDomain, (Security.sandboxType == Security.REMOTE) ? SecurityDomain.currentDomain : null);
			_ldr.load(new URLRequest(String(source)), ctx);
		}
		
		public function removePlugin(name:String = null):Boolean
		{
			if(name == null)
				return false;
			for each(var plugin:PluginInfo in this._pluginList)
			{
				if(plugin.name == name)
				{
					//trace("Prepare to remove plugin " + plugin.name + " " + plugin.content.VERSION);
					Traceable.doTrace("Prepare to remove plugin " + plugin.name + " " + plugin.content.VERSION, "info");
					// remove the plugin from the pluginList
					var removed:PluginInfo = this._pluginList.splice(_pluginList.indexOf(plugin),1)[0] as PluginInfo;
					if(removed)
					{
						// physically remove the plugin from the stage
						if(this._player.guiMngr.removePlugin(removed.content))
						{
							//trace("Successfully removed plugin " + removed.name + " " + removed.content.VERSION);
							Traceable.doTrace("Successfully removed plugin " + removed.name + " " + removed.content.VERSION, "info");
							removed = null;
							return true;
						}
					}
				}
			}
			//trace("There's no plugin registered with the name \"" + name + "\".");
			Traceable.doTrace("There's no plugin registered with the name \"" + name + "\".", "warn");
			return false;
		}
		
		private function onPluginLoadCompleteHandler(event:Event):void
		{			
			var pluginName:String = String(_isLoading);
			_isLoading = false;
			
			// first we need to check if a plugin with the same name has been added before
			var toRemove:String;
			for each(var plugin:PluginInfo in this._pluginList)
			{
				if(plugin.name == pluginName)
				{
					//trace("A plugin registered with the name \"" + pluginName + "\" has been loaded already. Will now try to remove it.");
					Traceable.doTrace("A plugin registered with the name \"" + pluginName + "\" has been loaded already. Will now try to remove it.", "info");
					toRemove = pluginName;
					break; // we don't need to continue the loop here since we make sure all plugins are ALWAYS ONE OF A KIND
				}
			}
			
			// if there's no conflicting plugin, or the conflicting plugin has been successfully removed
			if(toRemove == null || this.removePlugin(toRemove))
			{					
				if(toRemove)
					Traceable.doTrace("Plugin Removal Done.","info");
				
				// now let's add the newly loaded plugin.
				var pluginContent:SephPlayerPlugin = event.target.content as SephPlayerPlugin;
				if(pluginContent)
				{					
					// allow cross-scripting from plugin's domain
					// putting this in the "if" block here emphasizes that
					// we only allow cross-scripting when the pluginContent is of SephPlayerPlugin type
					// so that no malicious software can play havok on SephPlayer
					Security.allowDomain(event.target.url);
					
					// first we need to fully register the plugin's useful properties
					// such as the reference the to SephPlayer object
					// and the configurations we passed in the plugin at calling time
					pluginContent.player = this._player;
					pluginContent.config = this._configBuffer;
					var pluginInfo:PluginInfo = new PluginInfo(pluginName, pluginContent);
					this._pluginList.push(pluginInfo);
					// physically add the plugin to the display list.
					this._player.guiMngr.addPlugin(pluginInfo.content);
					
					if(Traceable.TRACE_LEVEL == Traceable.TRACE_LEVEL_ALL) this._player.guiMngr.notice("Plugin " + pluginName + " " + pluginContent.VERSION + " loaded.");
					Traceable.doTrace("Plugin " + pluginName + " " + pluginContent.VERSION + " loaded.", "info");
					this._configBuffer = null;
				}
				else
				{
					this._player.guiMngr.notice("Error: Plugin " + pluginName + " failed to load: It might not be an instance of SephPlayerPlugin");
					Traceable.doTrace("Error: Plugin " + pluginName + " failed to load: It might not be an instance of SephPlayerPlugin", "error");
				}
			}
			
			_ldr.unload();
			System.gc();
			
			dispatchEvent(event.clone());
			
			// if there's still unloaded plugin in the queue, now is the time to do so...
			this.loadNextPlugin();
		}
		
		private function onPluginLoadErrorHandler(event:IOErrorEvent):void
		{
			this._player.guiMngr.notice("Error: Plugin " + String(_isLoading) + " failed to load: Loading error");
			Traceable.doTrace("Error: Plugin " + String(_isLoading) + " failed to load: Loading error", "error");
			_isLoading = false;
			_configBuffer = null;
			//dispatchEvent(event.clone()); we can handle the error here in this class, no need to further dispatch the event
			
			// if there's still unloaded plugin in the queue, now is the time to do so...
			this.loadNextPlugin();
		}
		
		private function loadNextPlugin():void
		{
			if(this._queue.length > 0)
			{
				var toLoad:Object = this._queue.shift();
				this.loadPlugin(toLoad["name"], toLoad["source"], toLoad["config"]);
			}
		}
	}
}

import seph.media.sephPlayer.plugin.SephPlayerPlugin;
class PluginInfo
{	
	public var name:String;
	public var content:SephPlayerPlugin;

	public function PluginInfo(name:String, content:SephPlayerPlugin)
	{
		this.name = name;
		this.content = content;
	}
}