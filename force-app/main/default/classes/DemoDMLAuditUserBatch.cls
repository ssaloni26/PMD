/**
 * @description : Batch class to analyze DML_Audit__c logs per user using AI (Einstein) 
 *                and create Security_Insight__c records for anomalies.
 * @author      : Saloni Swami
 * @last modified on : 2025-10-29
 */
public with sharing class DemoDMLAuditUserBatch implements Database.Batchable<SObject> {

    @TestVisible private static Boolean forceTryBlock = false; 
    public List<Id> userIds = new List<Id>();

    // ============================================================
    // Start Method
    // =========================================================== '=
    public Database.QueryLocator start(Database.BatchableContext bc) {
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

    // ============================================================
    // Execute Method
    // ============================================================
    public void execute(Database.BatchableContext bc, List<User> scope) {
        processUsers(scope);
    }

    // ============================================================
    // Finish Method
    // ============================================================
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch completed. Total users processed: ' + userIds.size());
    }

    // ============================================================
    // Core Logic — Process Users
    // ============================================================
    @TestVisible
    public void processUsers(List<User> users) {
        List<Security_Insight__c> insightsToInsert = new List<Security_Insight__c>();

        for (User u : users) {
            Id userId = u.Id;
            String cleanedOutput;

            // ✅ Use mock JSON in test context
            if (Test.isRunningTest() && !forceTryBlock) {
                cleanedOutput = '{"records":[{' +
                    '"Operation":"Insert",' +
                    '"Logdate":"2025-12-01",' +
                    '"ObjectName":"Order",' +
                    '"Count":30000,' +
                    '"User":"' + userId + '",' +
                    '"RecordId":"a03gL00000DyKMwQAN"' +
                '},{' +
                    '"Operation":"Update",' +
                    '"Logdate":"2025-10-12",' +
                    '"ObjectName":"ApexClass",' +
                    '"Count":12,' +
                    '"User":"' + userId + '",' +
                    '"RecordId":"a03gL00000FtDlQAN"' +
                '}],' +
                '"SpikedCount":2}';
            } else {
                // 🧠 Real Flow — Fetch DML logs and send to AI
                List<DML_Audit__c> userRecords = [
                    SELECT Id, User__c, ObjectName__c, Count__c, LogDate__c
                    FROM DML_Audit__c
                    WHERE User__c = :userId
                ];

                if (userRecords.isEmpty()) {
                    System.debug('No DML_Audit__c records for user ' + userId + '. Skipping AI call.');
                    continue;
                }

                Map<String, Object> payload = AIHelper.preparePayload(userRecords, userId);
                Map<String, Object> aiOutput = AIHelper.sendToAI('DML4', payload, userId);

                // 🔹 Guard against null/empty AI output
                if (aiOutput == null || aiOutput.isEmpty()) {
                    System.debug('AI output is null or empty for user ' + userId + '. Skipping.');
                    continue;
                }

                System.debug('AI Output for User ' + userId + ': ' + aiOutput);

                // 🔹 Clean and sanitize JSON
                String rawOutput = JSON.serialize(aiOutput);
                cleanedOutput = rawOutput
                    .replace('\u00A0', ' ')
                    .replaceAll('(?i)```json', '')
                    .replaceAll('(?i)```', '')
                    .trim();

                System.debug('Raw AI Output: ' + cleanedOutput);
            }

            // ============================================================
            // Parse AI JSON Response
            // ============================================================
            Map<String, Object> aiMap = new Map<String, Object>();
            try {
                aiMap = (Map<String, Object>) JSON.deserializeUntyped(cleanedOutput);
            } catch (Exception e) {
                System.debug('Invalid JSON for user ' + userId + ': ' + cleanedOutput);
                continue;
            }

            if (!aiMap.containsKey('SpikedCount') || !aiMap.containsKey('records')) {
                System.debug('AI map missing expected keys for user ' + userId + ': ' + aiMap.keySet());
                continue;
            }

            Integer spikedCount;
            try {
                spikedCount = (Integer) aiMap.get('SpikedCount');
            } catch (Exception e) {
                spikedCount = 0;
            }

            if (spikedCount == null || spikedCount <= 0) {
                System.debug('No spikes detected for user ' + userId);
                continue;
            }

            List<Object> spikeRecords = (List<Object>) aiMap.get('records');
            if (spikeRecords == null || spikeRecords.isEmpty()) {
                System.debug('No record list found in AI output for user ' + userId);
                continue;
            }

            // ============================================================
            // Group Records by ObjectName + LogDate
            // ============================================================
            Map<String, List<Map<String, Object>>> groupedByObjDate = new Map<String, List<Map<String, Object>>>();

            for (Object recObj : spikeRecords) {
                Map<String, Object> recMap = (Map<String, Object>) recObj;

                String objectName = recMap.containsKey('ObjectName')
                    ? String.valueOf(recMap.get('ObjectName'))
                    : 'Unknown';

                String logDateStr = 'Unknown';
                for (String keyName : recMap.keySet()) {
                    if (keyName.toLowerCase() == 'logdate') {
                        logDateStr = String.valueOf(recMap.get(keyName));
                        break;
                    }
                }

                String key = objectName + '|' + logDateStr;
                if (!groupedByObjDate.containsKey(key)) {
                    groupedByObjDate.put(key, new List<Map<String, Object>>());
                }
                groupedByObjDate.get(key).add(recMap);
            }

            // ============================================================
            // Build Security Insights per group
            // ============================================================
            for (String key : groupedByObjDate.keySet()) {
                List<Map<String, Object>> recGroup = groupedByObjDate.get(key); 
                Map<String, Integer> operationCountMap = new Map<String, Integer>();

                String objectName = key.split('\\|')[0];
                String logDateStr = key.split('\\|')[1];
                String userName = userId;

                for (Map<String, Object> recMap : recGroup) {
                    String operation = recMap.containsKey('Operation')
                        ? String.valueOf(recMap.get('Operation')).toLowerCase()
                        : '';
                    Integer countVal = (recMap.containsKey('Count') && recMap.get('Count') != null)
                        ? Integer.valueOf(recMap.get('Count'))
                        : 0;

                    if (operation != '') {
                        operationCountMap.put(
                            operation,
                            operationCountMap.containsKey(operation)
                                ? operationCountMap.get(operation) + countVal
                                : countVal
                        );
                    }
                }

                List<String> opParts = new List<String>();
                if (operationCountMap.containsKey('insert')) opParts.add(operationCountMap.get('insert') + ' insert');
                if (operationCountMap.containsKey('update')) opParts.add(operationCountMap.get('update') + ' update');
                if (operationCountMap.containsKey('delete')) opParts.add(operationCountMap.get('delete') + ' delete');

                String desc1 = String.join(opParts, ', ') + ' ' + objectName +
                    ' operations recorded on ' + logDateStr +
                    ' for user ' + userName + '.';

                Security_Insight__c insight = new Security_Insight__c();
                insight.User__c = userId;
                insight.Description__c = desc1;
                insight.Incident_Date__c = Date.today();
                insight.Severity__c = 'High';
                insight.ResourceName__c = 'DML Audit';
                insight.ResourceType__c = 'User Activity';
                insightsToInsert.add(insight);
            }
        }

        // ============================================================
        // Final DML Operation
        // ============================================================
        if (!insightsToInsert.isEmpty()) {
            try {
                insert insightsToInsert;
                System.debug('Inserted ' + insightsToInsert.size() + ' Security Insight records.');
            } catch (DmlException dmle) {
                System.debug('Failed to insert Security Insight records: ' + dmle.getMessage());
            }
        }
    }
}