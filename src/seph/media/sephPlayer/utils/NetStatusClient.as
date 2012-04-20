package seph.media.sephPlayer.utils {
	
	import flash.events.Event;
	
	import seph.media.sephPlayer.SephPlayer;
	import seph.media.sephPlayer.events.SephPlayerEvent;
	import seph.events.ItemEvent;
	
	public class NetStatusClient {
		
		private var _player:SephPlayer;
		
		public function NetStatusClient(player:SephPlayer) {
			this._player = player;
		}

		public function onMetaData(mData:*):void {
			trace("Metadata received: ");
			for (var prop:String in mData) {
				trace("\t" + prop + ": " + mData[prop]);
				_player.metadata[prop] = mData[prop];
				_player.playModel.dispatchEvent(new Event(SephPlayerEvent.METADATA_RECEIVED));
			}
			
			/*_meta_duration = Number(mData["duration"]);
			_meta_vidWidth = Number(mData["width"]);
			_meta_vidHeight = Number(mData["height"]);
			if(isNaN(_meta_vidWidth)) _meta_vidWidth = stage.stageWidth;
			if(isNaN(_meta_vidHeight)) _meta_vidHeight = stage.stageHeight;
			_meta_DAR = _meta_vidWidth / _meta_vidHeight;*/
		}
		
		public function onXMPData(xmpData:*):void {
			trace("XMP data received");
			/*for (var prop in xmpData) {
				trace("\t" + prop + ": " + xmpData[prop]);
			}*/
		}
		
		public function onPlayStatus(obj:*):void {
			trace("PlayStatus dispatched: ");
			for (var prop:String in obj) {
				trace("\t" + prop + ": " + obj[prop]);
			}
			_player.playModel.dispatchEvent(new ItemEvent(SephPlayerEvent.PLAY_STATUS, obj));
		}
		
		public function onID3(obj:*):void {
			trace("ID3 info received");
			for (var prop:String in obj) {
				trace("\t" + prop + ": " + obj[prop]);
			}
		}
		
		public function dispose():void {
			this._player = null;
		}

	}
	
}
