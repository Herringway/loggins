module loggins;
public {
	import common;
	import targets.filelogger;
	import targets.htmllogger;
	import targets.pushlogger;
	import targets.consolelogger;
	version(linux) import targets.journaldlogger;
	version(Have_lcdee) import targets.g15logger;
}
version(unittest) {
	HTMLLogger unitTestHTMLLogger;
	static this() {
		addLogger(new ConsoleLogger).minLevel = LoggingLevel.Debug;
		unitTestHTMLLogger = new HTMLLogger("unittest.html");
		addLogger(unitTestHTMLLogger).minLevel = LoggingLevel.Trace;
	}
	static ~this() {
		destroy(unitTestHTMLLogger);
	}
}
private shared Logger[] instances;
private shared LogEntry[] lineBuffer = [];
public T addLogger(T)(T newLogger) {
	instances ~= cast(shared T)newLogger;
	return newLogger;
}
private void Log(LoggingLevel level, LoggingFlags mode, string text, string file, int inLine, string title = "") nothrow @trusted {
	import core.thread : Thread;

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
				foreach (instance; instances)
					instance.Log(cast()bufferedLine);
			lineBuffer = [];
			foreach (instance; instances)
				instance.Log(line);
		}
	}
}
private auto getTime() nothrow @trusted {
	import std.datetime : Clock, SysTime;
	try {
		return Clock.currTime();
	} catch (Exception)
		return SysTime.min;
}
public void LogNotification(string file = __FILE__, int inLine = __LINE__, T...)(string title, string fmt, T args) {
	import std.string : format;
	try {
		Log(LoggingLevel.Results, LoggingFlags.NewLine, format(fmt, args), file, inLine, title);
	} catch (Exception e) {
		LogError("Error formatting format string: %s", e.msg);
	}
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
	void LogFunction(string file = __FILE__, int line = __LINE__, T...)(Exception e, string fmt, T args) nothrow @trusted {
		LoggingFlags mode = LoggingFlags.NewLine;
		static if (level >= LoggingLevel.Warning)
			mode |= LoggingFlags.NoCut;
		LogFunction!(file, line)(mode, e, fmt, args);
	}
	void LogFunction(string file = __FILE__, int line = __LINE__, T...)(LoggingFlags mode, Exception e, string fmt, T args) nothrow @trusted {
		import std.string : format;
		import std.exception : assumeWontThrow;
		assumeWontThrow(LogFunction!(file,line)(mode, true, format("%s: %s", fmt, e.msg), args));
		debug { //these don't produce useful output outside debug builds anyway
			LogFunction!(file,line)(true, "Thrown from %s:%s", e.file, e.line);
			assumeWontThrow(LogFunction!(file,line)(mode, true, "%s", e.info.toString()));
		}
	}
	void LogFunction(string file = __FILE__, int line = __LINE__, T...)(string fmt, T args) nothrow @trusted {
		static if (args.length > 0)
			LogFunction!(file,line)(true, fmt, args);
		else
			LogFunction!(file,line)(true, "%s", fmt);
	}
	void LogFunction(string file = __FILE__, int line = __LINE__, T...)(LoggingFlags mode, string fmt, T args) nothrow @trusted {
		LogFunction!(file, line)(mode, true, fmt, args);
	}
	void LogFunction(string file = __FILE__, int line = __LINE__, T...)(bool expr, string fmt, T args) nothrow @trusted {
		LoggingFlags mode = LoggingFlags.NewLine;
		static if (level >= LoggingLevel.Warning)
			mode |= LoggingFlags.NoCut;
		LogFunction!(file, line)(mode, expr, fmt, args);
	}
	void LogFunction(string file = __FILE__, int line = __LINE__, T...)(LoggingFlags mode, bool expr, string fmt, T args) nothrow @trusted {
		import std.string : format;
		import std.exception : ifThrown, assumeWontThrow;
		if (expr)
			assumeWontThrow({
				string msg;
				try {
					msg = format(fmt, args);
				} catch (Exception e) {
					msg = format("Error formatting %s at %s:%d\n%s", fmt, file, line, e);
				}
				Log(level, mode, msg, file, line);
			}());
	}
}
void setAssertLog() nothrow {
	import core.exception : assertHandler;
	assertHandler = &logAssertion;
}
void resetAssertLog() nothrow {
	import core.exception : assertHandler;
	assertHandler = null;
}
void logAssertion(string file, size_t line, string msg) nothrow {
	import core.exception : AssertError;
	import core.stdc.stdlib : exit;
	import core.runtime : defaultTraceHandler;
	resetAssertLog();
	scope(exit) setAssertLog();
	LogError("Assertion at %s:%s: %s", file, line, msg);
	try {
		foreach(t; defaultTraceHandler(null))
			LogError("%s", t);
	} catch (Exception) {
		assert(0, "Fatal error while logging assertion");
	}
	exit(1);
}