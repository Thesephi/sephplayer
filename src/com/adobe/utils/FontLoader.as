package com.adobe.utils {
	
	import flash.display.Loader;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	import flash.text.Font;

	public class FontLoader extends EventDispatcher {
		
		protected var _url:String;
		protected var _fontClassName:String;
		
		protected var loader:Loader;
		
		public function FontLoader(p_swfUrl:String = null, p_fontClassName:String = null) {
			super();
			
			if (p_swfUrl) { _url = p_swfUrl; }
			
			if (p_fontClassName) { _fontClassName = p_fontClassName; }
		}
		
		public function set url(p_url:String):void { _url = p_url; }
		public function get url():String { return _url; }
		
		public function set fontClassName(p_fontClassName:String):void { _fontClassName = p_fontClassName; }
		public function get fontClassName():String { return _fontClassName; }
		
		public function load():void {
			if (_url == null || _fontClassName == null) {
				throw new IllegalOperationError('Properties url and fontClassName must be set first.');
			}
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoad);
			loader.load(new URLRequest(_url));
		}
		
		protected function onLoad(p_event:Event):void {
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoad);
			Font.registerFont(loader.contentLoaderInfo.applicationDomain.getDefinition(_fontClassName) as Class);
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}