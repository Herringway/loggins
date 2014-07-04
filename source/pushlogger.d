private import common;
private import std.string : format;
private import std.stdio;
private import din;
public import din : pushService;
class PushLogger : Logger {
	private Din din;
	private string appName;
	public void Log(LogEntry line) nothrow @trusted {
		if (line.level != LoggingLevel.Results)
			return;
		scope(failure) return;
		auto notification = notification();
		notification.title = line.title;
		notification.message = line.msg;
		notification.apptitle = appName;
		notification.priority = 0;
		din.send(notification);
	}
	public void addNotifier(pushService service, string APIKey, string[] targets) {
		din.addNotifier(service, APIKey, targets);
	}
	public void addNotifier(pushService service, string[] targets) {
		din.addNotifier(service, targets);
	}
	this(string appname) {
		appName = appname;
		din = new Din();
	}
}