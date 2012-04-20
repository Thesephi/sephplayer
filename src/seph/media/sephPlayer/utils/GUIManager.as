package seph.media.sephPlayer.utils
{
	import caurina.transitions.Tweener;
	
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.text.*;
	import flash.ui.Mouse;
	import flash.utils.Timer;
	
	import seph.URLGrabber;
	import seph.Utilities;
	import seph.events.ItemEvent;
	import seph.media.sephPlayer.SephPlayer;
	import seph.media.sephPlayer.SephPlayerGlobal;
	import seph.media.sephPlayer.events.SephPlayerEvent;
	import seph.media.sephPlayer.models.AbstractPlayModel;
	import seph.media.sephPlayer.models.Clip;
	import seph.media.sephPlayer.models.VideoPlayModel;
	import seph.media.sephPlayer.utils.ClassResolver;
	import seph.utils.Traceable;
	
	public class GUIManager
	{		
		private var _player:SephPlayer;
		
		private var controlBar:DisplayObjectContainer;
		private var playBtn:DisplayObject;
		private var pauseBtn:DisplayObject;
		private var soundBtn:DisplayObject;
		private var noSoundBtn:DisplayObject;
		private var track:DisplayObject;
		private var fullScreenBtn:DisplayObject;
		private var normalScreenBtn:DisplayObject;
		private var settingsBtn:DisplayObject;
		private var switchScaleModeBtn:DisplayObject;
		private var leftTF:DisplayObject;
		private var rightTF:DisplayObject;
		private var bar:DisplayObject;
		private var qualityBtn:DisplayObject;
		private var settingSlidePanel:DisplayObjectContainer;
		private var loadAnim:DisplayObject;
		private var overlaySprite:Loader;
		
		private var _skinAssets:ApplicationDomain;
		
		/**
		 * flags that allow the use of QualityPanel 
		 * @param flag set to true if wanting to show and use the QualityPanel
		 * 
		 */		
		public function set allowsQualityPanel(flag:Boolean):void
		{
			// since settingSlidePanel might be an empty Sprite, we need to be aware of that scenario
			if(this.settingSlidePanel && DisplayObjectContainer(this.settingSlidePanel).numChildren != 0)
			{
				if(this.settingSlidePanel["qualityPanel"])
				{
					if(flag == false)
					{
						this.settingSlidePanel["qualityPanel"]["alpha"] = 0.3;
						this.settingSlidePanel["qualityPanel"]["mouseEnabled"] = false;
						this.settingSlidePanel["qualityPanel"]["mouseChildren"] = false;
					}
					else
					{
						this.settingSlidePanel["qualityPanel"]["alpha"] = 1;
						this.settingSlidePanel["qualityPanel"]["mouseEnabled"] = true;
						this.settingSlidePanel["qualityPanel"]["mouseChildren"] = true;
					}
				}
			}
			else
			{
				Traceable.doTrace(this + ": There's no \"qualityPanel\" or \"settingSlidePanel\", or neither of them.");
			}
		}
		
		public function set allowsQualityBtn(flag:Boolean):void
		{
			if(this.qualityBtn)
			{
				if(flag)
				{
					this.qualityBtn.alpha = 1;
					this.qualityBtn["mouseChildren"] = this.qualityBtn["mouseEnabled"] = true;
					//DisplayObjectContainer(this.controlBar).addChild(qualityBtn);
				}
				else
				{
					this.qualityBtn.alpha = 0.3;
					this.qualityBtn["mouseChildren"] = this.qualityBtn["mouseEnabled"] = false;
					//if(qualityBtn.parent) qualityBtn.parent.removeChild(qualityBtn);
				}
			}
		}
		
		public function set allowsCaptionLanguagePanel(flag:Boolean):void
		{
			// TODO: do this
		}
		
		public var allowsSettingPanel:Boolean = true;
		
		private var tracer:*;
		private var bg:Sprite;
		private var fg:Sprite;
		
		private var _isControlBarOn:Boolean;
		public function get isControlBarOn():Boolean
		{
			return this._isControlBarOn;
		}
		private var _controlBarY:Number;
		private var _normalscreen_config_controls:String = "always";
		
		private var _idledBuffer:uint = 0;
		private var _idledWatcher:Timer;
		
		/**
		 * mostly this is for the OVA plugin uses 
		 */
		public var fgEnabled:Boolean = true;
		
		/**
		 * This function can be used to determined if the controlBar presents or not
		 * for example, a subtitle displayer will adjust its text to match the controlBar position 
		 * @return the position of the control bar
		 * 
		 */		
		public function get controlBarY():Number
		{
			return this._controlBarY;
		}
		
		public function get controlBarHeight():Number
		{
			if(this.bar)
				return this.bar.height;
			return 0;
		}
		
		/**
		 * This functions receives a skin and player instance,
		 * adds the skin to the player display list, and take care
		 * of sizes and positions of the skin elements
		 * the skin follows a certain predefined framework
		 * Please view the Skin_Guide documentation for more details 
		 * @param playerInstance the reference to the SephPlayer instance
		 * @param skin the DisplayObject containing the buttons, track, etc.
		 * 
		 */		
		public function GUIManager(playerInstance:SephPlayer, skin:*)
		{			
			this._player = playerInstance;
			
			// register the applicationDomain of the skin instance
			// so that we can reference whatever classes defined in the skin later
			if(skin is DisplayObject)
			{
				// set the blendMode to "Layer" so when the player alpha is dimmed it doesn't create artifact in the skin's layers
				_player.blendMode = flash.display.BlendMode.LAYER;
				
				if(DisplayObject(skin).loaderInfo && DisplayObject(skin).loaderInfo.applicationDomain)
					this._skinAssets = DisplayObject(skin).loaderInfo.applicationDomain;
				else if(_player.loaderInfo)
					this._skinAssets = _player.loaderInfo.applicationDomain;					
			}
			
			bg = new Sprite();
			this._player.addChildAt(bg,0);
			
			var skinElements:Array = [
									  {name:"playBtn", defClass:Sprite},
									  {name:"pauseBtn", defClass:Sprite},
									  {name:"soundBtn", defClass:Sprite},
									  {name:"noSoundBtn", defClass:Sprite},
									  {name:"track", defClass:Sprite},
									  {name:"fullScreenBtn", defClass:Sprite},
									  {name:"normalScreenBtn", defClass:Sprite},
									  {name:"settingsBtn", defClass:Sprite},
									  {name:"switchScaleModeBtn", defClass:Sprite},
									  {name:"qualityBtn", defClass:Sprite},
									  {name:"leftTF", defClass:Sprite},
									  {name:"rightTF", defClass:Sprite},
									  {name:"bar", defClass:Sprite},
									  {name:"settingSlidePanel", defClass:Sprite}
									  ];
			
			fg = new Sprite();
			this._player.addChild(fg);
			fg.graphics.beginFill(0x000000,0);
			fg.graphics.drawRect(0, 0, _player.width, _player.height);
			fg.graphics.endFill();
			
			//the controlbar should be on top of the display list
			if(skin["controlBar"])
			{
				this.controlBar = skin["controlBar"];
				this._player.addChild(this.controlBar);
			}
			else
			{
				// do NOT change this into Traceable way
				trace(this + ": Not found skin controlBar.","warn");
			}
			
			for each(var itm:Object in skinElements)
			{
				if(this.controlBar[itm["name"]])
				{
					this[itm["name"]] = this.controlBar[itm["name"]];
					// do NOT change this into Traceable way
					trace(this + ": Found " + itm["name"] + " in skin controlBar.","info");
				}
				else
				{
					// do NOT change this into Traceable way
					trace(this + ": Not found " + itm["name"] + " in skin controlBar.","warn");
					//var ElementClass:Class = Class(itm["defClass"]);
					//this[itm["name"]] = new ElementClass();
				}
			}
			
			// the following settings are only effective if tracer is a TextField instance itself
			// TODO: provide a better handling system for tracer (which could also be a MovieClip , Sprite, etc.)
			tracer = skin["tracer"];
			if(tracer)
			{
				tracer.x = 8;
				tracer.y = 5;
				tracer.autoSize = TextFieldAutoSize.LEFT;
				tracer.background = true;
				tracer.backgroundColor = 0x000000;
				tracer.alpha = 0.8;
				_player.addChild(tracer);
			}
			else
			{
				// do NOT change this into Traceable way
				trace(this + ": There's no tracer found in the Skin.","warn");
			}
			
			// apply mose configurations passed into the player here
			this.applyConfig();
			
			// a few initial settings to the GUI
			this.controlBar["bar"].buttonMode = true;
			//this.fg.buttonMode = true;
			
			// this watches for user interaction over the player (MOUSE_MOVE event on stage)
			// and will 'do something' if the user hasn't done anything for a certain time
			_idledWatcher = new Timer(1000);
			_idledWatcher.addEventListener(TimerEvent.TIMER, onIdledTimerHandler, false, 0, true);
			_idledWatcher.start();
			
			// the fundamental lies here! lol
			this.setListeners();			
		}
		
		/**
		 * This function should be called whenever a flashvar to the player configuration is changed
		 * so that the new setting is properly reflected 
		 * @param clipToPlay: the Clip going to be played with this config applied. Only used in certain circumstances
		 */		
		public function applyConfig():void
		{
			this._normalscreen_config_controls = this._player.config.controls;
			this.background = _player.config.background;
			this.controlBar.visible = (this._player.config.controls == "none")? false : true;
			
			if(_player.config.overlay)
			{
				this.setOverlay(_player.config.overlay, _player.config.overlayPosition);
			}
			else
			{
				var selfURL:String = URLGrabber.getSelfURL();
				if(selfURL)
				{
					var path:String = selfURL.substring(0, selfURL.lastIndexOf("/"));
					this.setOverlay(path + "/overlay.png", _player.config.overlayPosition);
				}
			}
			
			pauseBtn.visible = _player.config.autoStart; // this means if flashvar autoStart = true then by default the pauseBtn will show up
			playBtn.visible = !pauseBtn.visible; // and the playBtn will be hidden
			noSoundBtn.visible = _player.config.mute;
			soundBtn.visible = !noSoundBtn.visible;
			normalScreenBtn.visible = false;
			
			if(_player.config.live)
			{
				fg.removeEventListener(MouseEvent.CLICK, this.onFgMouseClickedHandler);
				this.disableControlBar();
			}
			else
			{
				fg.addEventListener(MouseEvent.CLICK, this.onFgMouseClickedHandler, false, 0, true);
				this.enableControlBar();
			}
			
			this.receiveGUIEvent(SephPlayerEvent.SCALE_MODE_SWITCH_REQUESTED, _player.config.scaleMode);			
		}
		
		public function setSize(w:Number, h:Number):void
		{			
			// controlBar: positioned as flashar specification
			// for now let's just put it at the bottom
			controlBar.y = h - this.controlBarHeight;
			/*if(_player.playModel && _player.playModel.isPlaying) {
				toggleControls(false,0);
			}*/
			
			// track: resized to fit the width of the player
			track.width = w;
			
			var elementsExceptBar:Array = [];
			var previousElement:DisplayObject = new Sprite();
			
			//--------------------------------------------------------------
			// first we take care of the elements that come before the 'bar'
			//--------------------------------------------------------------
			
			// playBtn and pauseBtn: positioned at the right-most
			if(playBtn && controlBar.contains(playBtn))
			{
				playBtn.x = pauseBtn.x = 0;
				elementsExceptBar.push(playBtn);
				previousElement = playBtn;
			}
			
			// soundBtn and noSoundBtn: positioned next to playBtn / pauseBtn
			if(soundBtn && controlBar.contains(soundBtn))
			{
				soundBtn.x = noSoundBtn.x = previousElement.x + previousElement.width;
				elementsExceptBar.push(soundBtn);
				previousElement = soundBtn;
			}
			
			// leftTF: positioned next to soundBtn / noSoundBtn
			if(leftTF && controlBar.contains(leftTF))
			{
				leftTF.x = previousElement.x + previousElement.width;
				elementsExceptBar.push(leftTF);
				previousElement = leftTF;
			}
			
			//--------------------------------------------------------------
			// now we take care of the elements that come after the 'bar'
			//--------------------------------------------------------------
			
			// in case there's no "fullScreenBtn" available, make a temporary element
			// whose "x" property is equal to "w", so the subsequent elements to the "fullScreenBtn"
			// can get their positions relative to this
			var backupRightMostElement:Sprite = new Sprite;
			backupRightMostElement.x = w;
			previousElement = backupRightMostElement;
			
			// fullScreenBtn: placed at the rightmost of the player
			if(fullScreenBtn && controlBar.contains(fullScreenBtn))
			{
				fullScreenBtn.x = normalScreenBtn.x = w - fullScreenBtn.width;
				elementsExceptBar.push(fullScreenBtn);
				previousElement = fullScreenBtn;
			}
			
			// switchScaleModeBtn: placed at the left of the fullScreenBtn
			if(switchScaleModeBtn && controlBar.contains(switchScaleModeBtn))
			{
				switchScaleModeBtn.x = previousElement.x - switchScaleModeBtn.width;
				elementsExceptBar.push(switchScaleModeBtn);
				previousElement = switchScaleModeBtn;
			}
			
			// settingsBtn: if present, placed at the left of the switchScaleModeBtn
			if(this.allowsSettingPanel)
			{
				if(settingsBtn)
				{
					this.controlBar.addChild(settingsBtn);
					settingsBtn.visible = true;
					settingsBtn.x = previousElement.x - settingsBtn.width;
					elementsExceptBar.push(settingsBtn);
					previousElement = settingsBtn;
				}
			}
			else
			{
				if(settingsBtn)
				{
					settingsBtn.visible = false;
					if(settingsBtn.parent)
						settingsBtn.parent.removeChild(settingsBtn);
				}
			}
			
			// qualityBtn: if present, placed at the left of switchScaleModeBtn
			if(qualityBtn && controlBar.contains(qualityBtn))
			{
				qualityBtn.x = previousElement.x - qualityBtn.width;
				elementsExceptBar.push(qualityBtn);
				previousElement = qualityBtn;
			}
			
			// rightTF: placed at the left of whichever "previousElement" is set to
			if(rightTF && controlBar.contains(rightTF))
			{
				rightTF.x = previousElement.x - rightTF.width;
				elementsExceptBar.push(rightTF);
				previousElement = rightTF;
			}
			
			// bar: positioned left to rightTF and
			// resized to fit the space given to it,
			// which is the entire width of the player
			// minus the total width of everytying else
			var elementsWidthExceptBar:Number = 0;
			for each(var itm:DisplayObject in elementsExceptBar)
			{
				elementsWidthExceptBar += itm.width;
			}
			if(bar && controlBar.contains(bar))
			{
				bar["barTrack"].width = w - elementsWidthExceptBar;
				bar.x = previousElement.x - bar["barTrack"].width;
			}
			// bar: update the current status given by the playModel
			if(_player.playModel)
				this.updateBar(_player.playModel.getProgPerc(), _player.playModel.getLoadPerc());
			
			// bg: resized to fit the dimension of the player
			if(bg.width != 0 && bg.height != 0)
			{
				bg.width = w;
				bg.height = h;
			}
			
			// fg: orniarily this is a colored Sprite with zero alpha
			// so by default we change the size of this Sprite
			fg.graphics.clear();
			fg.graphics.beginFill(0x000000, 0);
			fg.graphics.drawRect(0, 0, w, h);
			fg.graphics.endFill();
			
			// tracer: if there is one, resized to fit the entire width of the player
			//tracer.width = w - 16;
			
			// if a loadAnim is being displayed, position it at the center of the stage
			if(loadAnim && loadAnim.parent)
			{
				loadAnim.x = loadAnim.parent.width/2;
				loadAnim.y = loadAnim.parent.height/2;
			}
			
			// PlayModel's display: resized and repositioned
			// to match the flashvars specifications
			if(_player.display)
			{
				var displayH:Number = (_player.config.controls == "always")? h - controlBarHeight : h;
				if(_player.stage.displayState == StageDisplayState.FULL_SCREEN)
					displayH = h;
				setDisplaySize(w, displayH);
			}
			
			_player.evtMngr.dispatchEvent(new ItemEvent(SephPlayerEvent.RESIZE, {width:w, height:h}));
			
		}
		
		private function setDisplaySize(w:Number, h:Number):void {
			var sw:Number = 1;
			var sh:Number = 1;
			var desiredDAR:Number = w / h;
			
			// if there's no autoplay enabled (making the metadata available), _meta_vidWidth and _meta_vidHeight should be gibven a default value!
			if(isNaN(_player.metadata.width))
				_player.metadata.width = w;
			if(isNaN(_player.metadata.height))
				_player.metadata.height = h;
			
			switch(_player.config.scaleMode)
			{
				default :
				case "showAll" : // scale so that ALL of the content fits (letterbox applied)
				{
					// this will assume _meta_DAR ALWAYS has a valid value (not NaN, not Zero)
					if(desiredDAR <= _player.metadata.DAR)
					{
						sw = w / _player.metadata.width;
						sh = sw;
					}
					else if(desiredDAR > _player.metadata.DAR)
					{
						sh = h / _player.metadata.height;
						sw = sh;
					}
					if(isNaN(sw) || sw == 0)
						sw = 1;
					if(isNaN(sh) || sh == 0)
						sh = 1;
					
					break;
				}
				case "exactFit" : // scale to fit the entire screen (no letterbox, default aspect ratio might suffer)
				{
					sw = w / _player.metadata.width;
					sh = h / _player.metadata.height;
					break;
				}
				case "noScale" : // do nothing
				{
					
					break;
				}
				case "lossyScale" :
				{
					// this will assume _meta_DAR ALWAYS has a valid value (not NaN, not Zero)
					if(desiredDAR >= _player.metadata.DAR)
					{
						sw = w / _player.metadata.width;
						sh = sw;
					}
					else if(desiredDAR < _player.metadata.DAR)
					{
						sh = h / _player.metadata.height;
						sw = sh;
					}
					if(isNaN(sw) || sw == 0)
						sw = 1;
					if(isNaN(sh) || sh == 0)
						sh = 1;
					
					break;
				}
			}
			
			/*
			_player.display.width = _player.metadata.width * sw;
			_player.display.height = _player.metadata.height * sh;
			_player.display.x = w/2 - _player.display.width/2;
			_player.display.y = h/2 - _player.display.height/2;
			*/
			
			var _dw:Number = _player.metadata.width * sw;
			var _dh:Number = _player.metadata.height * sh;
			var _dx:Number = w/2 - _dw/2;
			var _dy:Number = h/2 - _dh/2;
			
			var displayTX:Number;
			var displayTY:Number;
			if(Math.round(_player.display.x/_player.display.width - _dx/_dw) == 0)
			{
				displayTX = (_dx - _player.display.x) / 2 + (_dw - _player.display.width) / 2;
				displayTY = (_dy - _player.display.y) / 2 + (_dh - _player.display.height) / 2;
			}
			_player.display.x += displayTX;
			_player.display.y += displayTY;
			
			var time:Number = 0.4;			
			Tweener.removeTweens(_player.display);
			Tweener.addTween(_player.display, {width:_dw, height:_dh, x:_dx, y:_dy, time:time, transition:"easeInOutQuad"});
			
			if(this.overlaySprite)
			{
				var __dw:Number = _dw;
				var __dh:Number = _dh;
				var __dx:Number = _dx;
				var __dy:Number = _dy;
				if(_dw > _player.width)
				{
					__dw = _player.width;
					__dx = 0;
				}
				if(_dh > _player.height)
				{
					__dh = _player.height;
					__dy = 0;
				}
				
				switch(this._player.config.overlayPosition)
				{
					case 1 :
					{
						this.overlaySprite.x = 10;
						this.overlaySprite.y = 10;
						break;
					}
					
					default :
					case 2 :
					{
						this.overlaySprite.x = __dw - this.overlaySprite.width - 10;
						this.overlaySprite.y = 10;
						break;
					}
						
					case 3 :
					{
						this.overlaySprite.x = __dw - this.overlaySprite.width - 10;
						this.overlaySprite.y = __dh - this.overlaySprite.height - 10;
						break;
					}
						
					case 4 :
					{
						this.overlaySprite.x = 10;
						this.overlaySprite.y = __dh - this.overlaySprite.height - 10;
						break;
					}
				}				
				this.overlaySprite.x += __dx;
				this.overlaySprite.y += __dy;
			}			
		}
		
		public function set background(info:*):void {
			
			if(!info)
				return;
			
			// first we clear the background
			if(bg.numChildren > 0)
			{
				if(bg.getChildAt(0) is Loader)
				{
					var oldLdr:Loader = bg.getChildAt(0) as Loader;
					if(oldLdr.content)
						oldLdr.unload();
					bg.removeChild(oldLdr);
				}
			}
			
			// then apply the new background setting
			if(info is Number)
			{
				bg.graphics.clear();
				bg.graphics.beginFill(info);
				bg.graphics.drawRect(0, 0, _player.width, _player.height);
				bg.graphics.endFill();
			}
			else if(info is String)
			{
				var ldr:Loader = new Loader();
				// TODO: see if the background requested is in another domain to the player, if true, require a policy file, else dont allow it to save bandwidth
				var ctx:LoaderContext = new LoaderContext(true, null, (Security.sandboxType == Security.REMOTE) ? SecurityDomain.currentDomain : null);
				ldr.load(new URLRequest(String(info)),ctx);
				bg.addChildAt(ldr, 0);
			}			
		}
		
		public function setOverlay(source:String, position:int):void
		{
			if(!source)
				return;
			
			// first we need to remove the current overlaySprite (if any)
			if(this.overlaySprite)
			{
				if(this.overlaySprite.parent)
					this.overlaySprite.parent.removeChild(this.overlaySprite);
				
				this.overlaySprite.unload();
				this.overlaySprite = null;
			}
			
			// then load the new overlay
			this.overlaySprite = new Loader();
			// TODO: see if the file requested is in another domain to the player, if true, require a policy file, else dont allow it to save bandwidth
			var ctx:LoaderContext = new LoaderContext(true, null, (Security.sandboxType == Security.REMOTE) ? SecurityDomain.currentDomain : null);
			overlaySprite.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onOverlayLoadErrorHandler, false, 0, true);
			overlaySprite.contentLoaderInfo.addEventListener(Event.COMPLETE, onOverlayLoadCompleteHandler, false, 0, true);
			overlaySprite.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onOverlayLoadErrorHandler, false, 0, true);
			overlaySprite.load(new URLRequest(source),ctx);
			this.fg.addChild(this.overlaySprite);
			
			var curClip:Clip = this._player.playlistMngr.getCurrentClip();
			if(_player.playModel && curClip && curClip.clipType != "ad")
			{
				overlaySprite.visible = true;
			}
			else
			{
				overlaySprite.visible = false;
				Traceable.doTrace(this + ": Failed to show overlay since the clip being played is found to be null!");
			}
		}
		
		private function onOverlayLoadErrorHandler(event:Event):void
		{
			event.target.removeEventListener(IOErrorEvent.IO_ERROR,onOverlayLoadErrorHandler);
			event.target.removeEventListener(Event.COMPLETE,onOverlayLoadCompleteHandler);
			event.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,onOverlayLoadErrorHandler);
			Traceable.doTrace(this + ": Could not load overlay!","error");
		}
		
		private function onOverlayLoadCompleteHandler(event:Event):void
		{
			event.target.removeEventListener(IOErrorEvent.IO_ERROR,onOverlayLoadErrorHandler);
			event.target.removeEventListener(Event.COMPLETE,onOverlayLoadCompleteHandler);
			event.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,onOverlayLoadErrorHandler);
			_player.stage.dispatchEvent(new Event(Event.RESIZE));
		}
		
		private function setListeners():void
		{			
			if(!_player.stage)
			{
				Traceable.doTrace(this + ": Please call setListeners only after adding the player to the stage.","error");
				return;
			}
			
			var stage:Stage = _player.stage;
			stage.addEventListener(Event.RESIZE, onStageResizedHandler, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_OVER, onStageMouseOverHandler, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_OUT, onStageMouseOutHandler, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMoveIdledHandler, false, 0, true);
			
			if(!_player.config.live)
				fg.addEventListener(MouseEvent.CLICK, onFgMouseClickedHandler, false, 0, true);
			
			fg.doubleClickEnabled = true;
			fg.addEventListener(MouseEvent.DOUBLE_CLICK, onFullScreenRequestHandler, false, 0, true);
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreenEventHandler, false, 0, true);
			if(fullScreenBtn)
				fullScreenBtn.addEventListener(MouseEvent.CLICK, onBtnClickedHandler, false, 0, true);
			if(normalScreenBtn)
				normalScreenBtn.addEventListener(MouseEvent.CLICK, onBtnClickedHandler, false, 0, true);
			
			if(playBtn)
				playBtn.addEventListener(MouseEvent.CLICK, onBtnClickedHandler, false, 0, true);
			if(pauseBtn)
				pauseBtn.addEventListener(MouseEvent.CLICK, onBtnClickedHandler, false, 0, true);
			if(soundBtn)
				soundBtn.addEventListener(MouseEvent.CLICK, onBtnClickedHandler, false, 0, true);
			if(noSoundBtn)
				noSoundBtn.addEventListener(MouseEvent.CLICK, onBtnClickedHandler, false, 0, true);
			
			if(switchScaleModeBtn)
				switchScaleModeBtn.addEventListener(MouseEvent.CLICK, onBtnClickedHandler, false, 0, true);
			
			if(controlBar)
			{
				if(controlBar["bar"])
					controlBar["bar"].addEventListener(MouseEvent.MOUSE_DOWN, startSeeking, false, 0, true);
				controlBar.addEventListener(MouseEvent.MOUSE_UP, onControlBarMouseUpHandler, false, 0, true);
			}
			
			if(settingSlidePanel)
				settingSlidePanel.addEventListener(SephPlayerEvent.BITRATE_SWITCH_REQUEST, onBitrateSwitchRequestHandler, false, 0, true);
			
			if(qualityBtn)
			{
				qualityBtn.addEventListener(SephPlayerEvent.BITRATE_SWITCH_REQUEST, onBitrateSwitchRequestHandler, false, 0, true);
				if(qualityBtn.hasOwnProperty("buttonMode"))
					qualityBtn["buttonMode"] = true;
			}
			
			_player.evtMngr.addEventListener(SephPlayerEvent.FILE_PLAY_START, onFilePlayFirstStartHandler, false, 0, true);
			_player.evtMngr.addEventListener(SephPlayerEvent.FILE_PLAY_COMPLETE, onFilePlayFinalCompleteHandler, false, 0, true);			
		}
		
		private function startSeeking(event:MouseEvent):void
		{			
			// do not proceed if there's no playModel
			if(!this._player.playModel)
				return;
			
			// also do not proceed if we're PAUSING while streamning from RED5 server
			if(this.playBtn.visible && this._player.config.streamer)
			{
				notice(SephPlayer.LANG.WARN_RED5_RTMP_SEEKING_WHILE_PAUSING);
				return;
			}
			
			// stop the timer so the time related GUI elements is not updated while seeking
			if(this._player.playModel && this._player.playModel.timer)
				this._player.playModel.timer.removeEventListener(TimerEvent.TIMER, this._player.playModel.onTimerHandler);
			
			controlBar["bar"].addEventListener(MouseEvent.MOUSE_UP, stopSeeking, false, 0, true);
			_player.stage.addEventListener(MouseEvent.MOUSE_UP, stopSeeking, false, 0, true);
			_player.stage.addEventListener(MouseEvent.MOUSE_MOVE, doSeeking, false, 0, true);
		}
		
		private function stopSeeking(event:MouseEvent):void
		{
			controlBar["bar"].removeEventListener(MouseEvent.MOUSE_UP, stopSeeking);
			_player.stage.removeEventListener(MouseEvent.MOUSE_UP, stopSeeking);
			_player.stage.removeEventListener(MouseEvent.MOUSE_MOVE, doSeeking);
			
			// call this BEFORE calling seek, useful in dealing with RED5 seeking issue (covered later)
			//var willPlayAfterSeek:Boolean = this.pauseBtn.visible;
			
			var seekPoint:Number = doSeeking();
			//trace("Requested seek point: " + seekPoint);
			_player.playModel.seek(seekPoint);
			
			// start the timer again to update time related GUI elements
			if(this._player.playModel && this._player.playModel.timer)
				this._player.playModel.timer.addEventListener(TimerEvent.TIMER, this._player.playModel.onTimerHandler, false, 0, true);
			// since RED5 will send NetStream.Play.Start automatically after Seek action
			// we have no choice but to assume the user presses "Pause" after seeking
			// if we need to maintain the pause status before seeking
			/*if(_player.config.streamer) {
				if(!willPlayAfterSeek) {
					var timer:Timer = new Timer(1000, 3);
					timer.addEventListener(TimerEvent.TIMER, playAfterRED5Seek, false, 0, true);
					timer.start();
				}
			}*/
			
			/*function playAfterRED5Seek(event:TimerEvent):void {
				if(event.target.currentCount == 1) {
					receiveGUIEvent(SephPlayerEvent.PAUSE_BTN_CLICKED);
				} else if(event.target.currentCount == 2) {
					receiveGUIEvent(SephPlayerEvent.PLAY_BTN_CLICKED);
				} else if(event.target.currentCount == 3) {
					receiveGUIEvent(SephPlayerEvent.PAUSE_BTN_CLICKED);
					event.target.removeEventListener(TimerEvent.TIMER, playAfterRED5Seek);
				}
			}*/			
		}
		
		private function doSeeking(event:MouseEvent = null):Number
		{			
			if(isNaN(_player.metadata.duration))
				return 0;
			
			var ratio:Number = controlBar["bar"].mouseX / controlBar["bar"]["barTrack"].width;
			//trace("Ratio: " + ratio);
			if(ratio < 0)
				ratio = 0.1;
			else if(ratio > 1)
				ratio = 0.999;
			
			// seekPoint could be based on the value of _player.config.start
			// but we stopped using that feature because the offset in _ns.start is so silly
			var seekPoint:Number = _player.metadata.duration * ratio /* - _player.config.start*/;
			
			// we only seek in real-time if the file is played progressively. with streamer, let's leave it till the user stops seeking
			if(!_player.config.streamer)
			{
				if(_player.playModel)
					_player.playModel.seek(seekPoint);
			}
			
			// update the playhead bar and leftTF for better user GUI experience
			this.updateBar(ratio * 100);
			this.updateLeftTF(SephPlayerUtils.convertFromSecToMin(seekPoint));
			
			_player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.SEEK));
			
			return seekPoint;			
		}
		
		public function updateLeftTF(content:String):void
		{
			controlBar["leftTF"].text = content;
		}
		
		public function updateRightTF(content:String):void
		{
			controlBar["rightTF"].text = content;
		}
		
		public function updateBar(progPerc:Number = NaN, loadPerc:Number = NaN):void
		{			
			if(!isNaN(progPerc))
			{
				if(progPerc < 0)
					progPerc = 0;
				else if(progPerc > 100)
					progPerc = 100;
				
				var barProgWidth:Number = controlBar["bar"]["barTrack"].width * progPerc / 100;
				controlBar["bar"]["barProg"].width = barProgWidth;
			}
			
			if(!isNaN(loadPerc))
			{
				if(loadPerc < 0)
					loadPerc = 0;
				else if(loadPerc > 100)
					loadPerc = 100;
				
				var barLoaWidth:Number = controlBar["bar"]["barTrack"].width * loadPerc / 100;
				controlBar["bar"]["barLoa"].width = barLoaWidth;
			}
			
			//trace("prog: " + barProgWidth + ", load: " + barLoaWidth);
			
			//Tweener.addTween(controlBar["bar"]["barLoa"], {width:barLoaWidth, time:0.3, transition:"linear"});
			//Tweener.addTween(controlBar["bar"]["barProg"], {width:barProgWidth, time:0.3, transition:"linear"});
		}
		
		public function streamingStatusHandler(statusObj:*):void
		{
			var code:String = "";
			var event:NetStatusEvent;
			
			if(statusObj is NetStatusEvent)
			{
				event = NetStatusEvent(statusObj);
				code = event.info.code;
			}
			else if(statusObj is String)
			{
				code = String(statusObj);
			}
			
			switch(code)
			{
				case "NetConnection.Connect.Success" :
				{
					if(playBtn)
						playBtn.visible = true;
					
					this.addLoadAnim();
					notice(SephPlayer.LANG.READY_TO_STREAM);
					break;
				}
					
				case "NetConnection.Connect.Closed" :
				{
					if(playBtn)
						playBtn.visible = true;
					if(pauseBtn)
						pauseBtn.visible = false;
					this.removeLoadAnim();
					if(this._player.playModel is VideoPlayModel && VideoPlayModel(this._player.playModel).isPlayFinalCompleteDispatched == false)
						notice(SephPlayer.LANG.CONNECTION_CLOSED, true);
					break;
				}
					
				case "NetConnection.Connect.Rejected" :
				{
					if(playBtn)
						playBtn.visible = true;
					if(pauseBtn)
						pauseBtn.visible = false;
					this.removeLoadAnim();
					var desc:String;
					if(event)
					{
						switch(SephPlayerGlobal.SERVER_TYPE)
						{
							case "wowza" :
							{
								desc = String(event.info.application);
								break;
							}
								
							default :
							{
								desc = String(event.info.description);
								break;
							}
						}
					}
					var reason:String = SephPlayer.LANG.CONNECTION_REJECTED + " " + ((desc)? desc : SephPlayer.LANG.PLEASE_CONTACT_ADMIN);
					notice(reason, true);
					break;
				}
					
				case "NetConnection.Connect.Failed" :
				{
					if(playBtn)
						playBtn.visible = true;
					if(pauseBtn)
						pauseBtn.visible = false;
					this.removeLoadAnim();
					notice(SephPlayer.LANG.CONNECTION_FAILED, true);
					break;
				}
					
				case "NetStream.Play.Start" :
				{				
					if(playBtn)
						playBtn.visible = false;
					if(pauseBtn)
						pauseBtn.visible = true;
					
					// making sure OVA plugin will not mess up with the controlBar
					// in any way possible
					if(!_player.config.live)
						this.enableControlBar();
					
					toggleControls(false);
					notice(SephPlayer.LANG.BUFFERING);
					
					addLoadAnim();
					
					break;
				}
					
				case "NetStream.Play.Stop" :
				{
					// currently we disable this, since Play.Stop doesn't always mean the playback actually stops
					/*
					playBtn.visible = true;
					pauseBtn.visible = false;
					toggleControls(true);
					updateBar(0);
					*/
					
					this.removeLoadAnim();					
					if(this.overlaySprite)
						this.overlaySprite.visible = false;
					
					break;
				}
					
				case "NetStream.Play.Complete" :
				{
					if(playBtn)
						playBtn.visible = true;
					if(pauseBtn)
						pauseBtn.visible = false;
					toggleControls(true);
					updateBar(0);
					removeLoadAnim();
					if(this.overlaySprite)
						this.overlaySprite.visible = false;
					break;
				}
					
				case "NetStream.Play.StreamNotFound" :
				{
					if(playBtn)
						playBtn.visible = true;
					if(pauseBtn)
						pauseBtn.visible = false;
					toggleControls(true);
					this.removeLoadAnim();
					
					// a nice user feedback
					var curClip:Clip = this._player.playlistMngr.getCurrentClip();
					var curClipStreamer:String = "null";
					if(curClip.streamer)
						curClipStreamer = SephPlayerUtils.getStreamerNameAndArg(curClip.streamer)["streamer"];
					
					if(_player.config.live)
						notice(SephPlayer.LANG.LIVE_STREAM_NOT_FOUND, false);
					else
						notice(SephPlayer.LANG.STREAM_NOT_FOUND, true);
						//notice(SephPlayer.LANG.STREAM_NOT_FOUND + ": " + curClip.file + "@" + curClipStreamer, true);
					
					Traceable.doTrace("Sream not found.","error");
					break;
				}
					
				case "NetStream.Play.Transition" :
				{
					this.allowsQualityPanel = false;
					this.allowsQualityBtn = false;
					break;
				}
					
				case "NetStream.Play.TransitionComplete" :
				{
					this.allowsQualityPanel = true;
					this.allowsQualityBtn = true;
					break;
				}
				
				case "NetStream.Pause.Notify" :
				{
					if(playBtn)
						playBtn.visible = true;
					if(pauseBtn)
						pauseBtn.visible = false;
					notice(SephPlayer.LANG.PAUSED, true);
					break;
				}
				
				case "NetStream.Unpause.Notify" :
				{
					if(playBtn)
						playBtn.visible = false;
					if(pauseBtn)
						pauseBtn.visible = true;
					notice(SephPlayer.LANG.UNPAUSE);
					break;
				}
				
				case "NetStream.Buffer.Full" :
				{
					// only update the GUI if the player is playing, not seeking
					// we do this since this event can be fired while seeking
					// and we do not want it to interfere with the current play / pause
					// status of the player
					if(this._player.playModel.timer.running)
					{
						if(playBtn)
							playBtn.visible = false;
						if(pauseBtn)
							pauseBtn.visible = true;
						removeLoadAnim();
						if(this.overlaySprite && _player.playlistMngr.getCurrentClip().clipType.toLowerCase() != "ad")
							this.overlaySprite.visible = true;
					}
					break;
				}
				
				case "NetStream.Buffer.Empty" :
				{
					//notice(SephPlayer.LANG.BUFFER_EMPTY); // can be disabled if it flickers the ad countdown
					if(!_player.playModel.isPlaying)
					{
						// if the player has finished playing a file (Buffer.Empty is called the last time)
						if(playBtn)
							playBtn.visible = true;
						if(pauseBtn)
							pauseBtn.visible = false;
						updateBar(0);
						notice(SephPlayer.LANG.PLAYBACK_END, true);
					}
					else
					{
						// is the player is still playing a file (Buffer.Empty dispatched in the middle of a clip)
						addLoadAnim();
					}
					break;
				}
					
				case "NetStream.Buffer.Flush" :
				{
					//notice(SephPlayer.LANG.BUFFER_FLUSH); // currently disabled so it does not flicker the ad countdown
					break;
				}
					
				case "NetStream.Failed" :
				{
					if(playBtn)
						playBtn.visible = true;
					if(pauseBtn)
						pauseBtn.visible = false;
					toggleControls(true);
					this.removeLoadAnim();
					notice(SephPlayer.LANG.GENERAL_ERROR, true);
					break;
				}
					
				case "NetStream.Play.InsufficientBW" :
				{
					notice(SephPlayer.LANG.INSUFFICIENT_BW);
					break;
				}
					
				case "NetStream.Seek.Notify" :
				{
					this.addLoadAnim();
					notice(SephPlayer.LANG.BUFFERING);
					break;
				}
					
				case "NetStream.Seek.InvalidTime" :
				{
					//
					break;
				}
					
				default :
				{
					notice("Unhandled msg: " + code);
					break;
				}
			}
		}
		
		private function onBtnClickedHandler(event:MouseEvent):void
		{
			resetIdledState();
			switch(event.currentTarget)
			{
				case this.playBtn :
				{
					this.receiveGUIEvent(SephPlayerEvent.PLAY_BTN_CLICKED);
					break;
				}
				case this.pauseBtn :
				{
					this.receiveGUIEvent(SephPlayerEvent.PAUSE_BTN_CLICKED);
					break;
				}
				case this.soundBtn :
				case this.noSoundBtn :
				{
					onMuteRequestHandler();
					break;
				}
				case this.fullScreenBtn :
				case this.normalScreenBtn :
				{
					onFullScreenRequestHandler();
					break;
				}
				case switchScaleModeBtn :
				{
					this.receiveGUIEvent(SephPlayerEvent.SCALE_MODE_SWITCH_REQUESTED);
					break;
				}
			}
		}
		
		private function onMuteRequestHandler():void
		{
			if(_player.playModel)
			{
				_player.playModel.mute = !_player.playModel.mute;
				soundBtn.visible = !_player.playModel.mute;
				noSoundBtn.visible = _player.playModel.mute;
				
				if(_player.playModel.mute)
					_player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.MUTE));
				else if(!_player.playModel.mute)
					_player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.UNMUTE));				
			}
			else
			{
				Traceable.doTrace(this + "- onMuteRequestHandler: There's no playModel!","error");
			}
		}
		
		private function onFullScreenRequestHandler(event:Event = null):void
		{
			Traceable.doTrace(this + ": Processing Fullscreen Request.");
			if(!_player.stage)
				return;
			
			var stage:Stage = _player.stage;
			if(stage.displayState == StageDisplayState.FULL_SCREEN)
				stage.displayState = StageDisplayState.NORMAL;
			else
				stage.displayState = StageDisplayState.FULL_SCREEN;
			
			if(_player.playModel && _player.playModel is VideoPlayModel)
				VideoPlayModel(_player.playModel).exploreVideoDecodingCapability();
			
			if(event)
				event.stopPropagation();
		}
		
		private function onFullScreenEventHandler(event:FullScreenEvent):void
		{
			if(event.fullScreen)
			{				
				fullScreenBtn.visible = false;
				normalScreenBtn.visible = true;
				
				// when going fullscreen, make controls flashvar "auto"
				//notice("Configuration 'controls' set from '" + this._player.config.controls + "' to 'auto'");
				_normalscreen_config_controls = this._player.config.controls;
				this._player.config.controls = "auto";
				
				// only to apply the configuration since we stopPropagation on fullScreen event
				// the flag here isn't important since it will be overwritten in the toggleControls() method
				this.toggleControls(false);
				
				// let the external know about the event
				this._player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.GO_FULL_SCREEN));				
			}
			else
			{				
				fullScreenBtn.visible = true;
				normalScreenBtn.visible = false;
				
				// return controls flashvars back to its normalscreen value
				//notice("Configuration 'controls' set from '" + this._player.config.controls + "' to '" + this._normalscreen_config_controls + "'");
				this._player.config.controls = _normalscreen_config_controls;
				
				// only to apply the configuration since we stopPropagation on fullScreen event
				// the flag here isn't important since it will be overwritten in the toggleControls() method
				this.toggleControls(false);
				
				// let the external know about the event
				this._player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.GO_NORMAL_SCREEN));
			}
		}
		
		private function toggleControls(flag:Boolean, duration:Number = 0.6):void
		{			
			var delay:Number = 0;
			
			if(flag)
				_player.evtMngr.dispatchEvent(new ItemEvent(SephPlayerEvent.CONTROLBAR_TOGGLED, SephPlayerEvent.CONTROLBAR_ON));
			else
				_player.evtMngr.dispatchEvent(new ItemEvent(SephPlayerEvent.CONTROLBAR_TOGGLED, SephPlayerEvent.CONTROLBAR_OFF));
			
			switch(_player.config.controls)
			{
				case "none" :
				{
				
					break;
				}
				case "always" :
				{
					flag = true;
					break;
				}
				case "auto" :
				{
					
					break;
				}
			}
			
			this._isControlBarOn = flag;
			if(flag)
			{
				_controlBarY = _player.stage.stageHeight - controlBarHeight;
				//delay = 0; // don't add delay here since we used idledBuffer and idledWatcher already
			}
			else
			{
				_controlBarY = _player.stage.stageHeight;
				//delay = 3; // don't add delay here since we used idledBuffer and idledWatcher already
			}
			Tweener.removeTweens(controlBar);
			Tweener.addTween(controlBar, {y:_controlBarY, time:duration, delay:delay, transition:"easeOutSine", onComplete:afterTogglingControlBar, onCompleteParams:[flag]});			
		}
		
		private function afterTogglingControlBar(flag:Boolean):void
		{
			// toggle mouse
			if(flag)
				Mouse.show();
			else
				Mouse.hide();
		}
		
		public function enableControlBar():void
		{			
			if(pauseBtn && playBtn)
				this.pauseBtn.alpha = this.playBtn.alpha = 1;
			if(bar)
				this.bar.visible = true;
			if(leftTF)
				this.leftTF.visible = true;
			if(rightTF)
				this.rightTF.visible = true;
			if(this.settingsBtn)
				this.settingsBtn.alpha = 1;
			if(this.qualityBtn)
				this.qualityBtn.alpha = 1;
			//this.controlBar.visible = true;
			
			if(this.bar && this.bar.hasOwnProperty("mouseEnabled"))
				this.bar["mouseEnabled"] = true;
			
			if(this.bar && this.bar.hasOwnProperty("mouseChildren"))
				this.bar["mouseChildren"] = true;
			
			if(this.pauseBtn && this.pauseBtn.hasOwnProperty("mouseEnabled"))
				this.pauseBtn["mouseEnabled"] = true;
			
			if(pauseBtn && this.pauseBtn is DisplayObjectContainer)
				DisplayObjectContainer(this.pauseBtn).mouseChildren = true;
			
			if(this.playBtn && this.playBtn.hasOwnProperty("mouseEnabled"))
				this.playBtn["mouseEnabled"] = true;
			
			if(playBtn && playBtn is DisplayObjectContainer)
				DisplayObjectContainer(playBtn).mouseChildren = true;
			
			if(this.settingsBtn && this.settingsBtn.hasOwnProperty("mouseEnabled"))
				this.settingsBtn["mouseEnabled"] = true;
			
			if(this.qualityBtn && this.qualityBtn.hasOwnProperty("mouseEnabled"))
				this.qualityBtn["mouseEnabled"] = true;
			
			//this.fg.mouseChildren = this.fg.mouseEnabled = true;
			this.fgEnabled = true;
		}
		
		public function disableControlBar():void
		{			
			if(pauseBtn && playBtn)
				this.pauseBtn.alpha = this.playBtn.alpha = 0.3;
			if(bar)
				this.bar.visible = false;
			if(leftTF)
				this.leftTF.visible = false;
			if(rightTF)
				this.rightTF.visible = false;
			if(this.settingsBtn)
				this.settingsBtn.alpha = 0.3;
			if(this.qualityBtn)
				this.qualityBtn.alpha = 0.3;
			//this.controlBar.visible = false;
			
			if(bar && this.bar.hasOwnProperty("mouseEnabled"))
				this.bar["mouseEnabled"] = false;
			
			if(bar && this.bar.hasOwnProperty("mouseChildren"))
				this.bar["mouseChildren"] = false;
			
			if(pauseBtn && this.pauseBtn.hasOwnProperty("mouseEnabled"))
				this.pauseBtn["mouseEnabled"] = false;
			
			if(pauseBtn && pauseBtn is DisplayObjectContainer)
				DisplayObjectContainer(pauseBtn).mouseChildren = false;
			
			if(playBtn && this.playBtn.hasOwnProperty("mouseEnabled"))
				this.playBtn["mouseEnabled"] = false;
		
			if(playBtn && playBtn is DisplayObjectContainer)
				DisplayObjectContainer(playBtn).mouseChildren = false;
			
			if(settingsBtn && this.settingsBtn.hasOwnProperty("mouseEnabled"))
				this.settingsBtn["mouseEnabled"] = false;
			
			if(qualityBtn && this.qualityBtn.hasOwnProperty("mouseEnabled"))
				this.qualityBtn["mouseEnabled"] = false;
			
			//this.fg.mouseChildren = this.fg.mouseEnabled = false;
			this.fgEnabled = false;
		}
		
		private function onStageResizedHandler(event:Event):void
		{
			this._player.setSize(event.target.stageWidth, event.target.stageHeight);
		}
		
		private function onStageMouseOverHandler(event:MouseEvent):void
		{
			toggleControls(true,0);
			_player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.MOUSE_OVER));
		}
		
		private function onStageMouseOutHandler(event:MouseEvent):void
		{
			/*
			if(this._player.playModel && this._player.playModel.isPlaying)
				toggleControls(false);
			*/
			_player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.MOUSE_OUT));
		}
		
		private function onControlBarMouseUpHandler(event:MouseEvent):void
		{
			/*
			if(this._player.playModel && this._player.playModel.isPlaying)
				toggleControls(false);
			*/
		}
		
		public function notice(info:String, persistent:Boolean = false):void
		{
			//trace(info);
			if(Tweener.isTweening(tracer))
			{
				Tweener.pauseTweens(tracer);
				Tweener.removeTweens(tracer);
			}
			tracer["alpha"] = 0.8;
			tracer.text = info;
			if(!persistent)
				Tweener.addTween(tracer,{alpha:0, time:0.3, delay:5});
		}
		
		public function addPlugin(plugin:*):void
		{
			this.fg.addChild(plugin);
		}
		
		public function removePlugin(plugin:*):Boolean
		{
			try
			{
				var removed:DisplayObject = this.fg.removeChild(plugin);
				if(removed) return true;
			}
			catch(e:Error)
			{
				return false;
			}
			return false;
		}
		
		public function receiveGUIEvent(type:String, details:* = null):void
		{
			switch(type)
			{
				case SephPlayerEvent.PLAY_BTN_CLICKED :
				{
					if(this._player.doPlayFile())
					{
						pauseBtn.visible = true;
						playBtn.visible = false;
						
						_player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.PLAY));						
					}
					else
					{
						// if autoStart = true, pauseBtn shows up and playBtn gets hidden
						// but what if the file fails to play? => hide pauseBtn and show playBtn!
						pauseBtn.visible = false;
						playBtn.visible = true;
					}
					break;
				}
					
				case SephPlayerEvent.PAUSE_BTN_CLICKED :
				{
					if(this._player.doPauseFile())
					{
						pauseBtn.visible = false;
						playBtn.visible = true;
						notice(SephPlayer.LANG.PAUSED);
						
						_player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.PAUSE));	
					}
					break;
				}
					
				case SephPlayerEvent.STOP :
				{
					if(this._player.doStopFile())
					{
						pauseBtn.visible = false;
						playBtn.visible = true;
					}
					break;
				}
					
				case SephPlayerEvent.SCALE_MODE_SWITCH_REQUESTED :
				{
					if(details)
					{
						this._player.config.scaleMode = String(details);
					}
					else
					{
						switch(_player.config.scaleMode)
						{
							case "noScale" :
							{
								this._player.config.scaleMode = "showAll";
								this.notice(SephPlayer.LANG.SCALE_MODE_DESC_SHOWALL);
								break;
							}
							default :
							case "showAll" :
							{
								this._player.config.scaleMode = "lossyScale";
								this.notice(SephPlayer.LANG.SCALE_MODE_DESC_LOSSYSCALE);
								break;
							}
							case "lossyScale" :
							{
								this._player.config.scaleMode = "exactFit";
								this.notice(SephPlayer.LANG.SCALE_MODE_DESC_EXACTFIT);
								break;
							}
							case "exactFit" :
							{
								this._player.config.scaleMode = "noScale";
								this.notice(SephPlayer.LANG.SCALE_MODE_DESC_NOSCALE);
								break;
							}
						}
					}
					_player.root.stage.dispatchEvent(new Event(Event.RESIZE));
					break;
				}
				
				case SephPlayerEvent.BITRATE_SWITCH_REQUEST :
				{
					switch(String(details))
					{
						case "+" :
						{
							_player.switchToHigherBitrate();
							break;
						}
						case "-" :
						{
							_player.switchToLowerBitrate();
							break;
						}
						default :
						{
							Traceable.doTrace(this + ": About to switch to stream " + String(details));
							_player.switchToStreamName(String(details));
							break;
						}
					}
					break;
				}
				
				case SephPlayerEvent.BITRATE_GUI_CHANGE_REQUEST :
				{
					if(details != null)
					{						
						// details should be 1 based, not 0 based as usual						
						if(this.settingSlidePanel)
						{
							if(this.settingSlidePanel["qualityPanel"] &&
							   this.settingSlidePanel["qualityPanel"]["qualitySlider"])
							{
								if(this.settingSlidePanel["qualityPanel"]["qualitySlider"].getHandler() != int(details))
								{
									this.settingSlidePanel["qualityPanel"]["qualitySlider"].setHandler(int(details));
									this.toggleControls(true);
									
									// at its simplest form, if details equal 1, it means the internet speed is bad
									// refer to the onBWDone method defined in VideoPlayModel
									if(int(details) == 1)
										this.notice(SephPlayer.LANG.INTERNET_CONNECTION_QUALITY_BAD);
									else
										this.notice(SephPlayer.LANG.INTERNET_CONNECTION_QUALITY_GOOD);
								}
							}
						}
						else if(this.qualityBtn)
						{
							if(this.qualityBtn["getHandler"]() != int(details))
							{
								this.qualityBtn["setHandler"](int(details));
								this.toggleControls(true);
								
								// at its simplest form, if details equal 1, it means the internet speed is bad
								// refer to the onBWDone method defined in VideoPlayModel
								if(int(details) == 1)
									this.notice(SephPlayer.LANG.INTERNET_CONNECTION_QUALITY_BAD);
								else
									this.notice(SephPlayer.LANG.INTERNET_CONNECTION_QUALITY_GOOD);
							}
						}
					}
					break;
				}
				
				case SephPlayerEvent.BITRATE_OPTIONS_SET :
				{
					if(details && details is Array)
					{
						if(settingsBtn)
						{
							Traceable.doTrace(this + ": BITRATE_OPTIONS_SET called. \"settingsBtn\" found.");
							if(DisplayObjectContainer(this.settingSlidePanel).numChildren != 0)
							{
								if(this.settingSlidePanel && this.settingSlidePanel["qualityPanel"] && this.settingSlidePanel["qualityPanel"]["defineStreamOptions"])
									this.settingSlidePanel["qualityPanel"].defineStreamOptions(details);
								else
									Traceable.doTrace(this + ": Either there's no \"settingSlidePanel\" or its \"qualityPanel\" skin element, or the \"qualityPanel\" doesn't support the method \"degineStreamOptions\".");
							}
						}
						else if(qualityBtn)
						{
							Traceable.doTrace(this + ": BITRATE_OPTIONS_SET called. \"qualityBtn\" found.");
							if(qualityBtn["defineStreamOptions"])
								this.qualityBtn["defineStreamOptions"](details);
							else
								Traceable.doTrace(this + ": The \"qualityBtn\" doesn't support the interface method \"defineStreamOptions\".");
						}
					}
					break;
				}
			}
		}
		
		private function onBitrateSwitchRequestHandler(event:ItemEvent):void
		{
			this.receiveGUIEvent(SephPlayerEvent.BITRATE_SWITCH_REQUEST, event.id);
		}
		
		private function onFgMouseClickedHandler(event:MouseEvent):void
		{
			_player.evtMngr.dispatchEvent(new Event(SephPlayerEvent.CLICK_THROUGH));
			if(!this.fgEnabled)
				return;
			if(this.playBtn.visible)
				this.receiveGUIEvent(SephPlayerEvent.PLAY_BTN_CLICKED);
			else
				this.receiveGUIEvent(SephPlayerEvent.PAUSE_BTN_CLICKED);
		}
		
		private function onFilePlayFirstStartHandler(event:Event = null):void
		{
			this.bg.visible = false;
		}
		
		private function onFilePlayFinalCompleteHandler(event:Event = null):void
		{
			this.bg.visible = true;
		}
		
		private function onStageMouseMoveIdledHandler(event:MouseEvent):void
		{
			this.resetIdledState();
		}
		
		private function onIdledTimerHandler(event:TimerEvent):void
		{
			if(this._idledBuffer == 5)
			{
				this.toggleControls(false); // !important: don't let this be called continuously (such as by a timer invoked function) cause it won't work!
				this._idledBuffer = 6;
			}
			
			if(this._idledBuffer >= int.MAX_VALUE)
			{
				this._idledBuffer = 6;
			}
			
			this._idledBuffer++;
		}
		
		private final function resetIdledState():void
		{
			toggleControls(true,0);
			this._idledBuffer = 0;
		}
		
		private function removeListeners():void
		{			
			if(!_player.stage)
			{
				Traceable.doTrace(this + ": Please call removeListeners only after adding the player to the stage","error");
				return;
			}
			
			var stage:Stage = _player.stage;
			stage.removeEventListener(Event.RESIZE, onStageResizedHandler);
			stage.removeEventListener(MouseEvent.MOUSE_OVER, onStageMouseOverHandler);
			stage.removeEventListener(MouseEvent.MOUSE_OUT, onStageMouseOutHandler);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMoveIdledHandler);
			
			fg.removeEventListener(MouseEvent.CLICK, onFgMouseClickedHandler);
			fg.removeEventListener(MouseEvent.DOUBLE_CLICK, onFullScreenRequestHandler);
			stage.removeEventListener(FullScreenEvent.FULL_SCREEN, onFullScreenEventHandler);
			if(fullScreenBtn)
				fullScreenBtn.removeEventListener(MouseEvent.CLICK, onBtnClickedHandler);
			if(normalScreenBtn)
				normalScreenBtn.removeEventListener(MouseEvent.CLICK, onBtnClickedHandler);
			
			if(playBtn)
				playBtn.removeEventListener(MouseEvent.CLICK, onBtnClickedHandler);
			if(pauseBtn)
				pauseBtn.removeEventListener(MouseEvent.CLICK, onBtnClickedHandler);
			if(soundBtn)
				soundBtn.removeEventListener(MouseEvent.CLICK, onBtnClickedHandler);
			if(noSoundBtn)
				noSoundBtn.removeEventListener(MouseEvent.CLICK, onBtnClickedHandler);
			
			if(switchScaleModeBtn)
				switchScaleModeBtn.removeEventListener(MouseEvent.CLICK, onBtnClickedHandler);
			if(qualityBtn)
				qualityBtn.removeEventListener(SephPlayerEvent.BITRATE_SWITCH_REQUEST, onBitrateSwitchRequestHandler);
			
			if(controlBar)
			{
				controlBar.removeEventListener(MouseEvent.MOUSE_UP, onControlBarMouseUpHandler);
				if(controlBar["bar"])
					controlBar["bar"].removeEventListener(MouseEvent.MOUSE_DOWN, startSeeking);
			}
			
			if(settingSlidePanel)
				settingSlidePanel.removeEventListener(SephPlayerEvent.BITRATE_SWITCH_REQUEST, onBitrateSwitchRequestHandler);
			
			_player.evtMngr.removeEventListener(SephPlayerEvent.FILE_PLAY_START, onFilePlayFirstStartHandler);
			_player.evtMngr.removeEventListener(SephPlayerEvent.FILE_PLAY_COMPLETE, onFilePlayFinalCompleteHandler);
		}
		
		public final function getControlBar():DisplayObject
		{
			return this.controlBar;
		}
		
		private final function getSkinInstance(className:String):*
		{
			var TheClass:*;
			if(this._skinAssets && this._skinAssets.hasDefinition(className))
			{
				TheClass = this._skinAssets.getDefinition(className);
				return new TheClass();
			}
			else
			{
				// this might happen when compiled with Flex, meaning there's no LoaderInfo object to refer to				
				TheClass = ClassResolver.getClass(className);
				if(TheClass)
					return new TheClass();
			}
			return null;
		}
		
		public final function removeControlBarItem(itemName:String):void
		{
			if(this[itemName])
			{
				var target:DisplayObject = this[itemName] as DisplayObject;
				if(target && target.parent)
				{
					target.parent.removeChild(target);
					this._player.stage.dispatchEvent(new Event(Event.RESIZE));
				}
			}
		}
		
		public final function addControlBarItem(itemName:String):void
		{
			if(this[itemName])
			{
				var target:DisplayObject = this[itemName] as DisplayObject;
				if(target && !target.parent)
				{
					this.controlBar.addChild(target);
					this._player.stage.dispatchEvent(new Event(Event.RESIZE));
				}
			}
		}
		
		public final function addLoadAnim():void
		{
			if(loadAnim == null)
			{
				loadAnim = this.getSkinInstance("LoadAnim");
				if(loadAnim)
				{
					this._player.addChild(loadAnim);
					loadAnim.x = loadAnim.parent.width/2;
					loadAnim.y = loadAnim.parent.height/2;
				}
			}
		}
		
		public final function removeLoadAnim():void
		{
			if(loadAnim && loadAnim.parent)
			{
				loadAnim.parent.removeChild(loadAnim);
				loadAnim = null;
				//if(Tweener.isTweening(this.loadAnim)) Tweener.removeTweens(loadAnim);
				//Tweener.addTween(this.loadAnim, {alpha:0, time:0.6, delay:3, onComplete:doRemoveLoadAnim});
			}
		}
		
		/*
		private final function doRemoveLoadAnim():void
		{
			if(loadAnim && loadAnim.parent)
			{
				loadAnim.parent.removeChild(loadAnim);
				loadAnim = null;
			}
		}
		*/
	}	
}