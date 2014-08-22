public interface Logger {
	public shared void Log(LogEntry line) nothrow @safe;
	public @property LoggingLevel minLevel(LoggingLevel inLevel) nothrow @safe pure;
}
package struct LogEntry {
	import std.datetime : SysTime;
	import core.thread : Thread;
	LoggingLevel level;
	string msg;
	SysTime time;
	logFlags flags;
	string file;
	string mod;
	string func;
	int line;
	Thread thread;
	string title;
	@property string source() {
		import std.string : format, split;
		import std.path : dirSeparator;
		return format("%s:%d", file.split(dirSeparator)[$-1], line);
	}
	@property RFC5424PriorityLevel RFC5424Priority() {
		final switch (level) {
			case LoggingLevel.Trace:		return RFC5424PriorityLevel.Debug;
			case LoggingLevel.VerboseDebug:	return RFC5424PriorityLevel.Debug;
			case LoggingLevel.Debug:		return RFC5424PriorityLevel.Debug;
			case LoggingLevel.Info:			return RFC5424PriorityLevel.Informational;
			case LoggingLevel.Results:		return RFC5424PriorityLevel.Informational;
			case LoggingLevel.Diagnostic:	return RFC5424PriorityLevel.Notice;
			case LoggingLevel.Warning:		return RFC5424PriorityLevel.Warning;
			case LoggingLevel.Error:		return RFC5424PriorityLevel.Error;
			case LoggingLevel.Critical:		return RFC5424PriorityLevel.Critical;
			case LoggingLevel.Fatal:		return RFC5424PriorityLevel.Alert;
			case LoggingLevel.Emergency:	return RFC5424PriorityLevel.Emergency;
		}
	}
}
public enum RFC5424PriorityLevel : ubyte {Emergency, Alert, Critical, Error, Warning, Notice, Informational, Debug };
public enum LoggingLevel { Trace, VerboseDebug, Debug, Diagnostic, Info, Results, Warning, Error, Critical, Fatal, Emergency };
public enum LoggingFlags { None = 0, Rewind = 1, NoCut = 2, NewLine = 4 };
deprecated("Use LoggingLevel instead") alias logFlags = LoggingFlags;

version(unittest) {
	public const LoggingLevel defaultMinLevel = LoggingLevel.Trace;
} else {
	debug public const LoggingLevel defaultMinLevel = LoggingLevel.Debug;
	else public const LoggingLevel defaultMinLevel = LoggingLevel.Info;
}