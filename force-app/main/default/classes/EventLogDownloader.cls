public with sharing class EventLogDownloader {
// run by 
//EventLogDownloader.downloadAndSaveLatestCsv('ApexExecution');
// for dml 
public static Id downloadAndSaveLatestCsv(String eventType) {
    // Step 1: Query the latest EventLogFile record
    List<EventLogFile> logs = [
        SELECT Id, EventType, LogDate
        FROM EventLogFile
        WHERE EventType = :eventType
        ORDER BY LogDate DESC
        LIMIT 1
    ];

    if (logs.isEmpty()) {
        System.debug('No ' + eventType + ' logs found.');
        return null;
    }

    //download cv from rest api
    String csv = downloadCsvFromRest(logs[0].Id);

    if (csv == null || csv == '') {
        System.debug('CSV content is empty for ' + eventType);
        return null;
    }

    //save cv
    ContentVersion cv = new ContentVersion();
    cv.Title = eventType + 'Log';
    cv.PathOnClient = eventType + 'Log.csv';
    cv.VersionData = Blob.valueOf(csv);
    insert cv;

    System.debug(eventType + ' log file saved. ContentVersion Id: ' + cv.Id);
    return cv.Id;
}

//helper class
    private static String downloadCsvFromRest(Id logId) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String apiVersion = 'v61.0'; 
        req.setEndpoint(baseUrl + '/services/data/' + apiVersion + '/sobjects/EventLogFile/' + logId + '/LogFile');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return res.getBodyAsBlob().toString();
        } else {
            throw new CalloutException('Failed to download CSV. Status: ' + res.getStatus() + ' Body: ' + res.getBody());
        }
    }
}