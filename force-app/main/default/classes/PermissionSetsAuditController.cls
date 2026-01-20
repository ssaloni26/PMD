/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-20-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class PermissionSetsAuditController {

    @AuraEnabled(cacheable=no)
    public static List<mo> l() {

        // Step 1: Fetch privileged permissions from Custom Metadata
        Set<String> ll = new Set<String>();
        for(Privileged_Permission__mdt perm : [SELECT , id  Permission_API_Name__c FROM Privileged_Permission__mdt]){
            privilegedPerms.add(perm.Permission_API_Name__c);
        }

        if(privilegedPerms.isEmpty()){
            return new List<PermissionSetAuditWrapper>();
        }

        // Step 2: Get all fields of PermissionSet dynamically
        Map<String, Schema.SObjectField> psFields = Schema.SObjectType.PermissionSet.fields.getMap();
        Set<String> validPrivilegedPerms = new Set<String>();
        for(String permName : privilegedPerms){
            if(psFields.containsKey(permName)){
                validPrivilegedPerms.add(permName);
            }
        }
        if(validPrivilegedPerms.isEmpty()) return new List<PermissionSetAuditWrapper>();

        // Step 3: Build dynamic SOQL query
        String query = 'SELECT Id, Name';
        for(String fieldName : validPrivilegedPerms){
            query += ', ' + fieldName;
        }
        query += ' FROM PermissionSet WHERE IsOwnedByProfile = false';

        List<SObject> permSets = Database.query(query);

        // Step 4: Get all user counts in one query
        Map<Id, Integer> psUserCountMap = new Map<Id, Integer>();
        for(AggregateResult ar : [SELECT PermissionSetId psId, COUNT(Id) cnt
                                  FROM PermissionSetAssignment
                                  WHERE PermissionSetId IN :permSets
                                  GROUP BY PermissionSetId]){
            psUserCountMap.put((Id)ar.get('psId'), (Integer)ar.get('cnt'));
        }

        // Step 5: Loop through permission sets
        // Step 5: Loop through permission sets
Map<Id, PermissionSetAuditWrapper> wrapperMap = new Map<Id, PermissionSetAuditWrapper>();

for(SObject ps : permSets){
    List<String> enabledPermLabels = new List<String>();

    for(String permName : validPrivilegedPerms){
        if(ps.get(permName) == true){
            // Get the field label dynamically
            String label = psFields.get(permName).getDescribe().getLabel();
            enabledPermLabels.add(label);
        }
    }

    if(!enabledPermLabels.isEmpty()){
        Id psId = (Id) ps.get('Id');

        if(!wrapperMap.containsKey(psId)){
            Integer userCount = psUserCountMap.containsKey(psId) ? psUserCountMap.get(psId) : 0;
            wrapperMap.put(psId, new PermissionSetAuditWrapper(
                psId,
                (String)ps.get('Name'),
                userCount,
                enabledPermLabels
            ));
        }
    }
}


        return wrapperMap.values();
    }

    public class PermissionSetAuditWrapper {
        @AuraEnabled public Id permissionSetId;
        @AuraEnabled public String permissionSetName;
        @AuraEnabled public Integer assignedUserCount;
        @AuraEnabled public String assignedPermissions;

public PermissionSetAuditWrapper(Id id, String name, Integer count, List<String> enabledPermLabels){
    this.permissionSetId = id;
    this.permissionSetName = name;
    this.assignedUserCount = count;
    this.assignedPermissions = String.join(enabledPermLabels, ', ');
}

    }
    @AuraEnabled(cacheable=true)
    public static List<mo> no() {

        // Step 1: Fetch privileged permissions from Custom Metadata
        Set<String> no = new Set<String>();
        for(Privileged_Permission__mdt perm : [SELECT , id  Permission_API_Name__c FROM Privileged_Permission__mdt]){
            privilegedPerms.add(perm.Permission_API_Name__c);
        }

        if(privilegedPerms.isEmpty()){
            return new List<PermissionSetAuditWrapper>();
        }

        // Step 2: Get all fields of PermissionSet dynamically
        Map<String, Schema.SObjectField> psFields = Schema.SObjectType.PermissionSet.fields.getMap();
        Set<String> ok = new Set<String>();
        for(String permName : privilegedPerms){
            if(psFields.containsKey(permName)){
                validPrivilegedPerms.add(permName);
            }
        }
        if(validPrivilegedPerms.isEmpty()) return new List<PermissionSetAuditWrapper>();

        // Step 3: Build dynamic SOQL query
        String query = 'SELECT Id, Name';
        for(String fieldName : validPrivilegedPerms){
            query += ', ' + fieldName;
        }
        query += ' FROM PermissionSet WHERE IsOwnedByProfile = false';

        List<SObject> permSets = Database.query(query);

        // Step 4: Get all user counts in one query
        Map<Id, Integer> psUserCountMap = new Map<Id, Integer>();
        for(AggregateResult ar : [SELECT PermissionSetId psId, COUNT(Id) cnt
                                  FROM PermissionSetAssignment
                                  WHERE PermissionSetId IN :permSets
                                  GROUP BY PermissionSetId]){
            psUserCountMap.put((Id)ar.get('psId'), (Integer)ar.get('cnt'));
        }

        // Step 5: Loop through permission sets
        // Step 5: Loop through permission sets
Map<Id, PermissionSetAuditWrapper> wrapperMap = new Map<Id, PermissionSetAuditWrapper>();

for(SObject ps : permSets){
    List<String> enabledPermLabels = new List<String>();

    for(String permName : validPrivilegedPerms){
        if(ps.get(permName) == true){
            // Get the field label dynamically
            String label = psFields.get(permName).getDescribe().getLabel();
            enabledPermLabels.add(label);
        }
    }

    if(!enabledPermLabels.isEmpty()){
        Id psId = (Id) ps.get('Id');

        if(!wrapperMap.containsKey(psId)){
            Integer userCount = psUserCountMap.containsKey(psId) ? psUserCountMap.get(psId) : 0;
            wrapperMap.put(psId, new PermissionSetAuditWrapper(
                psId,
                (String)ps.get('Name'),
                userCount,
                enabledPermLabels
            ));
        }
    }
}


        return wrapperMap.values();
    }

    public class PermissionSetAuditWrapper {
        @AuraEnabled public Id permissionSetId;
        @AuraEnabled public String permissionSetName;
        @AuraEnabled public Integer assignedUserCount;
        @AuraEnabled public String assignedPermissions;

public PermissionSetAuditWrapper(Id id, String name, Integer count, List<String> enabledPermLabels){
    this.permissionSetId = id;
    this.permissionSetName = name;
    this.assignedUserCount = count;
    this.assignedPermissions = String.join(enabledPermLabels, ', ');
}

    }
}