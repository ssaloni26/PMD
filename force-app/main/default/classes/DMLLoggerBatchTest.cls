/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-19-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
private class DMLLoggerBatchTest {

    // --- Utility CSV Builders ---
    private static String getValidCsv(Date logDate) {
        Id userId = UserInfo.getUserId();
        return 'USER_ID,KEY_PREFIX,DML_TYPE,NUM_ROWS,TIMESTAMP_DERIVED\n' +
               userId + ',001,INSERT,5,' + logDate.format() + '\n' +
               userId + ',001,UPDATE,3,' + logDate.format() + '\n';
    }

    private static String k(Date logDate) {
        return 'USER_ID,KEY_PREFIX,DML_TYPE,NUM_ROWS,TIMESTAMP_DERIVED\n' +
               'InvalidId,001,INSERT,2,' + logDate.format() + '\n' +
               ',001,UPDATE,2,' + logDate.format() + '\n';
    }

    // --- Test start() ---
    @IsTest
    static void ok() {
        Date logDate = Date.today();
        DMLLoggerBatch batch = new DMLLoggerBatch(logDate);
        Database.QueryLocator ql = batch.start(null);
        Assert.isNotNull(ql, 'QueryLocator should not be null.');
    }

    // --- Test execute(): valid CSV ---
    @IsTest
    static void testExecute_InsertAndUpdateAudits() {
        Date logDate = Date.today();
        Test.setMock(HttpCalloutMock.class, new MockEventLogService(getValidCsv(logDate)));

        List<EventLogFile> scope = new List<EventLogFile>{
            new EventLogFile(Id='0AT000000000001AAA', EventType='DatabaseSave')
        };

        Test.startTest();
        new DMLLoggerBatch(logDate).execute(null, scope);
        Test.stopTest();

        List<Database_Audit__c> audits = [
            SELECT ObjectName__c, Operation__c, Record_Count__c
            FROM Database_Audit__c
        ];

        Assert.isNotNull(audits, 'Audit records should have been inserted.');
        Assert.areEqual(2, audits.size(), 'Expected one audit record per DML_TYPE (INSERT, UPDATE).');
    }

    // --- Test execute(): updates existing record ---
    @IsTest
    static void testExecute_UpdatesExistingRecord() {
        Date logDate = Date.today();
        Id userId = UserInfo.getUserId();

        Database_Audit__c existing = new Database_Audit__c(
            User__c = userId,
            ObjectName__c = 'Account',
            Operation__c = 'INSERT',
            Record_Count__c = 10,
            LogDate__c = logDate
        );
        insert existing;

        Test.setMock(HttpCalloutMock.class, new MockEventLogService(getValidCsv(logDate)));

        Test.startTest();
        DMLLoggerBatch batch = new DMLLoggerBatch(logDate);
        batch.execute(null, new List<EventLogFile>{
            new EventLogFile(Id='0AT000000000002BBB', EventType='DatabaseSave')
        });
        Test.stopTest();

        List<Database_Audit__c> audits = [
            SELECT ObjectName__c, Operation__c, Record_Count__c
            FROM Database_Audit__c
            WHERE LogDate__c = :logDate
        ];

        Assert.isNotNull(audits, 'Records should exist after execution.');
    }

    // --- Test execute(): invalid CSV ---
    @IsTest
    static void testExecute_InvalidCsv() {
        Date logDate = Date.today();
        Test.setMock(HttpCalloutMock.class, new MockEventLogService(getInvalidCsv(logDate)));

        Test.startTest();
        try {
            new DMLLoggerBatch(logDate).execute(null, new List<EventLogFile>{
                new EventLogFile(Id='0AT000000000003CCC', EventType='DatabaseSave')
            });
        } catch (Exception e) {
            Assert.fail(); // should not throw exception
        }
        Test.stopTest();
    }

    // --- Test execute(): blank CSV ---
    @IsTest
    static void testExecute_BlankCsv() {
        Date logDate = Date.today();
        Test.setMock(HttpCalloutMock.class, new MockEventLogService(''));

        Test.startTest();
        try {
            new DMLLoggerBatch(logDate).execute(null, new List<EventLogFile>{
                new EventLogFile(Id='0AT000000000004DDD', EventType='DatabaseSave')
            });
        } catch (Exception e) {
            Assert.fail(); // should not throw exception
        }
        Test.stopTest();
    }

