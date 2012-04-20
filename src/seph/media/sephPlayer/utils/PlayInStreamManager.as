package seph.media.sephPlayer.utils
{
	import seph.media.sephPlayer.models.Clip;

	public class PlayInStreamManager
	{
		private var _inStreamClips:Array;
		
		/**
		 * This is used to save the current clip's metadata before the inStream clip is played
		 * (that will record the inStream clip's metadata into the MetadataManager)
		 * After the inStream session ends, put this saved information to the MetadataManager again
		 */
		private var _savedMetadata:MetadataManager;
		
		public function PlayInStreamManager()
		{
			this._inStreamClips = [];
		}
		
		/**
		 * @param target: an Clip object or an array of Clip objects
		 * 
		 */
		public function registerInStreamClips(target:Object):void
		{
			if(target is Clip)
				this._inStreamClips.push(target as Clip);
			else if(target is Array)
				this._inStreamClips = this._inStreamClips.concat(target as Array);
		}
		
		public function clearInStreamClips():void
		{
			this._inStreamClips = [];
		}
		
		public function hasNextInStreamClip():Boolean
		{
			return this._inStreamClips.length > 0;
		}
		
		public function getCurrentInStreamClip():Clip
		{
			if(this.hasNextInStreamClip())
				return this._inStreamClips[0];
			return null;
		}
		
		public function removeFinishedInStreamClip():void
		{
			if(this._inStreamClips.length > 0)
				this._inStreamClips.shift();
		}
		
		public function saveInformationBeforeInStreamSession(metadata:MetadataManager):void
		{
			this._savedMetadata = metadata;
		}
		
		/**
		 * @param target: 'metadata'
		 */
		public function getInformationBeforeInStreamSession(target:String):*
		{
			switch(target)
			{
				case "metadata" :
				{
					return this._savedMetadata;
					break;
				}
			}
			return null;
		}
	}
}