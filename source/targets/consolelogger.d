module targets.consolelogger;
private import common;
class ConsoleLogger : Logger {
	import targets.filelogger, std.stdio : stderr, stdout;
	private FileLogger errLog;
	private FileLogger outLog;
	private LoggingLevel outputLevel = defaultMinLevel;
	private bool wasRewind = false;

	private static uint defaultConsoleWidth = 80;
	final:
	invariant() {
		assert(errLog !is null, "stderr went away!");
		assert(outLog !is null, "stdout went away!");
	}
	this() {
		version(Windows) {
			import core.sys.windows.windows;
			SetConsoleOutputCP(65001); // For unicode output on windows, linux doesn't require this
			//Does not seem to work in powershell, only cmd.exe...
		}
		errLog = new FileLogger(stderr);
		outLog = new FileLogger(stdout);
		errLog.minLevel = defaultMinLevel;
		outLog.minLevel = defaultMinLevel;
	}
	public @property LoggingLevel minLevel(LoggingLevel inLevel) @safe nothrow pure {
		errLog.minLevel = inLevel;
		outLog.minLevel = inLevel;
		return outputLevel = inLevel;
	}
	shared public void Log(LogEntry line) nothrow @trusted {
		scope(failure) return;
		auto output = outLog;
		if (line.level == LoggingLevel.Error)
			output = errLog;
		if (((line.flags & LoggingFlags.NoCut) == 0) && (consoleWidth > 0) && (line.msg.length >= consoleWidth-1)) {
			auto msg = line.msg[0..consoleWidth-2].dup;
			msg[consoleWidth-5..consoleWidth-2] = '.';
			line.msg = msg.idup;
		}
		if ((line.flags & LoggingFlags.Rewind) != 0) {
			clearline(output, line.level, consoleWidth);
			wasRewind = true;
		} else if (wasRewind) {
			stdout.writeln();
			wasRewind = false;
		}
		output.Log(line);
	}
	shared private void clearline(shared FileLogger output, LoggingLevel level, ulong linesize) nothrow @safe {
		scope(failure) return;
		if (linesize == 0)
			return;
		LogEntry line;
		line.level = level;
		version(Windows) {
			foreach (k; 0..linesize) //can't backspace beyond beginning of line
				line.msg ~= "\b \b";
		}
		version(Posix) {
			line.msg ~= "\033[2K\033[0E";
		}
		output.Log(line);
	}
	public static @property size_t consoleWidth() @trusted nothrow out(result) {
		assert(result > 0, "Console width zero or less!");
	} body {
		version(Posix) {
			import core.sys.posix.sys.ioctl;
			import std.stdio : stdin;
			winsize w;
			try {
				errnoEnforce(ioctl(stdin.fileno(), TIOCGWINSZ, &w) == 0, "Fetching winsize failed");
				return w.ws_col;
			} catch (ErrnoException e) {
				stderr.writeln(e);
				return defaultConsoleWidth;
			}
		}
		else version(Windows) { 
			import core.sys.windows.windows; 
			CONSOLE_SCREEN_BUFFER_INFO csbiInfo; 
			GetConsoleScreenBufferInfo(GetStdHandle(-11), &csbiInfo);
			return csbiInfo.dwMaximumWindowSize.X;
		} else
			return defaultConsoleWidth;
	}
}