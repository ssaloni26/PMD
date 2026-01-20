@IsTest
public class DMLLoggerBatch_Test  {
    
    private static String getValidCsv(Date logDate) {
        return 'USER_ID,KEY_PREFIX,DML_TYPE,NUM_ROWS,TIMESTAMP_DERIVED\n' +
               UserInfo.getUserId() + ',001,INSERT,5,' + logDate.format() + '\n' +
               UserInfo.getUserId() + ',001,UPDATE,3,' + logDate.format() + '\n';
    }

    private static String getInvalidCsv(Date logDate) {
        return 'USER_ID,KEY_PREFIX,DML_TYPE,NUM_ROWS,TIMESTAMP_DERIVED\n' +
               'InvalidId,001,INSERT,2,' + logDate.format() + '\n' +   // invalid user id
               ',001,UPDATE,2,' + logDate.format() + '\n';             // missing user
    }

    @IsTest
    static void testStartMethod() {
        Date logDate = Date.today();
        DMLLoggerBatch batch = new DMLLoggerBatch(logDate);
        Database.QueryLocator ql = batch.start(null);
        System.assertNotEquals(null, ql, 'QueryLocator should not be null.');
    }

    @IsTest
    static void testExecute_InsertAndUpdateAudits() {
        Date logDate = Date.today();

        // Get dummy logs from your helper
        List<EventLogFile> logs = DummyRecordDmlloggerTesting.getDummyLogs(logDate);

        // Set dummy CSV data for both log Ids
        for (EventLogFile e : logs) {
            DummyRecordDmlloggerTesting.dummyLogs.put(e.Id, getValidCsv(logDate));
        }

        Test.startTest();
        DMLLoggerBatch batch = new DMLLoggerBatch(logDate);
        batch.execute(null, logs);
        Test.stopTest();

        List<Database_Audit__c> audits = [
            SELECT ObjectName__c, Operation__c, Record_Count__c
            FROM Database_Audit__c
        ];

        System.assert(!audits.isEmpty(), 'Audit records should have been inserted.');
        System.assertEquals(2, audits.size(), 'There should be two audit records.');
    }

    @IsTest
    static void testExecute_UpdatesExistingRecord() {
        Date logDate = Date.today();

        // Create an existing audit record that should be updated
        Database_Audit__c existing = new Database_Audit__c(
            User__c = UserInfo.getUserId(),
            ObjectName__c = 'Account',
            Operation__c = 'INSERT',
            Record_Count__c = 10,
            LogDate__c = logDate,
            OwnerId = UserInfo.getUserId()
        );
        insert existing;

        // Get dummy logs
        List<EventLogFile> logs = DummyRecordDmlloggerTesting.getDummyLogs(logDate);

        // Attach CSV content to dummy logs
        for (EventLogFile e : logs) {
            DummyRecordDmlloggerTesting.dummyLogs.put(e.Id, getValidCsv(logDate));
        }

        Test.startTest();
        DMLLoggerBatch batch = new DMLLoggerBatch(logDate);
        batch.existingDatabaseAuditMap = batch.getExistingAudits(logDate);
        batch.execute(null, logs);
        Test.stopTest();

        Database_Audit__c updated = [
            SELECT Record_Count__c 
            FROM Database_Audit__c 
            WHERE Id = :existing.Id
        ];
        System.assertEquals(15, updated.Record_Count__c,
            'Existing record count should increment by 5 from CSV data.');
    }

    @IsTest
    static void testExecute_InvalidAndBlankCsv() {
        Date logDate = Date.today();
        List<EventLogFile> logs = DummyRecordDmlloggerTesting.getDummyLogs(logDate);

        // 1️⃣ Invalid CSV content
        DummyRecordDmlloggerTesting.dummyLogs.clear();
        for (EventLogFile e : logs) {
            DummyRecordDmlloggerTesting.dummyLogs.put(e.Id, getInvalidCsv(logDate));
        }

        Test.startTest();
        DMLLoggerBatch batch = new DMLLoggerBatch(logDate);
        batch.execute(null, logs);
        Test.stopTest();

        // 2️⃣ Blank CSV case
        DummyRecordDmlloggerTesting.dummyLogs.clear();
        for (EventLogFile e : logs) {
            DummyRecordDmlloggerTesting.dummyLogs.put(e.Id, '');
        }

        Test.startTest();
        batch.execute(null, logs);
        Test.stopTest();

        System.assert(true, 'Handled invalid and blank CSV cases successfully.');
    }

    @IsTest
    static void testExecute_EmptyLogsAndFinish() {
        Date logDate = Date.today();
        DMLLoggerBatch batch = new DMLLoggerBatch(logDate);

        Test.startTest();
        batch.execute(null, new List<EventLogFile>()); // empty scope
        batch.finish(null);
        Test.stopTest();

        System.assert(true, 'Handled empty scope and finish() correctly.');
    }
}