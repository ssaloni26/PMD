/** Description
The DMLLoggerBatch class analyzes Salesforce Event Log Files for the given date to track all DML Operations (from Event Type Database 
Save) activities performed by users. It retrieves event logs, parses their CSV data, and calculates the total number of records 
inserted, updated, or deleted per user, object, operation and logdate. The batch then upserts summarized counts into a custom 
object Database_Audit__c. This enables daily monitoring and auditing of user-level database activity across Salesforce objects.
**/
public class DMLLoggerBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    public Set<String> systemObjectSet = SchemaService.getSystemObjects();
    private Date logDate;
    @TestVisible
    public Map<String, Database_Audit__c> databaseAuditMap = new Map<String, Database_Audit__c>();
    @TestVisible
    public List<Database_Audit__c> deleteList = new List<Database_Audit__c>();

    
    public DMLLoggerBatch(Date logDate) {
        this.logDate = logDate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date startDate = logDate;
        Date endDate = logDate.addDays(1);
        deleteList = [SELECT Id FROM Database_Audit__c WHERE LogDate__c = :logDate and operation__c != 'Query'];

        return Database.getQueryLocator([
            SELECT Id, EventType, LogDate
            FROM EventLogFile
            WHERE EventType = 'DatabaseSave'
            AND Interval ='Hourly'
            AND LogDate >= :startDate
            AND LogDate < :endDate
            ORDER BY LogDate DESC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<EventLogFile> scope) {
       processEventLog(scope);
    }

    private void processEventLog(List<EventLogFile> eventLogs) {
        if (eventLogs.isEmpty()) return;
		for (EventLogFile logFile : eventLogs) {
            try {
                String csvData = EventLogService.getEventLogCsv(logFile.Id);
                List<Map<String, String>> eventLogFileRows = DynamicCSVParser.parseCSV(csvData);
                for (Map<String, String> row : eventLogFileRows) {
                    String userIdStr = row.get('USER_ID');
                    String keyPrefix = row.get('KEY_PREFIX');
                    String dmlType = row.get('DML_TYPE');
                    String numRowsStr = row.get('NUM_ROWS');
                    String objectName = SchemaService.getSObjectNameFromPrefix(keyPrefix);
                    Integer numRows = Integer.valueOf(numRowsStr);
                    
                    if (String.isBlank(userIdStr) || 
                        String.isBlank(keyPrefix) ||
                        String.isBlank(dmlType) || 
                        String.isBlank(numRowsStr)|| 
                        String.isBlank(objectName) || 
                        systemObjectSet.contains(objectName)
                   	) {
                        continue;
                    }
                    
                    String key = buildKey(userIdStr, objectName, dmlType, logDate);
                    Database_Audit__c recordToUpsert;
                    if (databaseAuditMap.containsKey(key)) {
                        recordToUpsert = databaseAuditMap.get(key);
                        recordToUpsert.Record_Count__c = recordToUpsert.Record_Count__c + numRows;
                    } else {
                        recordToUpsert = new Database_Audit__c(
                            User__c = userIdStr,
                            ObjectName__c = objectName,
                            Operation__c = dmlType,
                            LogDate__c = logDate,
                            Record_Count__c = numRows
                        );
                        databaseAuditMap.put(key,recordToUpsert);
                    }
				}
            } catch (Exception e) {System.debug('Error processing EventLogFile ' + logFile.Id + ' : ' + e.getMessage());}
        }
            try {
                upsert databaseAuditMap.values();
             } catch (Exception e) {System.debug('Upsert failed in finish(): ' + e.getMessage());}
        
    }

	/**Generates a unique composite key by concatenating the User Id, Object Name, uppercase Operation, and formatted Log Date (YYYY-MM-DD).**/
    private static String buildKey(String userIdStr, String objectName, String operation, Date logDate) {
         return userIdStr + '|' +objectName + '|' + String.valueOf(operation).toUpperCase() + '|' + 
                DateTime.newInstance(logDate.year(), logDate.month(), logDate.day()).format('yyyy-MM-dd');
    }

    public void finish(Database.BatchableContext bc) {
        if (!deleteList.isEmpty()) {
            try {
                delete deleteList;                
                //Connected App Logger Batch
                Database.executeBatch(new ConnectedAppLoggerBatch(), 1);
            } catch (Exception e) {System.debug('Delete failed in finish(): ' + e.getMessage());}
        }
    }
}