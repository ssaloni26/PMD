@IsTest
private class EventLogServiceTest {

    //Mock class to simulate a callout exception scenario.
    private class MockHttpThrowCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated callout exception');
        }
    }

    //Mock class to simulate a successful Event Log CSV response (HTTP 200).
    private class EventLogSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('GET', req.getMethod(), 'Expected GET method');
            System.assertEquals(true, req.getEndpoint().contains('/EventLogFile/0ATgL000001gyNjWAI/LogFile'), 'Incorrect endpoint');

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/csv');
            res.setBody('EventType,CreatedDate,UserId\nLogin,2025-10-27,005XXXXXXXXXXXX');
            res.setStatusCode(200);
            return res;
        }
    }

    //Mock class to simulate an error response from Event Log API (HTTP 404).
    private class EventLogErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setBody('Not Found');
            return res;
        }
    }

    // Test to verify successful CSV fetch when callout returns 200 response. 
    @IsTest
    static void testGetEventLogCsv_Success() {
        Test.setMock(HttpCalloutMock.class, new EventLogSuccessMock());
        Test.startTest();
        String csvData = EventLogService.getEventLogCsv('0ATgL000001gyNjWAI');
        Test.stopTest();

        System.assertNotEquals('', csvData, 'Expected non-empty CSV data');
        System.assertEquals(true, csvData.contains('EventType'), 'CSV should contain header');
        System.assertEquals(true, csvData.contains('Login'), 'CSV should contain mock event data');
    }

    // Test to verify empty result when API returns error response (404). 
    @IsTest
    static void testGetEventLogCsv_Error() {
        Test.setMock(HttpCalloutMock.class, new EventLogErrorMock());
        Test.startTest();
        String csvData = EventLogService.getEventLogCsv('0ATgL000001gyNjWAI');
        Test.stopTest();

        System.assertEquals('', csvData, 'Expected empty string for failed callout');
    }

    // Test to verify graceful handling of CalloutException during callout. 
    @IsTest
    static void testGetEventLogCsv_CalloutException() {
        Test.setMock(HttpCalloutMock.class, new MockHttpThrowCallout());
        Test.startTest();
        String csv = EventLogService.getEventLogCsv('0ATgL000001gyNjWAI');
        Test.stopTest();

        System.assertEquals('', csv, 'Should return empty string when callout throws exception');
    }

    // Test to verify handling of general exceptions such as null input. 
    @IsTest
    static void testCatchGeneralException() {
        Test.startTest();
        String csv = EventLogService.getEventLogCsv(null);
        Test.stopTest();

        System.assertEquals('', csv, 'Catch block for general Exception executed');
    }
}