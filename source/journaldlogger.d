private import common;
version(linux) {
	pragma(lib, "systemd-journal");
	extern(C) int sd_journal_print(int priority, const char* format, ...) nothrow;
}
class JournaldLogger : Logger {
	public @property LoggingLevel minLevel(LoggingLevel inLevel) {
		return outputLevel = inLevel;
	}
	private LoggingLevel outputLevel = LoggingLevel.Info;
	void init(string param) nothrow { }
	void Log(LogEntry line) nothrow {
		version(linux) {
			int priority = 6;
			final switch (line.level) {
				case LoggingLevel.UnitTest: priority = 7; break;
				case LoggingLevel.VerboseDebug: priority = 7; break;
				case LoggingLevel.Debug: priority = 7; break;
				case LoggingLevel.DebugImportant: priority = 7; break;
				case LoggingLevel.Info: priority = 6; break;
				case LoggingLevel.Warning: priority = 4; break;
				case LoggingLevel.Error: priority = 3; break;
			}
			sd_journal_print(priority, "%s", line.msg.toStringz());
		}
	}
}