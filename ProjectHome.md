# About the Project #
<p>SephPlayer is a Flash-based Media Player for use on the web (embedded to an HTML document or used inside other Flash projects). Being developed out of pure hobby, SephPlayer might not be the best, all-round solution you may find out there in the market (<a href='http://flowplayer.org/'>FlowPlayer</a>, <a href='http://www.longtailvideo.com/players'>JWPlayer</a>, etc.), but it would be my honor to see it actually being used somewhere on the www, hear comments and feedback so that I could further enhance the player.<p>

<del>= Forewords =<br>
Please notice that this Google Code page currently only contains the Wiki pages and Issue Tracking for SephPlayer. The source code itself is <b>not yet available to be put on public</b> (it's a real mess on my hard-drive now actually). I would love to express my apology for this, and thank you for your understanding.<br></del><br />

<p>Below is a few useful links to help you get started quickly with SephPlayer:</p>
<ol>
<li><a href='https://code.google.com/p/sephplayer/wiki/EmbeddingSephPlayer'>Embedding SephPlayer</a></li>
<li><a href='https://code.google.com/p/sephplayer/wiki/Flashvars'>SephPlayer Flashvars</a></li>
<li><a href='http://code.google.com/p/sephplayer/wiki/CompilationInstruction'>Compilation Instruction</a></li>
</ol>
<br />

<h1>Main features</h1>
<ul><li>Streams video and audio contents (FLV, MP3<code>(1)</code> and H264-encoded files<code>(2)</code>) progressively with HTTP protocol or real-time with RTMP protocol<br>
</li><li>Supports secured server connections with custom connect params out of the box<br>
</li><li>Highly scalable and expandable, custom skins can be loaded dynamically<br>
</li><li>Can be embedded into an HTML webpage as well as loaded into a Flash <a href='http://livedocs.adobe.com/flash/9.0/ActionScriptLangRefV3/flash/display/DisplayObject.html'>DisplayObject</a>
</li><li>Comes with a wide range of <a href='http://en.wikipedia.org/wiki/JavaScript'>JavaScript</a> and <a href='http://en.wikipedia.org/wiki/ActionScript'>ActionScript</a> API supports<br>
</li><li>Where needed, flashvars can be <a href='http://www.json.org/'>JSON</a> objects, making the embedding of SephPlayer simpler  than many other Flash Media Players<br>
<br /></li></ul>

<h1>Releases</h1>
<ul><li>Current stable release is 2.10.1 build 1<br>
<br /></li></ul>

<h1>Todo's</h1>
<ul><li>Complete documentation for Plugins<br>
</li><li>Add the feature to play audio files (MP3 for the most part)<br>
<br /></li></ul>

<h1>About the Author</h1>
<p>SephPlayer is written and maintained by <b><a href='http://khangdinh.wordpress.com/'>Khang Dinh</a></b> (Dinh Pham Khang), an <b>Interactive Designer</b>, <b>Front-End Developer</b>, and an <b><a href='http://en.wikipedia.org/wiki/ActionScript'>ActionScript</a> Developer</b>. He started working on SephPlayer when he was working for <a href='http://pvac.vn'>PVAC</a>, an Advertisement and Communication Company, where he joined a decent amount of projects involving writing <a href='http://en.wikipedia.org/wiki/ActionScript'>ActionScript</a> codes, especially interactive webs, applications and media streaming projects (VOD/Live) with focuses on both server and client sides.</p>

<p>Flash is Khang's <del>biggest and</del> initial enthusiasm. Other than that he also enjoys working with computer graphics, animations, visual and audio effects, 3D modelling and animations, building Java applications and PHP/HTML/CSS websites.</p>
<br />
<hr />
<i>(1) MP3 playing is not yet supported, and is already on the TODO list!</i><br />
<i>(2) Using the appropriate streaming server. As of Dec 24th, 2010, <a href='http://osflash.org/red5'>RED5 Open Source Flash Server</a> still does not support H264 streaming completely.</i>