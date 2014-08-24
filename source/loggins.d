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
alias LogError		= LogFunction!(LoggingLevel.Error);
alias LogWarning	= LogFunction!(LoggingLevel.Warning);
alias LogResults	= LogFunction!(LoggingLevel.Results);
alias LogInfo		= LogFunction!(LoggingLevel.Info);
alias LogDiagnostic	= LogFunction!(LoggingLevel.Diagnostic);
alias LogDebug		= LogFunction!(LoggingLevel.Debug);
alias LogDebugV		= LogFunction!(LoggingLevel.VerboseDebug);
alias LogTrace 		= LogFunction!(LoggingLevel.Trace);
template LogFunction(LoggingLevel level) {
	void LogFunction(string file = __FILE__, int line = __LINE__, T...)(string fmt, T args) nothrow @trusted {
		LogFunction!(file,line)(true, fmt, args);
	}
	void LogFunction(string file = __FILE__, int line = __LINE__, T...)(LoggingFlags mode, string fmt, T args) nothrow @trusted {
		LogFunction!(file,line)(mode, true, fmt, args);
	}
	void LogFunction(string file = __FILE__, int line = __LINE__, T...)(bool expr, string fmt, T args) nothrow @trusted {
		LoggingFlags mode = LoggingFlags.NewLine;
		static if (level >= LoggingLevel.Warning)
			mode |= LoggingFlags.NoCut;
		LogFunction!(file,line)(mode, expr, fmt, args);
	}
	void LogFunction(string file = __FILE__, int line = __LINE__, T...)(LoggingFlags mode, bool expr, string fmt, T args) nothrow @trusted {
		import std.string : format;
		import std.exception : collectException;
		if (expr) {
			try {
				Log!(file,line)(level, mode, format(fmt, args));
			} catch (Exception e) { collectException(Log!(file, line)(LoggingLevel.Error, mode, format("Error formatting %s at %s:%d", fmt, file, line))); }
		}
	}
}
public void LogException(LoggingFlags mode = LoggingFlags.NewLine, string file = __FILE__, int line = __LINE__, T...)(Exception e, string fmt, T args) nothrow @trusted {
	import std.exception : collectException;
	LogError(mode, fmt, args);
	LogDebug(LoggingFlags.NoCut, "Thrown from %s:%s", e.file, e.line);
	collectException(LogDebug(LoggingFlags.NoCut, e.info.toString()));
}