module targets.journaldlogger;
private import common;
version(linux) {
	extern(C) int sd_journal_print(int priority, const char* format, ...) nothrow;
} else {
	int sd_journal_print(int priority, const char* format, ...) nothrow {
		return 0;
	}
}
class JournaldLogger : Logger {
	public @property LoggingLevel minLevel(LoggingLevel inLevel) nothrow @safe pure {
		return outputLevel = inLevel;
	}
	private LoggingLevel outputLevel = LoggingLevel.Info;
	shared void Log(LogEntry line) nothrow {
		scope(failure) return;
		version(linux) {
			import std.string : toStringz;
			synchronized {
				sd_journal_print(line.RFC5424Priority, "%s", line.msg.toStringz());
			}
		}
	}
}