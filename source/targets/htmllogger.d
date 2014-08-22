module targets.htmllogger;
private import common;

class HTMLLogger : Logger {
	private import std.stdio : File;
	File handle;
	private LoggingLevel outputLevel = LoggingLevel.Info;

	public @property LoggingLevel minLevel(LoggingLevel inLevel) @safe nothrow pure {
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
			.Trace        { position: relative; color: lightgray; display: none; }
			.VerboseDebug { position: relative; color: lightgray; display: none; }
			.Debug        { position: relative; color: gray; }
			.Diagnostic   { position: relative; color: gray; }
			.Info         { position: relative; color: black; }
			.Results      { position: relative; color: black; }
			.Warning      { position: relative; color: darkorange; }
			.Error        { position: relative; color: red; }
			body          { font-family: monospace; font-size: 10pt; margin: 0px; }

			.log          { margin: 0px 10pt 36px 10pt; }

			time, div.time {
				display: inline-block;
				vertical-align: top;
				width: 180pt;
			}
			div.source {
				display: inline-block;
				vertical-align: top;
				width: 200pt;
			}
			div.threadName {
				display: inline-block;
				vertical-align: top;
				width: 100pt;
			}
			div.message {
				width: calc(100% - 480pt);
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
			function init() {
				populateLevels();
				updateLevels();
			}
			function populateLevels() {
				var sel = document.getElementById("Level");
				var matches = [];
				for (var i = 0; i < document.styleSheets[0].cssRules.length; i++) {
					if (document.styleSheets[0].cssRules[i].selectorText == "body")
						break;
					matches.push(document.styleSheets[0].cssRules[i].selectorText.charAt(1).toUpperCase() + document.styleSheets[0].cssRules[i].selectorText.substring(2));
				}
 				for (var i = 0; i < matches.length; i++) {
 					var option = document.createElement("option");
 					option.textContent = matches[i];
 					option.value = i;
 					sel.appendChild(option);
 				}
 				sel.selectedIndex = 2;
			}
			window.onload = init;
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
	<body>
		<form class="menubar">
			Minimum Log Level:
			<select id="Level" onChange="updateLevels()">
			</select>
		</form>
		<div class="log">
		<div style="position: relative;"><div class="time">Time</div><div class="source">Source</div><div class="threadName">Thread</div><div class="message">Message</div></div>`);
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
	shared void Log(LogEntry line) nothrow @trusted {
		import std.string : format;
		import std.array;
		scope(failure) return;
		string writestr = "";
		if (line.thread)
			writestr = format(`		<div class="%s"><time datetime="%s">%s</time><div class="source">%s</div><div class="threadName">%s</div><div class="message">%s</div></div>`, line.level, line.time.toISOExtString(), line.time.toSimpleString(), line.source, line.thread.name, htmlEscape(line.msg).replace("\n", "<br />"));
		else
			writestr = format(`		<div class="%s"><time datetime="%s">%s</time><div class="source">%s</div><div class="threadName">&nbsp;</div><div class="message">%s</div></div>`, line.level, line.time.toISOExtString(), line.time.toSimpleString(), line.source, htmlEscape(line.msg).replace("\n", "<br />"));
		synchronized { 
			(cast(File)handle).writeln(writestr);
			(cast(File)handle).flush();
		}
	}
}
private char[] htmlEscape(inout(char[]) text) @trusted nothrow {
	import std.string : format;
	import std.array : appender;
	auto output = appender!(char[])();
	foreach (character; text) {
		switch (character) {
			default: output ~= character; break;
			case 0: .. case 9:
			case 11: .. case 13:
			case 14: .. case 31:
				try {
					output ~= format("&#%d", cast(uint)character); 
				} catch (Exception) {} 
				break;
			case '&': output ~= "&amp;"; break;
			case '<': output ~= "&lt;"; break;
			case '>': output ~= "&gt;"; break;
		}
	}
	return output.data;
}