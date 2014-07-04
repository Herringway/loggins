private import common;
private import std.string : format;
private import std.stdio;
class FileLogger : Logger {
	private File output;
	public bool timestamps = false;
	private LoggingLevel outputLevel = defaultMinLevel;
	public void init(string params) nothrow { }
	public @property LoggingLevel minLevel(LoggingLevel inLevel) @safe {
		return outputLevel = inLevel;
	}
	public void Log(LogEntry line) nothrow @trusted {
		scope(failure) return;
		if (output.name == output.name.init)
			clearline(line.level, consoleWidth);
		char[] msg;
		if (timestamps)
			msg ~= format("[%02d:%02d:%02d] ", line.time.hour, line.time.minute, line.time.second);
		msg ~= line.msg;
		if (((line.flags & statusMode.NoCut) == 0) && (consoleWidth > 0) && (msg.length >= consoleWidth-1)) {
			msg = msg[0..consoleWidth-2];
			msg[consoleWidth-5..consoleWidth-2] = '.';
		}
		if (((line.flags & statusMode.Rewind) == 0) || (consoleWidth == 0) || (output.name != output.name.init))
			msg ~= "\n";
		print(line.level, msg.idup);
	}
	this(File outputFile = std.stdio.stdout) {
		output = outputFile;
	}
	this(string filename) {
		output = File(filename, "a");
	}
	private void clearline(LoggingLevel level, ulong linesize = 1000) nothrow @safe {
		scope(failure) return;
		if (consoleWidth == 0)
			return;
		version(Windows) {
			foreach (k; 0..linesize) //can't backspace beyond beginning of line
				print(level, "\b \b");
		}
		version(Posix) {
			print(level,"\033[2K\033[0E");
		}
	}
	public static @property size_t consoleWidth() nothrow @trusted {
		version(Posix) {
			import core.sys.posix.sys.ioctl;
			winsize w;
			ioctl(0, TIOCGWINSZ, &w);
			return w.ws_col;
		}
		else version(Windows) { 
			import core.sys.windows.windows; 
			CONSOLE_SCREEN_BUFFER_INFO csbiInfo; 
			GetConsoleScreenBufferInfo(GetStdHandle(-11), &csbiInfo);
			return csbiInfo.dwMaximumWindowSize.X;
		} else
			return 0;
	}
	unittest {
		assert(consoleWidth() > 0, "Console width zero or less!");
	}
	protected void print(LoggingLevel level, string message) @trusted nothrow {
		if (level < outputLevel)
			return;
		scope(failure) return;
		output.write(message);
		output.flush();
	}
}