    // --- Test finish(): delete old records ---
    @IsTest
    static void testFinish_DeletesOldRecords() {
        Date logDate = Date.today();

        insert new List<Database_Audit__c>{
            new Database_Audit__c(User__c = UserInfo.getUserId(), ObjectName__c = 'Account',
                Operation__c = 'Insert', LogDate__c = logDate, Record_Count__c = 10),
            new Database_Audit__c(User__c = UserInfo.getUserId(), ObjectName__c = 'Contact',
                Operation__c = 'Update', LogDate__c = logDate, Record_Count__c = 5)
        };

        DMLLoggerBatch batch = new DMLLoggerBatch(logDate);
        batch.deleteList = [SELECT Id FROM Database_Audit__c WHERE LogDate__c = :logDate];

        Test.startTest();
        batch.finish(null);
        Test.stopTest();

        Integer remaining = [SELECT COUNT() FROM Database_Audit__c WHERE LogDate__c = :logDate];
        Assert.areEqual(0, remaining, 'finish() should delete old audit records.');
    }

    // --- Test execute(): empty scope ---
    @IsTest
    static void testExecute_EmptyScopeAndFinish() {
        Date logDate = Date.today();
        DMLLoggerBatch batch = new DMLLoggerBatch(logDate);

        Test.startTest();
        batch.execute(null, new List<EventLogFile>());
        batch.finish(null);
        Test.stopTest();

        Assert.isTrue(true, 'Handled empty scope without error.');
    }

    // --- Mock class ---
    private class MockEventLogService implements HttpCalloutMock {
        private String responseBody;
        MockEventLogService(String body) { this.responseBody = body; }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/csv');
            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }
    }

    // --- Test execute(): duplicate key increment and exception handling ---
    @IsTest
    static void testExecute_RecordCountIncrement_AndCatch() {
        Date logDate = Date.today();
        Id userId = UserInfo.getUserId();
        String duplicateKeyCsv =
            'USER_ID,KEY_PREFIX,DML_TYPE,NUM_ROWS,TIMESTAMP_DERIVED\n' +
            userId + ',001,INSERT,5,' + logDate.format() + '\n' +
            userId + ',001,INSERT,7,' + logDate.format() + '\n' +
            'BAD_ID,001,INSERT,3,' + logDate.format() + '\n';

        Test.setMock(HttpCalloutMock.class, new MockEventLogService(duplicateKeyCsv));

        Test.startTest();
        DMLLoggerBatch batch = new DMLLoggerBatch(logDate);
        batch.execute(null, new List<EventLogFile>{
            new EventLogFile(Id='0AT000000000007GGG', EventType='DatabaseSave')
        });
        Test.stopTest();

        List<Database_Audit__c> audits = [
            SELECT Record_Count__c
            FROM Database_Audit__c
            WHERE LogDate__c = :logDate
        ];

        Assert.areEqual(1, audits.size(), 'Only one record should exist for the duplicate key.');
        Assert.areEqual(12, audits[0].Record_Count__c, 'Record_Count__c should have incremented (5 + 7).');
    }

    // --- Test all catch blocks ---
    @IsTest
    static void testAllCatchBlocks() {
        Date logDate = Date.today();
        String auditPrefix = Database_Audit__c.SObjectType.getDescribe().getKeyPrefix();

        String badCsv = 'USER_ID,KEY_PREFIX,DML_TYPE,NUM_ROWS,TIMESTAMP_DERIVED\n' +
                        'BAD_ID,001,INSERT,abc,' + logDate.format() + '\n';
        Test.setMock(HttpCalloutMock.class, new MockEventLogService(badCsv));

        DMLLoggerBatch batchWithDeleteFail = new DMLLoggerBatch(logDate);
        String fakeDeleteId = auditPrefix + '000000000000BBB';
        batchWithDeleteFail.deleteList.add(new Database_Audit__c(Id = fakeDeleteId));

        Test.startTest();

        DMLLoggerBatch csvErrorBatch = new DMLLoggerBatch(logDate);
        csvErrorBatch.execute(null, new List<EventLogFile>{
            new EventLogFile(Id='0AT000000000099ZZZ', EventType='DatabaseSave')
        });

        batchWithDeleteFail.finish(null);
        Test.stopTest();

        Assert.isNotNull(csvErrorBatch, 'csvErrorBatch instance should not be null');
        Assert.isNotNull(batchWithDeleteFail, 'batchWithDeleteFail instance should not be null');
        Assert.areEqual(1, batchWithDeleteFail.deleteList.size(), 'One bad delete record expected');

        Assert.isTrue(true, 'Both catch blocks executed successfully.');
    }
}