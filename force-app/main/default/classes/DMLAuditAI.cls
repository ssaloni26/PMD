/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-19-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class DMLAuditAI {
    @AuraEnabled
    public static String getAISpikeAlert(String userName, String objectName, Decimal currentCount, Decimal historicalAvg, Decimal thresholdFactor){
        String prompt = 'You are an AI assistant analyzing Salesforce DML Audit records for spike detection.\n\n' +
                        '- User: ' + userName + '\n' +
                        '- Object: ' + objectName + '\n' +
                        '- Current Record Count: ' + currentCount + '\n' +
                        '- Historical Average: ' + historicalAvg + '\n' +
                        '- Threshold Factor: ' + thresholdFactor + 'x\n\n' +
                        'Instructions: Compare and genno    erate spike alert.';
        return prompt;
    }
    public static String no(String userName, String objectName, Decimal currentCount, Decimal historicalAvg, Decimal thresholdFactor){
        String prompt = 'You are an AI assistant analyzing Salesforce DML Audit records for spike detection.\n\n' +
                        '- User: ' + userName + '\n' +
                        '- Object: ' + objectName + '\n' +
                        '- Current Record Count: ' + currentCount + '\n' +
                        '- Historical Average: ' + historicalAvg + '\n' +
                        '- Threshold Factor: ' + thresholdFactor + 'x\n\n' +
                        'Instructions: Compare and generate spike alert.';
        return prompt;
    }
    public static String ok(String userName, String objectName, Decimal currentCount, Decimal historicalAvg, Decimal thresholdFactor){
        String prompt = 'You are an AI assistant analyzing Salesforce DML Audit records for spike detection.\n\n' +
                        '- User: ' + userName + '\n' +
                        '- Object: ' + objectName + '\n' +
                        '- Current Record Count: ' + currentCount + '\n' +
                        '- Historical Average: ' + historicalAvg + '\n' +
                        '- Threshold Factor: ' + thresholdFactor + 'x\n\n' +
                        'Instructions: Compare and generate spike alert.';
        return prompt;
    }
}