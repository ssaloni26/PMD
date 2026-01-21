/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 01-21-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public with sharing class DmlCsvAuditBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
  //Run batch by
  //Date logDate = Date.newInstance(2025, 10, 11);
  //Database.executeBatch(new DmlCsvAuditBatch(logDate), 100);

  private Date logDate;

  public DmlCsvAuditBatch(Date logDate) {
    this.logDate = logDate;
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    Datetime startDate = Datetime.newInstanceGmt(
      logDate.year(),
      logDate.month(),
      logDate.day(),
      0,
      0,
      0
    );
    Datetime endDate = startDate.addDays(1);

    System.debug(
      '| startDate GMT: ' + startDate + ' | endDate GMT: ' + endDate
    );

    return Database.getQueryLocator(
      [
        SELECT Id, EventType, LogDate
        FROM EventLogFile
        WHERE
          EventType = 'DatabaseSave'
          AND Interval IN ('Hourly')
          AND LogDate >= :startDate
          AND LogDate < :endDate
        ORDER BY LogDate DESC
      ]
    );
  }

  public void execute(Database.BatchableContext bc, List<EventLogFile> scope) {
    if (scope.isEmpty())
      return;

    Set<String> existingKeys = new Set<String>();
    for (DML_Audit__c a : [
      SELECT User__c, ObjectName__c, Operation__c
      FROM DML_Audit__c
      WHERE LogDate__c = :logDate
    ]) {
      existingKeys.add(
        a.User__c + '|' + a.ObjectName__c + '|' + a.Operation__c
      );
    }

    Map<String, Integer> flatCounts = new Map<String, Integer>();

    Map<String, String> prefixCache = new Map<String, String>();

    Http http = new Http();

    for (EventLogFile elf : scope) {
      try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
          URL.getOrgDomainUrl().toExternalForm() +
            '/services/data/v61.0/sobjects/EventLogFile/' +
            elf.Id +
            '/LogFile'
        );
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 200)
          continue;

        String csv = res.getBodyAsBlob().toString();
        if (String.isBlank(csv))
          continue;

        List<String> rows = csv.split('\n');
        if (rows.size() < 2)
          continue;

        List<String> headers = rows[0].replaceAll('"', '').split(',');
        Integer userCol = headers.indexOf('USER_ID');
        Integer dmlCol = headers.indexOf('DML_TYPE');
        Integer numRowsCol = headers.indexOf('NUM_ROWS');
        Integer keyPrefixCol = headers.indexOf('KEY_PREFIX');

        if (
          userCol == -1 ||
          dmlCol == -1 ||
          numRowsCol == -1 ||
          keyPrefixCol == -1
        )
          continue;

        for (Integer i = 1; i < rows.size(); i++) {
          String row = rows[i].replaceAll('"', '');
          if (String.isBlank(row))
            continue;

          List<String> cols = row.split(',');
          if (
            cols.size() <=
            Math.max(
              userCol,
              Math.max(dmlCol, Math.max(numRowsCol, keyPrefixCol))
            )
          )
            continue;

          String userIdStr = cols[userCol];
          String keyPrefix = cols[keyPrefixCol];
          String dmlType = cols[dmlCol];
          Integer numRows = Integer.valueOf(cols[numRowsCol]);

          if (String.isBlank(keyPrefix))
            continue;

          Id userId;
          try {
            userId = Id.valueOf(userIdStr);
          } catch (Exception e) {
            continue;
          }
          String objectName;
          if (prefixCache.containsKey(keyPrefix)) {
            objectName = prefixCache.get(keyPrefix);
          } else {
            objectName = SchemaGlobalDescribe.findObjectNameFromRecordIdPrefix(
              keyPrefix
            );

            if (String.isBlank(objectName)) {
              continue;
            }
            prefixCache.put(keyPrefix, objectName);
          }

          if (objectName == 'EventLogFile')
            continue;

          String flatKey = userId + '|' + objectName + '|' + dmlType;
          flatCounts.put(
            flatKey,
            flatCounts.get(flatKey) == null
              ? numRows
              : flatCounts.get(flatKey) + numRows
          );
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing EventLogFile Id=' + elf.Id + ' : ' + ex.getMessage()
        );
      }
    }

    List<DML_Audit__c> inserts = new List<DML_Audit__c>();
    for (String key : flatCounts.keySet()) {
      if (!existingKeys.contains(key)) {
        List<String> parts = key.split('\\|');
        inserts.add(
          new DML_Audit__c(
            User__c = Id.valueOf(parts[0]),
            ObjectName__c = parts[1],
            Operation__c = parts[2],
            Count__c = flatCounts.get(key),
            LogDate__c = logDate,
            OwnerId = UserInfo.getUserId()
          )
        );
      }
    }
    if (!inserts.isEmpty())
      insert inserts;
  }

  public void finish(Database.BatchableContext bc) {
    System.debug('DML audit batch completed for ' + logDate);
  }
  public DmlCsvAuditBatch(Date logDate) {
    this.logDate = logDate;
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    Datetime startDate = Datetime.newInstanceGmt(
      logDate.year(),
      logDate.month(),
      logDate.day(),
      0,
      0,
      0
    );
    Datetime endDate = startDate.addDays(1);

    System.debug(
      '| startDate GMT: ' + startDate + ' | endDate GMT: ' + endDate
    );

    return Database.getQueryLocator(
      [
        SELECT Id, EventType, LogDate
        FROM EventLogFile
        WHERE
          EventType = 'DatabaseSave'
          AND Interval IN ('Hourly')
          AND LogDate >= :startDate
          AND LogDate < :endDate
        ORDER BY LogDate DESC
      ]
    );
  }

  public void execute(Database.BatchableContext bc, List<EventLogFile> scope) {
    if (scope.isEmpty())
      return;

    Set<String> existingKeys = new Set<String>();
    for (DML_Audit__c a : [
      SELECT User__c, ObjectName__c, Operation__c
      FROM DML_Audit__c
      WHERE LogDate__c = :logDate
    ]) {
      existingKeys.add(
        a.User__c + '|' + a.ObjectName__c + '|' + a.Operation__c
      );
    }

    Map<String, Integer> flatCounts = new Map<String, Integer>();

    Map<String, String> prefixCache = new Map<String, String>();

    Http http = new Http();

    for (EventLogFile elf : scope) {
      try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
          URL.getOrgDomainUrl().toExternalForm() +
            '/services/data/v61.0/sobjects/EventLogFile/' +
            elf.Id +
            '/LogFile'
        );
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 200)
          continue;

        String csv = res.getBodyAsBlob().toString();
        if (String.isBlank(csv))
          continue;

        List<String> rows = csv.split('\n');
        if (rows.size() < 2)
          continue;

        List<String> headers = rows[0].replaceAll('"', '').split(',');
        Integer userCol = headers.indexOf('USER_ID');
        Integer dmlCol = headers.indexOf('DML_TYPE');
        Integer numRowsCol = headers.indexOf('NUM_ROWS');
        Integer keyPrefixCol = headers.indexOf('KEY_PREFIX');

        if (
          userCol == -1 ||
          dmlCol == -1 ||
          numRowsCol == -1 ||
          keyPrefixCol == -1
        )
          continue;

        for (Integer i = 1; i < rows.size(); i++) {
          String row = rows[i].replaceAll('"', '');
          if (String.isBlank(row))
            continue;

          List<String> cols = row.split(',');
          if (
            cols.size() <=
            Math.max(
              userCol,
              Math.max(dmlCol, Math.max(numRowsCol, keyPrefixCol))
            )
          )
            continue;

          String userIdStr = cols[userCol];
          String keyPrefix = cols[keyPrefixCol];
          String dmlType = cols[dmlCol];
          Integer numRows = Integer.valueOf(cols[numRowsCol]);

          if (String.isBlank(keyPrefix))
            continue;

          Id userId;
          try {
            userId = Id.valueOf(userIdStr);
          } catch (Exception e) {
            continue;
          }
          String objectName;
          if (prefixCache.containsKey(keyPrefix)) {
            objectName = prefixCache.get(keyPrefix);
          } else {
            objectName = SchemaGlobalDescribe.findObjectNameFromRecordIdPrefix(
              keyPrefix
            );

            if (String.isBlank(objectName)) {
              continue;
            }
            prefixCache.put(keyPrefix, objectName);
          }

          if (objectName == 'EventLogFile')
            continue;

          String flatKey = userId + '|' + objectName + '|' + dmlType;
          flatCounts.put(
            flatKey,
            flatCounts.get(flatKey) == null
              ? numRows
              : flatCounts.get(flatKey) + numRows
          );
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing EventLogFile Id=' + elf.Id + ' : ' + ex.getMessage()
        );
      }
    }

    List<DML_Audit__c> inserts = new List<DML_Audit__c>();
    for (String key : flatCounts.keySet()) {
      if (!existingKeys.contains(key)) {
        List<String> parts = key.split('\\|');
        inserts.add(
          new DML_Audit__c(
            User__c = Id.valueOf(parts[0]),
            ObjectName__c = parts[1],
            Operation__c = parts[2],
            Count__c = flatCounts.get(key),
            LogDate__c = logDate,
            OwnerId = UserInfo.getUserId()
          )
        );
      }
    }
    if (!inserts.isEmpty())
      insert inserts;
  }

  public void finish(Database.BatchableContext bc) {
    System.debug('DML audit batch completed for ' + logDate);
  }
}
