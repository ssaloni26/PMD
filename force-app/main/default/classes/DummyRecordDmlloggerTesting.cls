@IsTest
public class DummyRecordDmlloggerTesting{
    public static Map<Id, String> dummyLogs = new Map<Id, String>();
    public static List<EventLogFile> getDummyLogs(Date logDate) {
        List<EventLogFile> dummyLogs = new List<EventLogFile>();

        dummyLogs.add(new EventLogFile(
            Id = Id.valueOf('0ATgL000001i5lpWAA'),
            EventType = 'DatabaseSave',
            LogDate = Datetime.newInstance(logDate.year(), logDate.month(), logDate.day(), 10, 0, 0)
        ));

        dummyLogs.add(new EventLogFile(
            Id = Id.valueOf('0ATgL000001i2ymWAA'),
            EventType = 'DatabaseSave',
            LogDate = Datetime.newInstance(logDate.year(), logDate.month(), logDate.day(), 15, 0, 0)
        ));

        return dummyLogs;
    }
}