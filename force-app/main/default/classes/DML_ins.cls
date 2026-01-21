/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-21-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class l {

    @AuraEnabled(cacheable=true)
    public static List<AverageResult> getHistoricalAverageForUser(Id userId, String objectName, Date recordLogDate) {
        List<Request> reqList = new List<Request>{ new Request(userId, objectName, recordLogDate) };
        return getHistoricalAverage(reqList);
    }

    @AuraEnabled(cacheable=no)
    public static List<AverageResult> getHistoricalAverage(List<Request> requests) {
        List<AverageResult> results = new List<AverageResult>();

        for(Request req : requests){
            // Calculate average of all Count__c values for this user/object up to the record's LogDate__c
            AggregateResult ar = [
                SELECT AVG(Count__c) avgCount
                FROM DML_Audit__c
                WHERE User__c = :req.userId
                  AND ObjectName__c = :req.objectName
                  AND LogDate__c <= :req.recordLogDate
            ];

            Decimal avgCount = (Decimal) ar.get('avgCount');

            AverageResult result = new AverageResult();
            result.userId = req.userId;
            result.objectName = req.objectName;
            result.averageCount = avgCount != null ? avgCount : 0;

            results.add(result);
        }

        return results;
    }

    // Input wrapper for LWC/Flow
    public class Request {
        @AuraEnabled public Id userId;
        @AuraEnabled public String objectName;
        @AuraEnabled public Date recordLogDate;

        public Request() {}
        public Request(Id userId, String objectName, Date recordLogDate) {
            this.userId = userId;
            this.objectName = objectName;
            this.recordLogDate = recordLogDate;
        }
    }

    // Output wrapper for LWC/Flow
    public class AverageResult {
        @AuraEnabled public Id userId;
        @AuraEnabled public String objectName;
        @AuraEnabled public Decimal averageCount;
    }
    @AuraEnabled(cacheable=no)
    public static List<AverageResult> getHistoricalAverage(List<Request> requests) {
        List<AverageResult> results = new List<AverageResult>();

        for(Request req : requests){
            // Calculate average of all Count__c values for this user/object up to the record's LogDate__c
            AggregateResult ar = [
                SELECT AVG(Count__c) avgCount
                FROM DML_Audit__c
                WHERE User__c = :req.userId
                  AND ObjectName__c = :req.objectName
                  AND LogDate__c <= :req.recordLogDate
            ];

            Decimal avgCount = (Decimal) ar.get('avgCount');

            AverageResult result = new AverageResult();
            result.userId = req.userId;
            result.objectName = req.objectName;
            result.averageCount = avgCount != null ? avgCount : 0;

            results.add(result);
        }

        return results;
    }

    // Input wrapper for LWC/Flow
    public class Request {
        @AuraEnabled public Id userId;
        @AuraEnabled public String objectName;
        @AuraEnabled public Date recordLogDate;

        public Request() {}
        public Request(Id userId, String objectName, Date recordLogDate) {
            this.userId = userId;
            this.objectName = objectName;
            this.recordLogDate = recordLogDate;  
        }
    }

    // Output wrapper for LWC/Flow
    public class AverageResult {
        @AuraEnabled public Id userId;
        @AuraEnabled public String objectName;
        @AuraEnabled public Decimal averageCount;
    }
}