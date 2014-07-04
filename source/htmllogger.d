private {
	import common;
	import std.stdio : File;
	import std.string : format;
	import std.array : appender;
	import std.traits : EnumMembers;
}
class HTMLLogger : Logger {
	File handle;
	private LoggingLevel outputLevel = LoggingLevel.Info;

	public @property LoggingLevel minLevel(LoggingLevel inLevel) @safe {
		return outputLevel = inLevel;
	}
	this(string logpath) @trusted nothrow {
		scope(failure) return;
		handle = File(logpath, "w");
		handle.writeln(`<html>
	<head>
		<title>HTML Log</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<style content="text/css">
			.Trace        { position: relative; color: lightgray; }
			.VerboseDebug { position: relative; color: lightgray; }
			.Debug        { position: relative; color: gray; }
			.Diagnostic   { position: relative; color: gray; }
			.Info         { position: relative; color: black; }
			.Results      { position: relative; color: black; }
			.Warning      { position: relative; color: darkorange; }
			.Error        { position: relative; color: red; }
			body          { font-family: monospace; font-size: 10pt; margin: 0px; }

			.log          { margin: 0px 10pt 36px 10pt; }

			time {
				display: inline-block;
				vertical-align: top;
				width: 170pt;
			}
			div.threadName {
				display: inline-block;
				vertical-align: top;
				width: 100pt;
			}
			div.message {
				width: calc(100% - 270pt);
				display: inline-block;
			}
			form.menubar {
				position: fixed;
				bottom: 0px;
				padding: 4pt; 
				width: 100%;
				background-color: lightgray;
				z-index: 1;
				margin: 0px;
			}
		</style>
		<script language="JavaScript">
			function enableStyle(i){
				var style = document.styleSheets[0].cssRules[i].style;
				style.display = "block";
			}

			function disableStyle(i){
				var style = document.styleSheets[0].cssRules[i].style;
				style.display = "none";
			}

			function updateLevels(){
				var sel = document.getElementById("Level");
				var level = sel.value;
				for( i = 0; i < level; i++ ) disableStyle(i);
				for( i = level; i < 5; i++ ) enableStyle(i);
			}
		</script>
	</head>
	<body onLoad="updateLevels();">
		<form class="menubar">
			Minimum Log Level:
			<select id="Level" onChange="updateLevels()">`);
		foreach (level; [EnumMembers!LoggingLevel])
			handle.writefln(`				<option value="%d">%1$s</option>`, level);
		handle.writeln(
`			</select>
		</form>
		<div class="log">`);
		handle.flush();
	}
	@trusted nothrow ~this() {
		scope(failure) return;
		if (handle.isOpen) {
			handle.write("\n\t\t</div>\n\t</body>\n</html>");
			handle.flush();
			handle.close();
		}
	}
	void Log(LogEntry line) nothrow @trusted {
		import std.array;
		scope(failure) return;
		string threadname = "";
		if (line.thread)
			threadname = format(`<div class="threadName">%s</div>`, line.thread.name);
		handle.writefln(`		<div class="%s"><time datetime="%s">%s</time>%s<div class="message">%s</div></div>`, line.level, line.time.toISOExtString(), line.time.toSimpleString(), threadname, htmlEscape(line.msg).replace("\n", "<br />"));
		handle.flush();
	}
}
char[] htmlEscape(inout(char[]) text) @trusted nothrow {
	auto output = appender!(char[])();
	foreach (character; text) {
		switch (character) {
			default: output ~= character; break;
			case '&': output ~= "&amp;"; break;
			case '<': output ~= "&lt;"; break;
			case '>': output ~= "&gt;"; break;
		}
	}
	return output.data;
}