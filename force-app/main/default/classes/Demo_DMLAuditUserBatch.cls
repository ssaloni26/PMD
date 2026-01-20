public with sharing class Demo_DMLAuditUserBatch implements Database.Batchable<SObject>, Database.Stateful {

    @TestVisible public static Boolean forceTryBlock = false;
    @TestVisible private static String testRawOutput;
    private List<Id> userIds = new List<Id>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        for (AggregateResult ar : [
            SELECT User__c userId
            FROM DML_Audit__c
            WHERE User__c != null
            GROUP BY User__c
        ]) {
            userIds.add((Id) ar.get('userId'));
        }
        return Database.getQueryLocator([
            SELECT Id, Name 
            FROM User 
            WHERE Id IN :userIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<User> userScope) {
        if (userScope == null || userScope.isEmpty()) return;

        List<Security_Insight__c> insightsToInsert = new List<Security_Insight__c>();
        Set<Id> scopeUserIds = new Set<Id>();
        for (User u : userScope) scopeUserIds.add(u.Id);

        Map<Id, List<DML_Audit__c>> userIdVsAudits = new Map<Id, List<DML_Audit__c>>();
        for (DML_Audit__c dml : [
            SELECT Id, User__c, ObjectName__c, Count__c, LogDate__c, Operation__c
            FROM DML_Audit__c
            WHERE User__c IN :scopeUserIds
        ]) {
            if (!userIdVsAudits.containsKey(dml.User__c))
                userIdVsAudits.put(dml.User__c, new List<DML_Audit__c>());
            userIdVsAudits.get(dml.User__c).add(dml);
        }

        Set<String> existingDescriptions = new Set<String>();
        for (Security_Insight__c si : [SELECT Description__c FROM Security_Insight__c]) {
            if (si.Description__c != null)
                existingDescriptions.add(si.Description__c.trim());
        }

        for (User u : userScope) {
            Id userId = u.Id;
            String cleanedOutput = getAIResponse(userId, userIdVsAudits.get(userId));
            if (cleanedOutput == null || cleanedOutput.trim() == '') continue;

            Map<String, Object> aiMap = parseAIGeneratedResponse(cleanedOutput);
            if (aiMap.isEmpty() || !aiMap.containsKey('SpikedCount') || !aiMap.containsKey('records')) continue;

            Integer spikedCount = 0;
            try {
                spikedCount = (Integer) aiMap.get('SpikedCount');
            } catch (Exception e) {
                spikedCount = 0;
            }
            if (spikedCount <= 0) continue;

            List<Object> spikeRecords = (List<Object>) aiMap.get('records');
            if (spikeRecords == null || spikeRecords.isEmpty()) continue;

            Map<String, Security_Insight__c> insightsMap = buildInsights(userId, spikeRecords, existingDescriptions);
            insightsToInsert.addAll(insightsMap.values());
        }

        if (!insightsToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(insightsToInsert, false);
            Integer success = 0, failure = 0;
            for (Database.SaveResult r : results) {
                if (r.isSuccess()) success++;
                else failure++;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {}

    private static String getAIResponse(Id userId, List<DML_Audit__c> records) {
        if (records == null || records.isEmpty()) return null;

        if (Test.isRunningTest() && !forceTryBlock) {
            return '{"records":[{' +
                    '"Operation":"Insert","Logdate":"2025-12-01","ObjectName":"Order","Count":30000,"User":"' + userId + '"' +
                    '},{"Operation":"Delete","Logdate":"2025-10-12","ObjectName":"Dml_Audit__c","Count":20,"User":"' + userId + '"' +
                    '}],"SpikedCount":2}';
        }

        try {
            Map<String, Object> payload = AIHelper.preparePayload(records, userId);
            Map<String, Object> aiOutput = AIHelper.sendToAI('DML4', payload, userId);
            if (aiOutput == null || aiOutput.isEmpty()) return null;
            String rawOutput = JSON.serialize(aiOutput);
            return rawOutput
                .replace('\u00A0', ' ')
                .replaceAll('(?i)```json', '')
                .replaceAll('(?i)```', '')
                .trim();
        } catch (Exception e) {
            System.debug('AI call failed for user ' + userId + ': ' + e.getMessage());
            return null;
        }
    }

    public static Map<String, Object> parseAIGeneratedResponse(String raw) {
        Map<String, Object> parsedResponse = new Map<String, Object>();
        if (raw == null || raw.trim() == '') return parsedResponse;
        try {
            Object parsed = JSON.deserializeUntyped(raw);
            if (parsed instanceof Map<String, Object>)
                parsedResponse = (Map<String, Object>) parsed;
        } catch (Exception e) {
            System.debug('JSON parse failed: ' + e.getMessage());
        }
        return parsedResponse;
    }

    private static Map<String, Security_Insight__c> buildInsights(Id userId, List<Object> spikeRecords, Set<String> existingDescSet) {
        Map<String, Security_Insight__c> insightsMap = new Map<String, Security_Insight__c>();
        for (Object recObj : spikeRecords) {
            Map<String, Object> recMap = (Map<String, Object>) recObj;
            String objectName = getStringSafe(recMap, 'ObjectName', 'Unknown');
            String logDate = getStringSafe(recMap, 'Logdate', 'Unknown');
            String operation = getStringSafe(recMap, 'Operation', 'Insert');
            Integer count = getIntSafe(recMap, 'Count', 1);
            String desc1 = count + ' ' + operation + ' ' + objectName +
                           ' operations recorded on ' + logDate +
                           ' for user ' + userId + '.';
            if (existingDescSet.contains(desc1)) continue;
            Security_Insight__c insight = new Security_Insight__c(
                User__c = userId,
                Description__c = desc1,
                Incident_Date__c = Date.today(),
                Severity__c = 'High',
                ResourceName__c = objectName,
                ResourceType__c = 'DML Audit'
            );
            insightsMap.put(desc1, insight);
        }
        return insightsMap;
    }

    private static String getStringSafe(Map<String, Object> inputMap, String key, String defaultValue) {
        if (inputMap == null || key == null) return defaultValue;
        if (inputMap.containsKey(key) && inputMap.get(key) != null)
            return String.valueOf(inputMap.get(key)).trim();
        return defaultValue;
    }

    private static Integer getIntSafe(Map<String, Object> inputMap, String key, Integer defaultValue) {
        if (inputMap == null || key == null) return defaultValue;
        if (!inputMap.containsKey(key) || inputMap.get(key) == null) return defaultValue;
        try {
            return Integer.valueOf(String.valueOf(inputMap.get(key)));
        } catch (Exception e) {
            return defaultValue;
        }
    }
}