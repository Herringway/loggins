module targets.filelogger;
private import common;
class FileLogger : Logger {
	import std.stdio;
	private File output;
	public bool timestamps = false;
	private LoggingLevel outputLevel = defaultMinLevel;
	public @property LoggingLevel minLevel(LoggingLevel inLevel) @safe nothrow pure {
		return outputLevel = inLevel;
	}
	shared synchronized public void Log(LogEntry line) nothrow @trusted {
		import std.string : format;
		scope(failure) return;
		char[] msg;
		if (timestamps)
			msg ~= format("[%02d:%02d:%02d] ", line.time.hour, line.time.minute, line.time.second);
		msg ~= line.msg;
		if ((line.flags & LoggingFlags.NewLine) != 0)
			msg ~= "\n";
		synchronized {
			print(line.level, msg.idup);
		}
	}
	this(File outputFile) {
		output = outputFile;
	}
	this(string filename) {
		output = File(filename, "a");
	}
	shared protected void print(LoggingLevel level, string message) @trusted nothrow {
		if (level < outputLevel)
			return;
		scope(failure) return;
		(cast(File)output).write(message);
		(cast(File)output).flush();
	}
}