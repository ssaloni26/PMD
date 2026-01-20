@IsTest
private class EventLogServiceTest {

        private class MockHttpThrowCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated callout exception');
        }
    }
   
    @IsTest
    static void testGetEventLogCsvCalloutException() {
        Test.setMock(HttpCalloutMock.class, new MockHttpThrowCallout());

        Id dummyId = '0ATgL000001eegkWAA';
        String csv = EventLogService.getEventLogCsv(dummyId);

        System.assertEquals('', csv);
    }
    // Mock class for successful HTTP callout
    private class EventLogSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assert(req.getMethod() == 'GET', 'Expected GET method');
            System.assert(req.getEndpoint().contains('/EventLogFile/0ATgL000001gyNjWAI/LogFile'), 'Incorrect endpoint');

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/csv');
            res.setBody('EventType,CreatedDate,UserId\nLogin,2025-10-27,005XXXXXXXXXXXX');
            res.setStatusCode(200);
            return res;
        }
    }

    // Mock class for failed HTTP callout
    private class EventLogErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setBody('Not Found');
            return res;
        }
    }
//all
    @IsTest
    static void testGetEventLogCsv_Success() {
        // Register the mock callout
        Test.setMock(HttpCalloutMock.class, new EventLogSuccessMock());

        Test.startTest();
        String csvData = EventLogService.getEventLogCsv('0ATgL000001gyNjWAI');
        Test.stopTest();

        System.assertNotEquals('', csvData, 'Expected non-empty CSV data');
        System.assert(csvData.contains('EventType'), 'CSV should contain header');
        System.assert(csvData.contains('Login'), 'CSV should contain mock event data');
    }

    @IsTest
    static void testGetEventLogCsv_Error() {
        // Register the error mock callout
        Test.setMock(HttpCalloutMock.class, new EventLogErrorMock());

        Test.startTest();
        String csvData = EventLogService.getEventLogCsv('0ATgL000001gyNjWAI');
        Test.stopTest();

        System.assertEquals('', csvData, 'Expected empty string for failed callout');
    }


    
@IsTest
static void testCatchGeneralException() {
   
    Test.startTest();
    String csv = EventLogService.getEventLogCsv(null);
    Test.stopTest();

    System.assertEquals('', csv, 'Catch block for general Exception executed');
}
}