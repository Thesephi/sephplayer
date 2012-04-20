package seph.media.sephPlayer {
	
	public class SephPlayerGlobal {
		
		public static var EXTERNAL_SEND_EVENT_FUNC_NAME:String = "sendEvent";
		public static var EXTERNAL_PLAYFILE_FUNC_NAME:String = "playFile";
		public static var EXTERNAL_SET_SOURCE_FUNC_NAME:String = "setSource";
		public static var EXTERNAL_LOAD_PLUGIN_FUNC_NAME:String = "loadPlugin";
		public static var EXTERNAL_ON_LOAD_COMPLETE_FUNC_NAME:String = "onSephPlayerLoaded";
		public static var EXTERNAL_FILE_PLAY_COMPLETE_FUNC_NAME:String = "onSephPlayerPlayCompleteHandler";
		public static var EXTERNAL_FILE_PLAY_START_FUNC_NAME:String = "onSephPlayerPlayStartHandler";
		public static var EXTERNAL_PLAYLIST_PLAY_COMPLETE_FUNC_NAME:String = "onSephPlayerPlaylistPlayCompleteHandler";
		public static var EXTERNAL_SWITCH_TO_STREAM_NAME_FUNC_NAME:String = "switchToStreamName";
		
		public static var SERVER_TYPE:String = "wowza";
		
		public static var BITRATE_THRESHOLD_SIMPLE:Number = 1500; // a simple threshold value to distinguish between 'high' and 'low' bitrates
		
		public static var DECLARE_JS_FUNC_RECORD_LAST_ERROR:String = "function declareFunctionReportLastError() {window.recordLastError = function(val){window.lastError = val; try{onSephPlayerError(val)} catch(error) {} } }";

	}
	
}
