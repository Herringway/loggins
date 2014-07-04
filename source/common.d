private import std.datetime : SysTime;
private import core.thread : Thread;
interface Logger {
	public void Log(LogEntry line) nothrow @safe;
}
struct LogEntry {
	LoggingLevel level;
	string msg;
	SysTime time;
	statusMode flags;
	string file;
	string mod;
	string func;
	int line;
	Thread thread;
	string title;
}

public enum LoggingLevel {Trace, VerboseDebug, Debug, Diagnostic, Info, Results, Warning, Error};
public enum statusMode {None = 0, Rewind = 1, NoCut = 2};

version(unittest) {
	public const LoggingLevel defaultMinLevel = LoggingLevel.Trace;
} else {
	debug public const LoggingLevel defaultMinLevel = LoggingLevel.Debug;
	else public const LoggingLevel defaultMinLevel = LoggingLevel.Info;
}