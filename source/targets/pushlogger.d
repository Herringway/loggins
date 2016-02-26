module targets.pushlogger;
private import common;
public import din : PushService;
class PushLogger : Logger {
	private import din : Notification, Din;
	private Din din;
	private string appName;
	public @property LoggingLevel minLevel(LoggingLevel inLevel) nothrow @safe pure { return LoggingLevel.Results; }
	shared synchronized public void Log(LogEntry line) nothrow @trusted {
		if (line.level != LoggingLevel.Results)
			return;
		scope(failure) return;
		auto notification = Notification();
		notification.title = line.title;
		notification.message = line.msg;
		notification.appTitle = appName;
		notification.priority = 0;
		(cast(Din)din).send(notification);
	}
	public void addNotifier(PushService service, string APIKey, string[] targets) {
		din.addNotifier(service, APIKey, targets);
	}
	public void addNotifier(PushService service, string[] targets) {
		din.addNotifier(service, targets);
	}
	this(string appname) {
		appName = appname;
		din = new Din();
	}
}