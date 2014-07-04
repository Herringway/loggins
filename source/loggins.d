module loggins;
private import std.datetime : Clock;
public {
	import common;
	import filelogger;
	import htmllogger;
	import pushlogger;
	version(journald) import journaldlogger;
	version(G15) import g15logger;
}

version(unittest) static this() {
	addLogger(new FileLogger(std.stdio.stdout)).minLevel = LoggingLevel.Debug;
	addLogger(new HTMLLogger("unittest.html")).minLevel = LoggingLevel.Trace;
}
public enum Loggers {Console, HTML, Journald, G15};
private Logger[] instances;
public T addLogger(T)(T newLogger) {
	instances ~= newLogger;
	return newLogger;
}
public void Log(string file = __FILE__, int inLine = __LINE__)(LoggingLevel level, statusMode mode, string text, string title = "") nothrow @trusted {
	auto line = LogEntry();
	line.level = level;
	line.msg = text;
	line.flags = mode;
	line.time = getTime();
	try {
		line.thread = Thread.getThis();
	} catch (Exception) { }
	line.file = file;
	line.line = inLine;
	line.title = title;
	Log(line);
}
public void Log(LogEntry entry) nothrow @trusted {
	foreach (instance; instances)
		instance.Log(entry);
}
private SysTime getTime() nothrow @trusted {
	scope(failure) return SysTime();
	return Clock.currTime();
}
private void LogC(string file = __FILE__, int line = __LINE__, T...)(LoggingLevel level, statusMode mode, string fmt, T args) nothrow @trusted {
	try{
		Log!(file,line)(level, mode, format(fmt, args));
	} catch (Exception e) { try { Log!(file, line)(LoggingLevel.Error, mode, format("Error formatting %s at %s:%d", fmt, file, line)); } catch (Exception) { } }
}
public void LogError(statusMode mode = statusMode.NoCut, string file = __FILE__, int line = __LINE__, T...)(string fmt, T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Error, mode, fmt, args);
}
public void LogWarning(statusMode mode = statusMode.NoCut, string file = __FILE__, int line = __LINE__, T...)(string fmt, auto ref T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Warning, mode, fmt, args);
}
public void LogResults(statusMode mode = statusMode.None, string file = __FILE__, int line = __LINE__, T...)(string fmt, auto ref T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Results, mode, fmt, args);
}
public void LogInfo(statusMode mode = statusMode.None, string file = __FILE__, int line = __LINE__, T...)(string fmt, auto ref T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Info, mode, fmt, args);
}
public void LogDiagnostic(statusMode mode = statusMode.None, string file = __FILE__, int line = __LINE__, T...)(string fmt, T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Diagnostic, mode, fmt, args);
}
public void LogDebug(statusMode mode = statusMode.None, string file = __FILE__, int line = __LINE__, T...)(string fmt, T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Debug, mode, fmt, args);
}
public void LogDebugV(statusMode mode = statusMode.None, string file = __FILE__, int line = __LINE__, T...)(string fmt, T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.VerboseDebug, mode, fmt, args);
}
public void LogTrace(statusMode mode = statusMode.None, string file = __FILE__, int line = __LINE__, T...)(string fmt, T args) nothrow @safe {
	LogC!(file, line)(LoggingLevel.Trace, mode, fmt, args);
}
class LimitLogger : Logger {
	Logger wrappedLogger;
	private LoggingLevel outputLevel = LoggingLevel.Info;
	private LoggingLevel maxLevel;
	public void init(string params) nothrow @safe pure { }
	public @property LoggingLevel minLevel(LoggingLevel inLevel) @safe nothrow pure {
		return outputLevel = inLevel;
	}
	public void Log(LogEntry line) nothrow @trusted {
		if ((line.level < outputLevel) || (line.level > maxLevel))
			return;
		wrappedLogger.Log(line);
	}
	this(Logger inWrap, LoggingLevel inMax) nothrow @safe pure {
		wrappedLogger = inWrap;
		maxLevel = inMax;
	}
}