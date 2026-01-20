/**
 * @description       : Mock HTTP response for Einstein LLM / AI output simulation (matches real AI output)
 * @author            : saloni swami
 * @last modified on  : 10-29-2025
**/
@IsTest
global class DemoDMLAI_MockResponse implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);

        String mockAIResponse = 
        '{' +
            '"records": [' +
                '{' +
                    '"Operation": null,' +
                    '"Logdate": "2025-12-01",' +
                    '"ObjectName": "Order",' +
                    '"Count": 30000,' +
                    '"User": "005gL000007YloTQAS",' +
                    '"RecordId": "a03gL00000DyKMwQAN"' +
                '},' +
                '{' +
                    '"Operation": null,' +
                    '"Logdate": "2025-10-12",' +
                    '"ObjectName": "ApexClass",' +
                    '"Count": 12,' +
                    '"User": "005gL000007YloTQAS",' +
                    '"RecordId": "a03gL00000FtDlQAB"' +
                '}' +
            ']' +
        '}';

        res.setBody(mockAIResponse);
        return res;
    }
}