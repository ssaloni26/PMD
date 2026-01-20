@IsTest
public class DMLLoggerScheduler_Test {

    @IsTest
    static void testSchedulerExecutesBatch() {
        // Arrange: create a dummy date for the scheduler
        Date yesterday = Date.today().addDays(-1);

        // Use Test.startTest/stopTest to simulate asynchronous job execution
        Test.startTest();

        // Act: execute the scheduler directly
        DMLLoggerScheduler scheduler = new DMLLoggerScheduler();
        scheduler.execute(null);

        // Assert: verify a batch job was queued
        List<AsyncApexJob> jobs = [
            SELECT Id, JobType, Status
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
        ];

        Test.stopTest();

        System.assert(!jobs.isEmpty(), 'Batch job should have been enqueued by the scheduler.');
        System.assertEquals('BatchApex', jobs[0].JobType, 'Expected BatchApex job type.');
    }

    @IsTest
    static void testScheduledJobRunsAutomatically() {
        // Arrange: schedule the job to run once in the test context
        String cron = '0 0 12 * * ?'; // noon every day

        Test.startTest();
        String jobId = System.schedule('Test_DMLLoggerScheduler', cron, new DMLLoggerScheduler());
        Test.stopTest();

        // Assert: verify the scheduled job was created
        List<CronTrigger> ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, ct.size(), 'Scheduled job should exist.');
        System.assertEquals('0 0 12 * * ?', ct[0].CronExpression, 'Cron expression should match.');
    }
}