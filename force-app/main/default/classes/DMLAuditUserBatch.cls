public with sharing class DMLAuditUserBatch implements Database.Batchable<SObject> ,  Database.Stateful{

    public List<Id> userIds = new List<Id>();

    private static Map<String, Integer> calloutCounts = new Map<String, Integer>();
    public Database.QueryLocator start(Database.BatchableContext bc) {

        //all users
        for (AggregateResult result : [
            SELECT User__c userId
            FROM DML_Audit__c
            WHERE User__c != null
            GROUP BY User__c
        ]) {
            userIds.add((Id) result.get('userId'));
        }

        return Database.getQueryLocator([SELECT Id FROM User WHERE Id IN :userIds]);
    }
public void execute(Database.BatchableContext bc, List<User> scope) {

    List<Security_Insight__c> insightsToInsert = new List<Security_Insight__c>();

    for (User u : scope) {
        Id userId = u.Id;

        //records 
        List<DML_Audit__c> userRecords = [
            SELECT Id, User__c, ObjectName__c, Count__c, LogDate__c
            FROM DML_Audit__c
            WHERE User__c = :userId
        ];

        //skip if no records 
        if (userRecords.isEmpty()) {
            System.debug('No DML_Audit__c records for user ' + userId + '. Skipping AI call.');
            continue; 
        }

        
        //payload
        List<Map<String, Object>> jsonRecords = new List<Map<String, Object>>();
        for (DML_Audit__c rec : userRecords) {
            jsonRecords.add(new Map<String, Object>{
                'RecordId' => rec.Id,
                'User' => rec.User__c,
                'Count' => rec.Count__c,
                'LogDate' => rec.LogDate__c,
                'ObjectName' => rec.ObjectName__c
            });
        }

        
        Map<String, Object> payload = new Map<String, Object>{
            'BatchId' => 'batch_' + userId + '_' + Datetime.now().getTime(),
            'records' => jsonRecords
        };

        //ai ip
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        ConnectApi.WrappedValue wrappedPayload = new ConnectApi.WrappedValue();
        wrappedPayload.value = JSON.serialize(payload);
        inputParams.put('Input:DML_Records', wrappedPayload);

        try {
            String aiOutput = PromptUtils.invokePrompt('Demo', inputParams);
            System.debug('AI Output for User ' + userId + ': ' + aiOutput);

            // --- Count this callout ---
                String className = 'DMLAuditUserBatch';

                if (!calloutCounts.containsKey(className)) calloutCounts.put(className, 0);
                calloutCounts.put(className, calloutCounts.get(className) + 1);

                System.debug('HTTP callout made by ' + className
                             + ', Date: ' + Date.today()
                             + ', Total callouts so far: ' + calloutCounts.get(className));

            // Clean AI output
            String cleanedOutput = aiOutput.replace('\u00A0', ' ').trim();

            cleanedOutput = cleanedOutput.replaceAll('^```json', '');
            cleanedOutput = cleanedOutput.replaceAll('```$', '');
            cleanedOutput = cleanedOutput.trim();

            //skip if no json
            Map<String, Object> aiMap;
            try {
                aiMap = (Map<String, Object>) JSON.deserializeUntyped(cleanedOutput);
            } catch (Exception e) {
                System.debug('AI output is not valid JSON for user ' + userId + ': ' + cleanedOutput);
                continue; 
            }

            //insert in Security_Insight__c
            Integer spikedCount = (Integer) aiMap.get('SpikedCount');
            if (spikedCount != null && spikedCount > 0) {
                List<Object> spikeRecords = (List<Object>) aiMap.get('records');
                if (spikeRecords != null && !spikeRecords.isEmpty()) {
                    Security_Insight__c insight = new Security_Insight__c();
                    insight.User__c = userId;
                    insight.Description__c = JSON.serializePretty(spikeRecords);
                    insight.Incident_Date__c = Date.today();
                    insight.Severity__c = 'High';
                    insight.ResourceName__c = 'DML Audit';
                    insight.ResourceType__c = 'User Activity';
                    insightsToInsert.add(insight);
                }
            }

        } catch (Exception e) {
            System.debug('AI call failed for user ' + userId + ': ' + e.getMessage());
        }
    }

    if (!insightsToInsert.isEmpty()) {
        try {
            ///insert insightsToInsert;
            System.debug('Inserted ' + insightsToInsert.size() + ' Security Insight records.');
        } catch (DmlException dmle) {
            System.debug('Failed to insert Security Insight records: ' + dmle.getMessage());
        }
    }
}


    public void finish(Database.BatchableContext bc) {
        System.debug('Batch completed. Total users processed: ' + userIds.size());
        System.debug('Summary of HTTP callouts made by class: ' + calloutCounts);
    }
}