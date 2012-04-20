package seph.media.sephPlayer.events
{
	public class SephPlayerEvent
	{
		/*
		 * dispatched when player successfully inited (this includes loading GUI file and parsing all possible flashvars)
		 * this is the same moment that EXTERNAL_ON_LOAD_COMPLETE_FUNC_NAME is dispatched!
		 */
		public static const READY:String = "READY";
		
		public static const PLAY_STATUS:String = "PLAY_STATUS";
		public static const METADATA_RECEIVED:String = "METADATA_RECEIVED";
		public static const FILE_PLAY_COMPLETE:String = "FILE_PLAY_COMPLETED";
		public static const FILE_PLAY_START:String = "FILE_PLAY_START";
		public static const PLAY_TIME_UPDATED:String = "PLAY_TIME_UPDATED";
		
		public static const STREAM_NOT_FOUND:String = "NetStream.Play.StreamNotFound";
		public static const AD_NOT_FOUND:String = "AD_NOT_FOUND";
		public static const NETCONNECTION_CONNECT_REJECTED:String = "NetConnection.Connect.Rejected";
		public static const NETCONNECTION_CONNECT_FAILED:String = "NetConnection.Connect.Failed";
		
		public static const VIDEO_DECODING_CAPABILITY_STATUS:String = "VIDEO_DECODING_CAPABILITY_STATUS";
		public static const VIDEO_DECODING_UNAVAILABLE:String = "VIDEO_DECODING_UNAVAILABLE";
		public static const VIDEO_DECODING_SOFTWARE:String = "VIDEO_DECODING_SOFTWARE";
		public static const VIDEO_DECODING_HARDWARE:String = "VIDEO_DECODING_HARDWARE";
		
		public static const PLAY_BTN_CLICKED:String = "PLAY_BTN_CLICKED";
		public static const PAUSE_BTN_CLICKED:String = "PAUSE_BTN_CLICKED";
		
		public static const BANDWIDTH_DETECTED:String = "BANDWIDTH_DETECTED"; // dispatched when onBWDone has been called, carrying the information of the detected user bandwidth (event.id)
		
		public static const BITRATE_GUI_CHANGE_REQUEST:String = "BITRATE_GUI_CHANGE_REQUEST"; // sent when the GUI for quality settings (qualityBtn or qualityPanel) should be updated passively, just like an ordinary user interaction behavior
		public static const BITRATE_SWITCH_REQUEST:String = "BITRATE_SWITCH_REQUEST"; // sent when need to switch to another bitrate. i.e. when the qualitySlider inside the settingSlidePanel is used
		public static const BITRATE_OPTIONS_SET:String = "BITRATE_OPTIONS_SET"; // sent when need to display the stream options available to the stream being played via the skin element "settingSlidePanel"
		
		public static const STOP:String = "STOP";
		
		public static const SCALE_MODE_SWITCH_REQUESTED:String = "SCALE_MODE_SWITCH_REQUESTED";
		
		public static const PLAYLIST_UPDATED:String = "PLAYLIST_UPDATED";
		public static const PLAYLIST_PLAY_COMPLETE:String = "PLAYLIST_PLAY_COMPLETE";
		
		public static const CLICK_THROUGH:String = "CLICK_THROUGH";
		public static const GO_FULL_SCREEN:String = "GO_FULL_SCREEN";
		public static const GO_NORMAL_SCREEN:String = "GO_NORMAL_SCREEN";
		public static const MUTE:String = "MUTE";
		public static const UNMUTE:String = "UNMUTE";
		public static const PLAY:String = "PLAY";
		public static const PAUSE:String = "PAUSE";
		public static const REPLAY:String = "REPLAY";
		public static const SEEK:String = "SEEK";
		public static const RESUME:String = "RESUME";
		public static const MOUSE_OVER:String = "MOUSE_OVER";
		public static const MOUSE_OUT:String = "MOUSE_OUT";
		public static const PLAYER_STOP:String = "PLAYER_STOP"; // used for OVA plugin
		
		public static const RESIZE:String = "RESIZE";
		
		public static const PLAYLIST_INITIALIZED:String = "PLAYLIST_INITIALIZED";
		
		public static const SKIN_ASSET_LOAD_COMPLETE:String = "SKIN_ASSET_LOAD_COMPLETE";
		public static const SKIN_ASSET_LOAD_FAIL:String = "SKIN_ASSET_LOAD_FAIL";
		
		public static const CONTROLBAR_ON:String = "CONTROLBAR_ON";
		public static const CONTROLBAR_OFF:String = "CONTROLBAR_OFF";
		public static const CONTROLBAR_TOGGLED:String = "CONTROLBAR_TOGGLED";
		
		public static const CONNECTED_USERS_COUNT_RESULT:String = "CONNECTED_USERS_COUNT_RESULT";

	}
	
}
