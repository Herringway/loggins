module loggins;
public {
	import common;
	import targets.filelogger;
	import targets.htmllogger;
	import targets.pushlogger;
	import targets.consolelogger;
	version(journald) import targets.journaldlogger;
	version(G15) import targets.g15logger;
}
version(unittest) {
	HTMLLogger unitTestHTMLLogger;
	static this() {
		addLogger(new ConsoleLogger).minLevel = LoggingLevel.Debug;
		unitTestHTMLLogger = new HTMLLogger("unittest.html");
		addLogger(unitTestHTMLLogger).minLevel = LoggingLevel.Trace;
	}
	static ~this() {
		delete(unitTestHTMLLogger);
	}
}
public enum Loggers {Console, HTML, Journald, G15};
private shared Logger[] instances;
private shared LogEntry[] lineBuffer = [];
public T addLogger(T)(T newLogger) {
	instances ~= cast(shared T)newLogger;
	return newLogger;
}
public void Log(string file = __FILE__, int inLine = __LINE__)(LoggingLevel level, LoggingFlags mode, string text, string title = "") nothrow @trusted {
	import core.thread : Thread;
	scope(failure) return;

	auto line = LogEntry();
	line.level = level;
	line.msg = text;
	line.flags = mode;
	try {
		line.thread = Thread.getThis();
	} catch (Exception) { }
	line.file = file;
	line.line = inLine;
	line.title = title;
	synchronized {
		line.time = getTime();
		if (instances.length == 0)
			lineBuffer ~= cast(shared)line;
		else {
			foreach (bufferedLine; lineBuffer)
				Log(cast(LogEntry)bufferedLine);
			lineBuffer = [];
			Log(line);
		}
	}
}
public void Log(LogEntry entry) nothrow @trusted {
	foreach (instance; instances)
		instance.Log(entry);
}
private auto getTime() nothrow @trusted {
	import std.datetime : Clock, SysTime;
	scope(failure) return SysTime();
	return Clock.currTime();
}
private void LogC(string file = __FILE__, int line = __LINE__, T...)(LoggingLevel level, LoggingFlags mode, string fmt, T args) nothrow @trusted {
	import std.string : format;
	try{
		Log!(file,line)(level, mode, format(fmt, args));
	} catch (Exception e) { try { Log!(file, line)(LoggingLevel.Error, mode, format("Error formatting %s at %s:%d", fmt, file, line)); } catch (Exception) { } }
}
public void LogError(LoggingFlags mode = LoggingFlags.NoCut | LoggingFlags.NewLine, string file = __FILE__, int line = __LINE__, T...)(string fmt, T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Error, mode, fmt, args);
}
public void LogWarning(LoggingFlags mode = LoggingFlags.NoCut | LoggingFlags.NewLine, string file = __FILE__, int line = __LINE__, T...)(string fmt, auto ref T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Warning, mode, fmt, args);
}
public void LogResults(LoggingFlags mode = LoggingFlags.NewLine, string file = __FILE__, int line = __LINE__, T...)(string fmt, auto ref T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Results, mode, fmt, args);
}
public void LogInfo(LoggingFlags mode = LoggingFlags.NewLine, string file = __FILE__, int line = __LINE__, T...)(string fmt, auto ref T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Info, mode, fmt, args);
}
public void LogDiagnostic(LoggingFlags mode = LoggingFlags.NewLine, string file = __FILE__, int line = __LINE__, T...)(string fmt, T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Diagnostic, mode, fmt, args);
}
public void LogDebug(LoggingFlags mode = LoggingFlags.NewLine, string file = __FILE__, int line = __LINE__, T...)(string fmt, T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Debug, mode, fmt, args);
}
public void LogDebugV(LoggingFlags mode = LoggingFlags.NewLine, string file = __FILE__, int line = __LINE__, T...)(string fmt, T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.VerboseDebug, mode, fmt, args);
}
public void LogTrace(LoggingFlags mode = LoggingFlags.NewLine, string file = __FILE__, int line = __LINE__, T...)(string fmt, T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Trace, mode, fmt, args);
}
public void LogException(LoggingFlags mode = LoggingFlags.NewLine, string file = __FILE__, int line = __LINE__, T...)(Exception e, string fmt, T args) nothrow @trusted {
	LogError!mode(fmt, args);
	LogDebug!(LoggingFlags.NoCut)("Thrown from %s:%s", e.file, e.line);
	scope(failure) return;
	LogDebug!(LoggingFlags.NoCut)(e.info.toString());
}
class LimitLogger : Logger {
	shared Logger wrappedLogger;
	private LoggingLevel outputLevel = LoggingLevel.Info;
	private LoggingLevel maxLevel;
	public void init(string params) nothrow @safe pure { }
	public @property LoggingLevel minLevel(LoggingLevel inLevel) @safe nothrow pure {
		return outputLevel = inLevel;
	}
	shared synchronized public void Log(LogEntry line) nothrow @trusted {
		if ((line.level < outputLevel) || (line.level > maxLevel))
			return;
		wrappedLogger.Log(line);
	}
	this(shared Logger inWrap, LoggingLevel inMax) nothrow @safe pure {
		wrappedLogger = inWrap;
		maxLevel = inMax;
	}
}