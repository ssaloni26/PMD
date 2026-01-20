public with sharing class DmlMonthlyAnomalyBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Decimal thresholdFactor = 2;
    private Date runDate;

    public DmlMonthlyAnomalyBatch(Date runDate) {
        this.runDate = runDate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, User__c, ObjectName__c, Operation__c, Count__c, LogDate__c
            FROM DML_Audit__c
            WHERE LogDate__c <= :runDate
        ]);
    }

public void execute(Database.BatchableContext bc, List<SObject> scope) {
    List<Security_Insight__c> inserts = new List<Security_Insight__c>();
    Set<Id> userIds = new Set<Id>();

    //users
    for (DML_Audit__c rec : (List<DML_Audit__c>)scope) {
        if (rec.User__c != null) {
            try { userIds.add(Id.valueOf(rec.User__c)); } 
            catch(Exception e){ System.debug('Invalid User Id: '+rec.User__c); }
        }
    }

    Map<Id, User> users = new Map<Id, User>();
    if (!userIds.isEmpty()) {
        users = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :userIds ALL ROWS]);
    }

    //duplication
    Set<String> batchKeys = new Set<String>();
    for (DML_Audit__c rec : (List<DML_Audit__c>)scope) {
        if (rec.User__c != null) {
            String key = rec.User__c + '|' + rec.ObjectName__c + '|' + rec.Operation__c + '|' + rec.LogDate__c.format();
            batchKeys.add(key);
        }
    }

    //existing
    Map<String, Security_Insight__c> existingInsights = new Map<String, Security_Insight__c>();
    if (!batchKeys.isEmpty()) {
        for (Security_Insight__c si : [
            SELECT Id, User__c, ResourceName__c, ResourceType__c, Incident_Date__c
            FROM Security_Insight__c
            WHERE Incident_Date__c <= :runDate
            AND User__c IN :userIds
        ]) {
            String key = si.User__c + '|' + si.ResourceName__c + '|' + si.ResourceType__c + '|' + si.Incident_Date__c.format();
            existingInsights.put(key, si);
        }
    }

    for (DML_Audit__c rec : (List<DML_Audit__c>)scope) {
        Decimal cnt = rec.Count__c != null ? rec.Count__c : 0;

        //avg of months
        Decimal sumOtherMonths = 0;
        Integer countOtherMonths = 0;
        for (DML_Audit__c otherRec : (List<DML_Audit__c>)scope) {
            if (otherRec.User__c == rec.User__c &&
                otherRec.ObjectName__c == rec.ObjectName__c &&
                otherRec.Operation__c == rec.Operation__c &&
                otherRec.LogDate__c.month() != rec.LogDate__c.month()) {
                sumOtherMonths += otherRec.Count__c != null ? otherRec.Count__c : 0;
                countOtherMonths++;
            }
        }
        Decimal overallAvg = countOtherMonths > 0 ? sumOtherMonths / countOtherMonths : 0;

        if (overallAvg > 0 && cnt >= overallAvg * thresholdFactor) {
            Id userId = Id.valueOf(rec.User__c);
            String userName = users.containsKey(userId) ? users.get(userId).Name : 'Unknown';

            //duplicate key
            String key = rec.User__c + '|' + rec.ObjectName__c + '|' + rec.Operation__c + '|' + rec.LogDate__c.format();

       
            if (!existingInsights.containsKey(key)) {
                inserts.add(new Security_Insight__c(
                    ResourceName__c = rec.ObjectName__c,
                    ResourceType__c = rec.Operation__c,
                    User__c = userId,
                    Incident_Date__c = rec.LogDate__c,
                    Severity__c = 'High',
                    Description__c = 'DML spike detected: Count ' + cnt +
                                     ', Overall Avg (other months) ' + overallAvg +
                                     ', Threshold Factor: ' + thresholdFactor + 'x, User: ' + userName
                ));
                System.debug('Spike detected for record ' + rec.Id + ', inserting Security_Insight.');
            } else {
                System.debug('Duplicate detected for ' + key + ', skipping insert.');
            }
        }
    }

    if (!inserts.isEmpty()) insert inserts;
}

    public void finish(Database.BatchableContext bc) {
        System.debug('DmlMonthlyAnomalyBatch completed.');
    }
}