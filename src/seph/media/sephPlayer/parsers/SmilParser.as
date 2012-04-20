package seph.media.sephPlayer.parsers {
	import seph.media.sephPlayer.utils.SephPlayerUtils;
	public class SmilParser {

		public static function toArray(xml:XML):Array {
			if(!xml || !xml is XML) return null;
			var res:Array = new Array();
			try {
				for each(var video:XML in xml["body"]["switch"]["video"]) {
					res.push({name:video["@src"], rate:Number(video["@system-bitrate"]), extractEps:String(video["@extract-eps"])});
				}
			} catch(e:Error) {
				trace("SmilParser: " + e);
				return null;
			}
			res.sortOn("rate"/*, Array.DESCENDING*/);
			return res;
		}

	}
	
}
