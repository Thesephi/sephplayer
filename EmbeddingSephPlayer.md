# Embedding SephPlayer #

At its simplest form, SephPlayer is embedded using swfobject, like this:
```
var flashvars = {
	file:"<PATH_TO_MEDIA_FILE>", // can be an absolute or relative path, or a JSON object (converted into a String) that contains ONE or an ARRAY of items to be played
	streamer:"<STREAMER_URL>", // something like rtmp://your_streaming_server/your_scope
	controls:"auto", // auto | none | always
	autoStart:true,
	mute:false,
	scaleMode:"showAll", // showAll | noScale | lossyScale | exactFit
	background:"resources/vidBg.jpg" // use color, such as 0x000000, or url (relative or absolute) to an image here
};
var params = {
	loop:"false",
	menu:"false",
	quality:"high",
	wmode:"window",
	bgcolor:"#000000",
	allowScriptAccess:"always", // this should be "always" so that cross-scripting between html pages and swf files on different domains can work together
	allowFullScreen:"true"
};
var attributes = {
	id:"SephPlayer", // this is very important so you can reference the player later
	name:"SephPlayer"
};

swfobject.embedSWF("<PATH_TO_SEPHPLAYER_SWF_FILE>","<CONTAINING_DIV_ID>","w","h","version","<PATH_TO_EXPRESS_INSTALL_SWF>",flashvars,params,attributes);
```
<br />
# Example #

### Notices - MUST READ! ###
  1. _The following example also demonstrates how to setup plugins for SephPlayer. One of which is the [OVA](http://www.longtailvideo.com/open-video-ads/) plugin for SephPlayer._
  1. _Notice that the 2 flashvars `flashvar_file` and `flashvar_plugins` are of **JSON** type, but got **parsed into type String** before being used by the swfobject embed code._
  1. _Notice the `flashvar_file` block: it **contains** all of the [flashvars](https://code.google.com/p/sephplayer/wiki/Flashvars) available to SephPlayer (such as `file`, `streamer`, etc.) and thus, it can be used to setup an item or a list of items (playlist) for playback later. You can also specify a key called `movieTitle` here, which is a String pointing to the **title** of the corresponding clip. One example of its usages is for the SubReader plugin to compare and, if it matches the **title** that SubReader is registered to work on, it will show the subtitle entries associated with that clip._

### The code ###
```
var flashvar_file = [
	{
		"file": "resources/thuckhach1.flv",
		"movieTitle": "SAMPLE",
		"streamer": null,
		"plugins": {
			"name": "SubReader",
			"source": "plugin_2-0/subReader/subReaderPlugin.swf",
			"config": {
				"movieTitle": "SAMPLE",
				"source": "resources/sikgaek_01_P1.srt",
				"textColor": "0xFFFFFF",
				"backgroundColor": "0x222222",
				"marginBottom": 13
			}
		}
	}
];

// !important: parsing from a JSON object to a String to be used by swfobject later
flashvar_file = JSON.stringify(flashvar_file);
		
var flashvar_plugins = [
	{
		"name": "OvaSephPlayer",
		"source": "plugin_2-0/ova-sephPlayer/ova-sephPlayer.swf",
		"config": {
			"overlays": {
				"regions": [
					{
						"id": "bottom",
						"verticalAlign": "bottom",
						"horizontalAlign": "center",
						"backgroundColor": "#000000",
						"padding": "-10 -10 -10 -10",
						"width": 620,
						"height": 50
					}
				]
			},
			"ads": {
				"servers": [
					{
						"type": "OpenX",
						"apiAddress": "http://localhost/openx/www/delivery/fc.php"
					}
				],
				"schedule": [
					{
						"zone": "2",
						"position": "pre-roll"
					},
					{
						"zone": "2",
						"position": "post-roll"
					},
					{
						"zone": "2",
						"position": "bottom",
						"width": 620,
						"height": 50,
						"startTime": "00:00:05",
						"duration": "15"
					}
				]
			},
			"debug": {
				"debugger": "firebug",
				"levels": "fatal, config, vast_template"
			}
		}
	}
];

// !important: parsing from a JSON object to a String to be used by swfobject later
flashvar_plugins = JSON.stringify(flashvar_plugins);
		
var flashvars = {
	file:flashvar_file, // remember this? it's a JSON object "disguised" as a String
	streamer:null, // this will not be needed if you already specified one in the "flashvar_file" JSON object
	controls:"auto",
	autoStart:false,
	mute:false,
	scaleMode:"lossyScale",
	background:"resources/vidBg.jpg",
	plugins:flashvar_plugins // again, this is a JSON object being "converted" into a String
};
		
var params = {
	loop:"false",
	menu:"false",
	quality:"high",
	wmode:"window",
	bgcolor:"#000000",
	allowScriptAccess:"always",
	allowFullScreen:"true"
};
		
var attributes = {
	id:"sephPlayer",
	name:"sephPlayer"
};

swfobject.embedSWF("sephPlayer.swf","div_containing_flash","620","402","9.0.0","scripts/expressInstall.swf",flashvars,params,attributes);
```