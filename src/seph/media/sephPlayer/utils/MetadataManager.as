package seph.media.sephPlayer.utils
{
	public dynamic class MetadataManager
	{
		public var width:Number;
		public var height:Number;
		public var duration:Number;
		
		public function get DAR():Number
		{
			var res:Number;
			if(!isNaN(this.width) && !isNaN(this.height))
			{
				res = this.width / this.height;
			}
			return res;
		}
		
		public function clone():MetadataManager
		{
			var res:MetadataManager = new MetadataManager();
			res.width = this.width;
			res.height = this.height;
			res.duration = this.duration;
			return res;
		}

	}
	
}
