package
{
	import seph.media.sephPlayer.SephPlayer;
	import seph.media.sephPlayer.events.SephPlayerEvent;
	import flash.events.Event;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	
	public class SephPlayerHost extends SephPlayer
	{
		public function SephPlayerHost()
		{
			super("./SephPlayerDefaultSkin.swf");
			this.evtMngr.addEventListener(SephPlayerEvent.READY, onPlayerReadyHandler, false, 0, true);
		}
		
		private function onPlayerReadyHandler(event:Event):void
		{
			this.evtMngr.removeEventListener(SephPlayerEvent.READY, this.onPlayerReadyHandler);
			this.playFile("sample2.f4v");
		}
	}
	
}
