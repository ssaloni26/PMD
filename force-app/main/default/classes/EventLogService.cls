/** Description
The EventLogService class retrieves the raw CSV data for a specific Salesforce EventLogFile 
record using an authenticated HTTP callout. It constructs a REST API request to fetch the 
event log’s binary log file content, converts it into a readable string, and returns it for 
further processing. If the callout fails or an exception occurs, it safely handles the error 
and returns an empty string. This class serves as a utility for accessing Event Log File data 
within Salesforce for analysis or auditing.
 **/
public class EventLogService {
    public static String getEventLogCsv(Id eventLogId) {
        if (Test.isRunningTest() && DummyRecordDmlloggerTesting.dummyLogs.containsKey(eventLogId)) {
            return DummyRecordDmlloggerTesting.dummyLogs.get(eventLogId);
        }
            try{
            Http http = new Http();
            HttpRequest req = new HttpRequest();
    
            req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() +
                            '/services/data/v61.0/sobjects/EventLogFile/' + eventLogId + '/LogFile');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
    
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                return res.getBodyAsBlob().toString();
            } else {
                return '';
            }
		} catch (CalloutException e) {
            System.debug('CalloutException occurred: ' + e.getMessage());
            return '';
        }catch (Exception e) {
            System.debug('Unexpected exception occurred: ' + e.getMessage());
            return '';
        }
    }
}