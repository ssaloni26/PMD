/** Description
The DMLLoggerBatch class analyzes Salesforce Event Log Files for the given date to track all DML Operations (from Event Type Database 
Save) activities performed by users. It retrieves event logs, parses their CSV data, and calculates the total number of records 
inserted, updated, or deleted per user, object, operation and logdate. The batch then upserts summarized counts into a custom 
object Database_Audit__c. This enables daily monitoring and auditing of user-level database activity across Salesforce objects.
**/
public class DMLLoggerBatcnh implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
  private Date logDate;
  @TestVisible
  public Map<String, Database_Audit__c> existingDatabaseAuditMap = new Map<String, Database_Audit__c>();
  public Map<String, Integer> userObjectOperationCountMap = new Map<String, Integer>();

  public DMLLoggerBatch(Date logDate) {
    this.logDate = logDate;
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    Date startDate = logDate;
    Date endDate = logDate.addDays(1);

    return Database.getQueryLocator(
      [
        SELECT Id, EventType, LogDate
        FROM EventLogFile
        WHERE
          EventType = 'DatabaseSave'
          AND LogDate >= :startDate
          AND LogDate < :endDate
        ORDER BY LogDate DESC
      ]
    );
  }

  public void execute(Database.BatchableContext bc, List<EventLogFile> scope) {
    if (existingDatabaseAuditMap.isEmpty()) {
      existingDatabaseAuditMap = getExistingAudits(logDate);
    }
    processEventLog(scope);
  }

  private void processEventLog(List<EventLogFile> eventLogs) {
    if (eventLogs.isEmpty())
      return;

    Map<String, String> objectPrefixVsObjectMap = new Map<String, String>();

    for (EventLogFile logFile : eventLogs) {
      try {
        String csvData = EventLogService.getEventLogCsv(logFile.Id);
        if (String.isBlank(csvData))
          continue;

        List<Map<String, String>> eventLogFileRows = DynamicCSVParser.parseCSV(
          csvData
        );
        if (eventLogFileRows.isEmpty())
          continue;

        for (Map<String, String> row : eventLogFileRows) {
          String userIdStr = row.get('USER_ID');
          String keyPrefix = row.get('KEY_PREFIX');
          String dmlType = row.get('DML_TYPE');
          String numRowsStr = row.get('NUM_ROWS');
          String timestampDerived = row.get('TIMESTAMP_DERIVED');

          if (
            String.isBlank(userIdStr) ||
            String.isBlank(keyPrefix) ||
            String.isBlank(dmlType) ||
            String.isBlank(numRowsStr) ||
            String.isBlank(timestampDerived)
          ) {
            continue;
          }

          Integer numRows = Integer.valueOf(numRowsStr);
          Id userId;
          try {
            userId = Id.valueOf(userIdStr);
          } catch (Exception e) {
            continue;
          }

          String objectName;
          if (objectPrefixVsObjectMap.containsKey(keyPrefix)) {
            objectName = objectPrefixVsObjectMap.get(keyPrefix);
          } else {
            objectName = SchemaService.getSObjectNameFromPrefix(keyPrefix);
            if (String.isBlank(objectName))
              continue;
            objectPrefixVsObjectMap.put(keyPrefix, objectName);
          }

          if (objectName == 'EventLogFile')
            continue;

          String key = buildKey(userId, objectName, dmlType, logDate);

          userObjectOperationCountMap.put(
            key,
            userObjectOperationCountMap.containsKey(key)
              ? userObjectOperationCountMap.get(key) + numRows
              : numRows
          );
        }
      } catch (Exception e) {
        System.debug(
          'Error processing EventLogFile ' + logFile.Id + ' : ' + e.getMessage()
        );
      }
    }

    List<Database_Audit__c> recordsToUpsert = new List<Database_Audit__c>();

    for (String key : userObjectOperationCountMap.keySet()) {
      Integer countToAdd = userObjectOperationCountMap.get(key);
      if (countToAdd == null || countToAdd == 0)
        continue;

      List<String> parts = key.split('\\|');
      Id userId = Id.valueOf(parts[0]);
      String objectName = parts[1];
      String operation = parts[2];
      Date logDateValue = Date.valueOf(parts[3]);

      Database_Audit__c recordToUpsert;

      if (existingDatabaseAuditMap.containsKey(key)) {
        Database_Audit__c existingRecord = existingDatabaseAuditMap.get(key);
        recordToUpsert = new Database_Audit__c(
          Id = existingRecord.Id,
          Record_Count__c = countToAdd
        );
      } else {
        recordToUpsert = new Database_Audit__c(
          User__c = userId,
          ObjectName__c = objectName,
          Operation__c = operation,
          LogDate__c = logDateValue,
          Record_Count__c = countToAdd,
          OwnerId = UserInfo.getUserId()
        );
      }

      recordsToUpsert.add(recordToUpsert);
    }

    try {
      if (!recordsToUpsert.isEmpty()) {
        upsert recordsToUpsert;
      }
    } catch (Exception e) {
      System.debug('Upsert failed: ' + e.getMessage());
    }
  }

  @TestVisible
  public Map<String, Database_Audit__c> getExistingAudits(Date logDate) {
    Map<String, Database_Audit__c> auditMap = new Map<String, Database_Audit__c>();

    for (Database_Audit__c rec : [
      SELECT
        Id,
        User__c,
        ObjectName__c,
        Operation__c,
        Record_Count__c,
        LogDate__c
      FROM Database_Audit__c
      WHERE LogDate__c = :logDate
    ]) {
      String key = buildKey(
        rec.User__c,
        rec.ObjectName__c,
        rec.Operation__c,
        rec.LogDate__c
      );
      auditMap.put(key, rec);
    }

    return auditMap;
  }
  for (Map<String, String> row : eventLogFileRows) {
    String userIdStr = row.get('USER_ID');
    String keyPrefix = row.get('KEY_PREFIX');
    String dmlType = row.get('DML_TYPE');
    String numRowsStr = row.get('NUM_ROWS');
    String timestampDerived = row.get('TIMESTAMP_DERIVED');

    if (
      String.isBlank(userIdStr) ||
      String.isBlank(keyPrefix) ||
      String.isBlank(dmlType) ||
      String.isBlank(numRowsStr) ||
      String.isBlank(timestampDerived)
    ) {
      continue;
    }

    Integer numRows = Integer.valueOf(numRowsStr);
    Id userId;
    try {
      userId = Id.valueOf(userIdStr);
    } catch (Exception e) {
      continue;
    }

    String objectName;
    if (objectPrefixVsObjectMap.containsKey(keyPrefix)) {
      objectName = objectPrefixVsObjectMap.get(keyPrefix);
    } else {
      objectName = SchemaService.getSObjectNameFromPrefix(keyPrefix);
      if (String.isBlank(objectName))
        continue;
      objectPrefixVsObjectMap.put(keyPrefix, objectName);
    }

    if (objectName == 'EventLogFile')
      continue;

    String key = buildKey(userId, objectName, dmlType, logDate);

    userObjectOperationCountMap.put(
      key,
      userObjectOperationCountMap.containsKey(key)
        ? userObjectOperationCountMap.get(key) + numRows
        : numRows
    );
  }
} catch (Exception e) {
  System.debug(
    'Error processing EventLogFile ' + logFile.Id + ' : ' + e.getMessage()
  );
}
}

