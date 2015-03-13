# About Flashvars #

Please notice that JSON objects are acceptable for the **"file"** and **"plugins"** flashvars but have to be parsed into type **String** before being used as a flashvar value.

_To make it easy for most users, this page only lists the often-used flashvars. If you would love to see the full list, please browse the project's source code for the file "`seph.media.sephPlayer.utils.ConfigManager`"._

  1. file (can be a **String** or an **Object**)
  1. streamer (i.e.: rtmp://your\_streaming\_server\_domain[:port]/your\_streaming\_app[/your\_streaming\_app\_instance] - only used when content is to be streamed from a streaming media server)
  1. controls (**always|auto|none**)
  1. autoStart (**true|false**)
  1. mute (**true|false**)
  1. scaleMode (**showAll|exactFit|noScale|lossyScale**)
  1. background (can be a **String** or a **Flash HEX Color code**)
  1. plugins (an JSON object, or string representation of the JSON object, specifying the plugin information to load including "**name**", "**source**" and "**config**")
  1. skin (url to the **GUI file**. This is required for the player to operate properly. You can download the default skin file here: [SephPlayerDefaultSkin](https://code.google.com/p/sephplayer/downloads/detail?name=SephPlayerDefaultSkin.swf))
  1. overlay (a **String** to the image file served as the logo on top of the player)
  1. overlayPosition (**1|2|3|4**)