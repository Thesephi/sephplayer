package seph.media.sephPlayer.utils
{	
	import com.adobe.serialization.json.JSON;
	
	import flash.external.ExternalInterface;
	
	import seph.Utilities;
	
	public class SephPlayerUtils
	{
		public static function convertFromSecToMin(value:Number):String
		{
			if(isNaN(value))
				return "??";
			var min:String = String(Math.floor(value/60));
			var sec:String = String(Math.floor(value%60));
			return SephPlayerUtils.addPreZero(min) + ":" + SephPlayerUtils.addPreZero(sec);
		}
		
		public static function addPreZero(target:String, resLength:uint = 2):String
		{
			var u:int = target.length;
			for(var i:uint = u; i < resLength; i++)
			{
				target = "0" + target;
			}
			return target;
		}
		
		/*
		This version of the function is deprecated. Use the one below
		public static function getFileExtenstion(target:String):String {
			var res:String = (target.length >= 5)? target.substr(target.length - 3) : "???";
			return res;
		}
		*/
		
		public static function getFileExtension(target:String):String
		{
			if(!target)
				return null;
			var lastDot:int = target.lastIndexOf(".");
			return target.substring(lastDot+1);
		}
		
		public static function getStreamerNameAndArg(raw:String):Object
		{
			var res:Object = {streamer:null, streamerArg:null};
			//if(raw.indexOf("rtmp://") != -1 && raw.indexOf("http://") != -1) {
				var streamerArr:Array = raw.split("#");
				if(streamerArr.length == 2)
				{
					res["streamer"] = streamerArr[0];
					res["streamerArg"] = streamerArr[1];
				}
				else if(streamerArr.length == 1)
				{
					res["streamer"] = streamerArr[0];
					res["streamerArg"] = null;
				}
			//}
			return res;
		}
		
		public static function decodeJSONstring(raw:String, strict:Boolean = true):* 
		{
			return com.adobe.serialization.json.JSON.decode(raw, strict);
		}
		
		public static function convertStringObject(target:String, targetFormat:String):*
		{
			var res:*;
			switch(targetFormat)
			{
				case "Array" :
				case "array" :
				{
					target = target.replace("[","");
					target = target.replace("]","");
					target = target.replace(" ","");
					target = target.replace("\"","");
					target = target.replace("'","");
					res = target.split(",");
					break;
				}
				case "Object" :
				case "object" :
				case "obj" :
				case "Obj" :
				{
					target = target.replace("{","");
					target = target.replace("}","");
					while(target.indexOf(" ") != -1)
					{
						target = target.replace(" ","");
					}
					while(target.indexOf("\"") != -1)
					{
						target = target.replace("\"","");
					}
					while(target.indexOf("'") != -1)
					{
						target = target.replace("'","");
					}
					// target has the form "name:value,name:value,name:value"
					var pairArr:Array = target.split(",");
					// pairArr has the form ["name:value","name:value","name:value"]
					res = new Object();
					for each(var item:String in pairArr)
					{
						var aPair:Array = item.split(":");
						// aPair has the form ["name","value"]
						if(aPair && aPair.length == 2)
							res[aPair[0]] = aPair[1];
					}
					break;
				}				
			}
			return res;
		}
		
		public static function attachPrefix(fileName:String):String
		{
			if(fileName == null || fileName == "null")
				return null;
			
			var res:String = fileName;
			// TODO: improve this more to be compatible with FMS as well as other RTMP streaming servers
			if(SephPlayerUtils.getFileExtension(fileName) == "mp4")
				res = "mp4:" + res;
			return res;
		}
		
		public static function getStreamerFromStreamerAndStreamerArg(streamer:String, streamerArg:String = null):String
		{
			var fullStreamer:String;
			if(streamer)
			{
				fullStreamer = streamer;
				if(streamerArg)
					fullStreamer += "#" + streamerArg;
			}
			return fullStreamer;
		}
		
		public static function getQualifiedURLFromFileAndStreamer(file:String, streamer:String = null, streamerArg:String = null):String
		{
			// the result has the form streamer#streamerArg/file
			if(!file)
				return null;
			var fullStreamer:String = SephPlayerUtils.getStreamerFromStreamerAndStreamerArg(streamer, streamerArg);
			return fullStreamer + "/" + file;
		}
		
		public static function windowAlert(content:String):void
		{
			try
			{
				ExternalInterface.call("window.alert('" + content + "')");
			}
			catch(e:Error)
			{
				//
			}
		}
		
		public static function isFlash10Point2():Boolean
		{
			var cap:Object = Utilities.getCapObj();
			var res:Boolean = false;
			if(Number(cap[2]) > 10)
			{
				res = true;
			}
			else if(Number(cap[2]) == 10)
			{
				if(Number(cap[3]) >= 2)
					res = true;
			}
			return res;
		}
		
		public static function isFlash10Point1():Boolean
		{
			var cap:Object = Utilities.getCapObj();
			var res:Boolean = false;
			if(Number(cap[2]) > 10)
			{
				res = true;
			}
			else if(Number(cap[2]) == 10)
			{
				if(Number(cap[3]) >= 1)
					res = true;
			}
			return res;
		}
	}	
}