List<Database_Audit__c> recordsToUpsert = new List<Database_Audit__c>();

for (String key : userObjectOperationCountMap.keySet()) {
Integer countToAdd = userObjectOperationCountMap.get(key);
if (countToAdd == null || countToAdd == 0)
  continue;

List<String> parts = key.split('\\|');
Id userId = Id.valueOf(parts[0]);
String objectName = parts[1];
String operation = parts[2];
Date logDateValue = Date.valueOf(parts[3]);

Database_Audit__c recordToUpsert;

if (existingDatabaseAuditMap.containsKey(key)) {
  Database_Audit__c existingRecord = existingDatabaseAuditMap.get(key);
  recordToUpsert = new Database_Audit__c(
    Id = existingRecord.Id,
    Record_Count__c = countToAdd
  );
} else {
  recordToUpsert = new Database_Audit__c(
    User__c = userId,
    ObjectName__c = objectName,
    Operation__c = operation,
    LogDate__c = logDateValue,
    Record_Count__c = countToAdd,
    OwnerId = UserInfo.getUserId()
  );
}

recordsToUpsert.add(recordToUpsert);
}

try {
if (!recordsToUpsert.isEmpty()) {
  upsert recordsToUpsert;
}
} catch (Exception e) {
System.debug('Upsert failed: ' + e.getMessage());
}


@TestVisible
public Map<String, Database_Audit__c> getExistingAudits(Date logDate) {
Map<String, Database_Audit__c> auditMap = new Map<String, Database_Audit__c>();

for (Database_Audit__c rec : [
SELECT
  Id,
  User__c,
  ObjectName__c,
  Operation__c,
  Record_Count__c,
  LogDate__c
FROM Database_Audit__c
WHERE LogDate__c = :logDate
]) {
String key = buildKey(
  rec.User__c,
  rec.ObjectName__c,
  rec.Operation__c,
  rec.LogDate__c
);
auditMap.put(key, rec);
}

return auditMap;
}

  private static String buildKey(
    Id userId,
    String objectName,
    String operation,
    Date logDate
  ) {
    String monthStr = (logDate.month() < 10)
      ? '0' + String.valueOf(logDate.month())
      : String.valueOf(logDate.month());
    String dayStr = (logDate.day() < 10)
      ? '0' + String.valueOf(logDate.day())
      : String.valueOf(logDate.day());

    String formattedDate = logDate.year() + '-' + monthStr + '-' + dayStr;
    String normalizedOperation = (operation != null)
      ? operation.toUpperCase()
      : '';

    return userId +
      '|' +
      objectName +
      '|' +
      normalizedOperation +
      '|' +
      formattedDate;
  }

  public void finish(Database.BatchableContext bc) {
  }
}
