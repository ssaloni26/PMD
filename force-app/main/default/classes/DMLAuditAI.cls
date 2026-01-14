/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-14-2026
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
                        'Instructions: Compare and generate spike alert.';
        return prompt;
    }
    public static String spike(String userName, String objectName, Decimal currentCount, Decimal historicalAvg, Decimal thresholdFactor){
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