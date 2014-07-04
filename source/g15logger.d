import G15;
class G15Logger : Logger {
	private LoggingLevel outputLevel = LoggingLevel.Info;
	private wstring name = "LOGGINS";
	LogiLCD lcdInstance;

	public @property LoggingLevel minLevel(LoggingLevel inLevel) {
		return outputLevel = inLevel;
	}
	void init(string param) nothrow @safe { 
		scope(failure) return;
		name = to!wstring(param);
	}
	void Log(LogEntry line) nothrow @safe {
		scope(failure) return;
		if (lcdInstance is null)
			lcdInstance = new LogiLCD(name.idup);
		if (line.level < outputLevel)
			return;

		if (lcdInstance.mono) {// max len: 28?
			foreach (id, ref str; lcdInstance.mono.strings[0..$-1])
				str = lcdInstance.mono.strings[id+1];
			{
				scope(failure) lcdInstance.mono.strings[$-1] = "";
				lcdInstance.mono.strings[$-1] = to!wstring(line.msg);
			}
		}
		if (lcdInstance.color) {
			foreach (id, ref str; lcdInstance.color.strings[0..$-1])
				str = lcdInstance.color.strings[id+1];
			foreach (id, ref color; lcdInstance.color.stringColors[0..$-1])
				color = lcdInstance.color.stringColors[id+1];
			{
				scope(failure) lcdInstance.color.strings[$-1] = "";
				lcdInstance.color.strings[$-1] = to!wstring(line.msg);
				switch (line.level) {
					case LoggingLevel.Trace:		lcdInstance.color.stringColors[$-1] = 0xFFE0E0E0; break;
					case LoggingLevel.VerboseDebug: lcdInstance.color.stringColors[$-1] = 0xFFE0E0E0; break;
					case LoggingLevel.Debug:		lcdInstance.color.stringColors[$-1] = 0xFF808080; break;
					case LoggingLevel.Diagnostic:	lcdInstance.color.stringColors[$-1] = 0xFF808080; break;
					case LoggingLevel.Info:			lcdInstance.color.stringColors[$-1] = 0xFFFFFFFF; break;
					case LoggingLevel.Warning:		lcdInstance.color.stringColors[$-1] = 0xFFE08000; break;
					case LoggingLevel.Error:		lcdInstance.color.stringColors[$-1] = 0xFFFF0000; break;
					default:						lcdInstance.color.stringColors[$-1] = 0xFFFFFFFF; break;
				}
			}
		}
		lcdInstance.update();
	}
}
