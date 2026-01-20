/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 01-20-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public with sharing class PermissionSetsAuditController {
  @AuraEnabled(cacheable=true)
  public static List<PermissionSetAuditWrapper> getPrivilegedPermissionSets() {
    // Step 1: Fetch privileged permissions from Custom Metadata
    Set<String> privilegedPerms = new Set<String>();
    for (Privileged_Permission__mdt perm : [
      SELECT Permission_API_Name__c
      FROM Privileged_Permission__mdt
    ]) {
      privilegedPerms.add(perm.Permission_API_Name__c);
    }

    if (privilegedPerms.isEmpty()) {
      return new List<PermissionSetAuditWrapper>();
    }

    // Step 2: Get all fields of PermissionSet dynamically
    Map<String, Schema.SObjectField> psFields = Schema.SObjectType.PermissionSet.fields.getMap();
    Set<String> validPrivilegedPerms = new Set<String>();
    for (String permName : privilegedPerms) {
      if (psFields.containsKey(permName)) {
        validPrivilegedPerms.add(permName);
      }
    }
    if (validPrivilegedPerms.isEmpty())
      return new List<PermissionSetAuditWrapper>();

    // Step 3: Build dynamic SOQL query
    String query = 'SELECT Id, Label';
    for (String fieldName : validPrivilegedPerms) {
      query += ', ' + fieldName;
    }
    query += ' FROM PermissionSet WHERE IsOwnedByProfile = false';

    List<SObject> permSets = Database.query(query);

    // Step 4: Get all user counts in one query
    Map<Id, Integer> psUserCountMap = new Map<Id, Integer>();
    for (AggregateResult ar : [
      SELECT PermissionSetId psId, COUNT(Id) cnt
      FROM PermissionSetAssignment
      WHERE PermissionSetId IN :permSets
      GROUP BY PermissionSetId
    ]) {
      psUserCountMap.put((Id) ar.get('psId'), (Integer) ar.get('cnt'));
    }

    // Step 5: Loop through permission sets
    Map<Id, PermissionSetAuditWrapper> wrapperMap = new Map<Id, PermissionSetAuditWrapper>();

    for (SObject ps : permSets) {
      List<String> enabledPermLabels = new List<String>();
      for (String permName : validPrivilegedPerms) {
        if (ps.get(permName) == true) {
          String label = psFields.get(permName).getDescribe().getLabel();
          enabledPermLabels.add(label);
        }
      }

      if (!enabledPermLabels.isEmpty()) {
        Id psId = (Id) ps.get('Id');

        if (!wrapperMap.containsKey(psId)) {
          Integer userCount = psUserCountMap.containsKey(psId)
            ? psUserCountMap.get(psId)
            : 0;

          // Calculate object count (View All or Modify All)
          Integer objCount = 0;
          for (ObjectPermissions op : [
            SELECT PermissionsViewAllRecords, PermissionsModifyAllRecords
            FROM ObjectPermissions
            WHERE ParentId = :psId
          ]) {
            if (
              op.PermissionsViewAllRecords || op.PermissionsModifyAllRecords
            ) {
              objCount++;
            }
          }

          wrapperMap.put(
            psId,
            new PermissionSetAuditWrapper(
              psId,
              (String) ps.get('Label'),
              userCount,
              enabledPermLabels,
              objCount
            )
          );
        }
      }
    }

    return wrapperMap.values();
  }

  public class PermissionSetAuditWrapper {
    @AuraEnabled
    public Id permissionSetId;
    @AuraEnabled
    public String permissionSetName;
    @AuraEnabled
    public Integer assignedUserCount;
    @AuraEnabled
    public String assignedPermissions;
    @AuraEnabled
    public Integer objectCount; // <-- NEW

    public PermissionSetAuditWrapper(
      Id id,
      String name,
      Integer count,
      List<String> enabledPermLabels,
      Integer objCount
    ) {
      this.permissionSetId = id;
      this.permissionSetName = name;
      this.assignedUserCount = count;
      this.assignedPermissions = String.join(enabledPermLabels, ', ');
      this.objectCount = objCount;
    }
  }

  public class ObjPerm {
    @AuraEnabled
    public String sObjectType;
    @AuraEnabled
    public String objectLabel;
    @AuraEnabled
    public Boolean createPerm;
    @AuraEnabled
    public Boolean readPerm;
    @AuraEnabled
    public Boolean editPerm;
    @AuraEnabled
    public Boolean deletePerm;
    @AuraEnabled
    public Boolean viewAll;
    @AuraEnabled
    public Boolean modifyAll;
  }

  @AuraEnabled(cacheable=true)
  public static List<ObjPerm> getPermissionSetPermissions(Id permissionSetId) {
    List<ObjectPermissions> perms = [
      SELECT
        Id,
        PermissionsCreate,
        PermissionsRead,
        PermissionsEdit,
        PermissionsDelete,
        PermissionsViewAllRecords,
        PermissionsModifyAllRecords,
        SObjectType,  
        ParentId
      FROM ObjectPermissions
      WHERE ParentId = :permissionSetId
      ORDER BY SObjectType
    ];

    Set<String> apiNames = new Set<String>();
    for (ObjectPermissions p : perms)
      apiNames.add(p.SObjectType);

    Map<String, String> apiToLabelMap = new Map<String, String>();
    for (EntityDefinition ed : [
      SELECT QualifiedApiName, Label
      FROM EntityDefinition
      WHERE QualifiedApiName IN :apiNames
    ]) {
      apiToLabelMap.put(ed.QualifiedApiName, ed.Label);
    }

    List<ObjPerm> results = new List<ObjPerm>();
    for (ObjectPermissions op : perms) {
      if (!apiToLabelMap.containsKey(op.SObjectType) || !op.PermissionsRead)
        continue;

      ObjPerm p = new ObjPerm();
      p.sObjectType = op.SObjectType;
      p.objectLabel = apiToLabelMap.get(op.SObjectType);
      p.createPerm = op.PermissionsCreate;
      p.readPerm = op.PermissionsRead;
      p.editPerm = op.PermissionsEdit;
      p.deletePerm = op.PermissionsDelete;
      p.viewAll = op.PermissionsViewAllRecords;
      p.modifyAll = op.PermissionsModifyAllRecords;
      results.add(p);
    }
    return results;
  }
  @AuraEnabled(cacheable=true)
  public static List<PermissionSetAuditWrapper> getPrivilegedPermissionSets() {
    // Step 1: Fetch privileged permissions from Custom Metadata
    Set<String> privilegedPerms = new Set<String>();
    for (Privileged_Permission__mdt perm : [
      SELECT Permission_API_Name__c
      FROM Privileged_Permission__mdt
    ]) {
      privilegedPerms.add(perm.Permission_API_Name__c);
    }

    if (privilegedPerms.isEmpty()) {
      return new List<PermissionSetAuditWrapper>();
    }

    // Step 2: Get all fields of PermissionSet dynamically
    Map<String, Schema.SObjectField> psFields = Schema.SObjectType.PermissionSet.fields.getMap();
    Set<String> validPrivilegedPerms = new Set<String>();
    for (String permName : privilegedPerms) {
      if (psFields.containsKey(permName)) {
        validPrivilegedPerms.add(permName);
      }
    }
    if (validPrivilegedPerms.isEmpty())
      return new List<PermissionSetAuditWrapper>();

    // Step 3: Build dynamic SOQL query
    String query = 'SELECT Id, Label';
    for (String fieldName : validPrivilegedPerms) {
      query += ', ' + fieldName;
    }
    query += ' FROM PermissionSet WHERE IsOwnedByProfile = false';

    List<SObject> permSets = Database.query(query);

    // Step 4: Get all user counts in one query
    Map<Id, Integer> psUserCountMap = new Map<Id, Integer>();
    for (AggregateResult ar : [
      SELECT PermissionSetId psId, COUNT(Id) cnt
      FROM PermissionSetAssignment
      WHERE PermissionSetId IN :permSets
      GROUP BY PermissionSetId
    ]) {
      psUserCountMap.put((Id) ar.get('psId'), (Integer) ar.get('cnt'));
    }

    // Step 5: Loop through permission sets
    Map<Id, PermissionSetAuditWrapper> wrapperMap = new Map<Id, PermissionSetAuditWrapper>();

    for (SObject ps : permSets) {
      List<String> enabledPermLabels = new List<String>();
      for (String permName : validPrivilegedPerms) {
        if (ps.get(permName) == true) {
          String label = psFields.get(permName).getDescribe().getLabel();
          enabledPermLabels.add(label);
        }
      }

      if (!enabledPermLabels.isEmpty()) {
        Id psId = (Id) ps.get('Id');

        if (!wrapperMap.containsKey(psId)) {
          Integer userCount = psUserCountMap.containsKey(psId)
            ? psUserCountMap.get(psId)
            : 0;

          // Calculate object count (View All or Modify All)
          Integer objCount = 0;
          for (ObjectPermissions op : [
            SELECT PermissionsViewAllRecords, PermissionsModifyAllRecords
            FROM ObjectPermissions
            WHERE ParentId = :psId
          ]) {
            if (
              op.PermissionsViewAllRecords || op.PermissionsModifyAllRecords
            ) {
              objCount++;
            }
          }

          wrapperMap.put(
            psId,
            new PermissionSetAuditWrapper(
              psId,
              (String) ps.get('Label'),
              userCount,
              enabledPermLabels,
              objCount
            )
          );
        }
      }
    }

    return wrapperMap.values();
  }

  public class PermissionSetAuditWrapper {
    @AuraEnabled
    public Id permissionSetId;
    @AuraEnabled
    public String permissionSetName;
    @AuraEnabled
    public Integer assignedUserCount;
    @AuraEnabled
    public String assignedPermissions;
    @AuraEnabled
    public Integer objectCount; // <-- NEW

    public PermissionSetAuditWrapper(
      Id id,
      String name,
      Integer count,
      List<String> enabledPermLabels,
      Integer objCount
    ) {
      this.permissionSetId = id;
      this.permissionSetName = name;
      this.assignedUserCount = count;
      this.assignedPermissions = String.join(enabledPermLabels, ', ');
      this.objectCount = objCount;
    }
  }

  public class ObjPerm {
    @AuraEnabled
    public String sObjectType;
    @AuraEnabled
    public String objectLabel;
    @AuraEnabled
    public Boolean createPerm;
    @AuraEnabled
    public Boolean readPerm;
    @AuraEnabled
    public Boolean editPerm;
    @AuraEnabled
    public Boolean deletePerm;
    @AuraEnabled
    public Boolean viewAll;
    @AuraEnabled
    public Boolean modifyAll;
  }

  @AuraEnabled(cacheable=true)
  public static List<ObjPerm> getPermissionSetPermissions(Id permissionSetId) {
    List<ObjectPermissions> perms = [
      SELECT
        Id,
        PermissionsCreate,
        PermissionsRead,
        PermissionsEdit,
        PermissionsDelete,
        PermissionsViewAllRecords,
        PermissionsModifyAllRecords,
        SObjectType,
        ParentId
      FROM ObjectPermissions
      WHERE ParentId = :permissionSetId
      ORDER BY SObjectType
    ];

    Set<String> apiNames = new Set<String>();
    for (ObjectPermissions p : perms)
      apiNames.add(p.SObjectType);

    Map<String, String> apiToLabelMap = new Map<String, String>();
    for (EntityDefinition ed : [
      SELECT QualifiedApiName, Label
      FROM EntityDefinition
      WHERE QualifiedApiName IN :apiNames
    ]) {
      apiToLabelMap.put(ed.QualifiedApiName, ed.Label);
    }''

    List<ObjPerm> results = new List<ObjPerm>();
    for (ObjectPermissions op : perms) {
      if (!apiToLabelMap.containsKey(op.SObjectType) || !op.PermissionsRead)
        continue;

      ObjPerm p = new ObjPerm();
      p.sObjectType = op.SObjectType;
      p.objectLabel = apiToLabelMap.get(op.SObjectType);
      p.createPerm = op.PermissionsCreate;
      p.readPerm = op.PermissionsRead;
      p.editPerm = op.PermissionsEdit;
      p.deletePerm = op.PermissionsDelete;
      p.viewAll = op.PermissionsViewAllRecords;
      p.modifyAll = op.PermissionsModifyAllRecords;
      results.add(p);
    }
    return results;
  }
}
