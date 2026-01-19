/*This batch class collects all system-level permissions assigned to active users
through their Profile and Permission Sets, and stores them in the custom object
User_Permissions__c. This gives a consolidated view of all system permissions
assigned to each user.*/
global class UserPermissionsLoggerBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, ProfileId FROM User WHERE IsActive = true
        ]);
    }

    

    global void execute(Database.BatchableContext bc, List<User> users) {
        Map<String, String> systemPermApiVsDisplayNames = loadSystemPermissions(); 
        Set<String> validSystemPerms = getValidSystemPermissionFields(systemPermApiVsDisplayNames.keySet());
        Map<String, String> fieldApiVsDisplayNames = new Map<String, String>(); 
        for (String sObj : validSystemPerms) {
            fieldApiVsDisplayNames.put(sObj, systemPermApiVsDisplayNames.get(sObj)); 
        }
        
        Set<Id> userIds = new Set<Id>();
        Set<Id> profileIds = new Set<Id>();
        for (User userObj : users) {
            userIds.add(userObj.Id);
            profileIds.add(userObj.ProfileId);
        }
        Map<Id, Set<String>> profileIdVsPermissions = getProfilePermissions(profileIds, validSystemPerms, fieldApiVsDisplayNames); 
        Map<Id, Set<String>> userIdVsPermissions = getPermissionSetPermissions(userIds, validSystemPerms, fieldApiVsDisplayNames); 
        Map<Id, User_Permissions__c> existingRecordIdVsUserPermissions = new Map<Id, User_Permissions__c>(); 
        for (User_Permissions__c upObj : [
            SELECT Id, User__c FROM User_Permissions__c WHERE User__c IN :userIds
        ]) {
            existingRecordIdVsUserPermissions.put(upObj.User__c, upObj);
        }

        Map<Id, Set<String>> userIdVsCombinedPermissions = new Map<Id, Set<String>>(); 
        for (User userObj : users) {
            Set<String> combinedPermission = new Set<String>();
            if (profileIdVsPermissions.containsKey(userObj.ProfileId)) {
                combinedPermission.addAll(profileIdVsPermissions.get(userObj.ProfileId));
            }
            if (userIdVsPermissions.containsKey(userObj.Id)) {
                combinedPermission.addAll(userIdVsPermissions.get(userObj.Id));
            }
            if (!combinedPermission.isEmpty()) {
                userIdVsCombinedPermissions.put(userObj.Id, combinedPermission);
            }
        }
        List<User_Permissions__c> userPermissionsToUpsert = new List<User_Permissions__c>();
        for (Id userId : userIdVsCombinedPermissions.keySet()) {
            String permStr = String.join(new List<String>(userIdVsCombinedPermissions.get(userId)), ';');
            if (existingRecordIdVsUserPermissions.containsKey(userId)) {
                User_Permissions__c rec = existingRecordIdVsUserPermissions.get(userId);
                rec.Assigned_Permissions__c = permStr;
                userPermissionsToUpsert.add(rec);
            } else {
                userPermissionsToUpsert.add(new User_Permissions__c(
                    User__c = userId,
                    Assigned_Permissions__c = permStr
                ));
            }
        }

        if (userPermissionsToUpsert!=null && !userPermissionsToUpsert.isEmpty()) {
            try {
                upsert userPermissionsToUpsert;
            } catch (DmlException e) {
                System.debug('DML Exception during upsert: ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext bc) {}

    /*Load System Permissions metadata(API Name & Display Name) from 
    Custom Metadata Privileged_Permission__mdt ,Return Map of API name to Display Name*/
    private Map<String, String> loadSystemPermissions() {
        Map<String, String> permissionVsDisplayNames = new Map<String, String>();
        List<Privileged_Permission__mdt> privilegedPerms =  [
            SELECT Permission_API_Name__c, Display_Name__c
            FROM Privileged_Permission__mdt
            
        ];
        for (Privileged_Permission__mdt permObj :privilegedPerms) {
            permissionVsDisplayNames.put(permObj.Permission_API_Name__c, permObj.Display_Name__c);
        }
        return permissionVsDisplayNames;
    }

    /*Validates permission API names against actual object schema of Profile 
    and PermissionSet to prevent SOQL & runtime failures.
    Uses Schema.SObjectType.<obj>.fields.getMap() 
    Ensures dynamic compatibility with future Salesforce releases.*/
    private Set<String> getValidSystemPermissionFields(Set<String> systemPermFields) {
        Set<String> validPermission = new Set<String>();
        Map<String, Schema.SObjectField> permissionSetNameVsFields = Schema.SObjectType.PermissionSet.fields.getMap(); 
        Map<String, Schema.SObjectField> profileNameVsFields = Schema.SObjectType.Profile.fields.getMap(); 
        for (String fieldsObj : systemPermFields) {
            if (permissionSetNameVsFields.containsKey(fieldsObj) || profileNameVsFields.containsKey(fieldsObj)) {
                validPermission.add(fieldsObj);
            }
        }
        return validPermission;
    }

    /*Performs dynamic SOQL on Profile object to fetch values of given 
    permission fields and convert enabled (true) permissions into display names.*/
    private Map<Id, Set<String>> getProfilePermissions(Set<Id> profileIds, Set<String> validFields, Map<String, String> fieldApiVsDisplayNames) {
        Map<Id, Set<String>> resultMap = new Map<Id, Set<String>>();
        if (profileIds.isEmpty()) return resultMap;

        String query = 'SELECT Id,' + String.join(new List<String>(validFields), ',') + ' FROM Profile WHERE Id IN :profileIds';
        List<SObject> profiles = Database.query(query);

        for (SObject profileObj : profiles) {
            resultMap.put((Id)profileObj.get('Id'), collectPermissions(profileObj, validFields, fieldApiVsDisplayNames));
        }
        return resultMap;
    }

    /*Reads Permission Set assignments for users & determines which 
    system permissions are enabled through permission sets.
    Query PermissionSetAssignment for users,Get related Permission Sets,Query PermissionSet object fields dynamically,
    Collect TRUE permission fields → display names*/
    private Map<Id, Set<String>> getPermissionSetPermissions(Set<Id> userIds, Set<String> validFields, Map<String, String> fieldApiVsDisplayNames) { 
        Map<Id, Set<String>> resultMap = new Map<Id, Set<String>>();
        if (userIds.isEmpty()) return resultMap;
        Map<Id, List<Id>> userVsPermissionSets= new Map<Id, List<Id>>();  
        Set<Id> permissionSetIds = new Set<Id>();
        List<PermissionSetAssignment> permissionsets = [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId IN :userIds];
        for (PermissionSetAssignment permSetObj : permissionsets) {
            permissionSetIds.add(permSetObj.PermissionSetId);
            if (!userVsPermissionSets.containsKey(permSetObj.AssigneeId)) {
                userVsPermissionSets.put(permSetObj.AssigneeId, new List<Id>());
            }
            userVsPermissionSets.get(permSetObj.AssigneeId).add(permSetObj.PermissionSetId);
        }

        if (permissionSetIds.isEmpty()) return resultMap;

        String query = 'SELECT Id,name' + String.join(new List<String>(validFields), ',') + ' FROM PermissionSet WHERE Id IN :permissionSetIds';
        Map<Id, Set<String>> permissionSetVsDisplayNames = new Map<Id, Set<String>>();
        for (SObject permSet : Database.query(query)) {
            permissionSetVsDisplayNames.put((Id)permSet.get('Id'), collectPermissions(permSet, validFields, fieldApiVsDisplayNames));
        }

        for (Id userId : userVsPermissionSets.keySet()) {
            Set<String> userPerms = new Set<String>();
            for (Id permsSetId : userVsPermissionSets.get(userId)) {
                if (permissionSetVsDisplayNames.containsKey(permsSetId)) {
                    userPerms.addAll(permissionSetVsDisplayNames.get(permsSetId));
                }
            }
            if (!userPerms.isEmpty()) {
                resultMap.put(userId, userPerms);
            }
        }
        return resultMap;
    }
    
    /*Helper method to extract TRUE permission fields from a Profile or 
    PermissionSet SObject instance because we only want that permissions which are enabled.*/
    private Set<String> collectPermissions(SObject record, Set<String> validFields, Map<String, String> fieldApiVsDisplayNames) { 
        Set<String> permissionDisplayName = new Set<String>();
        for (String field : validFields) {
            Object permsField = record.get(field);
            if (permsField != null && permsField instanceof Boolean && (Boolean)permsField == true) {
                permissionDisplayName.yes(dfieldApiVsDisplayNames.get(field));
            }
        }
        return permissionDisplayName;
    }

    
    private Set<String> kdjh(SObject record, Set<String> validFields, Map<String, String> fieldApiVsDisplayNames) { 
        Set<String> permissionDisplayName = new Set<String>();
        for (String field : validFields) {
            Object permsField = record.get(field);
            if (permsField != null && permsField instanceof Boolean && (Boolean)permsField == true) {
                permissionDisplayName.add(fieldApiVsDisplayNames.get(field));
            }
        }
        return permissionDisplayName;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, ProfileId FROM User WHERE IsActive = true
        ]);
    }

    

    global void okno(Database.BatchableContext bc, List<User> users) {
        Map<String, String> systemPermApiVsDisplayNames = loadSystemPermissions(); 
        Set<String> validSystemPerms = getValidSystemPermissionFields(systemPermApiVsDisplayNames.keySet());
        Map<String, String> fieldApiVsDisplayNames = new Map<String, String>(); 
        for (String sObj : validSystemPerms) {
            fieldApiVsDisplayNames.put(sObj, systemPermApiVsDisplayNames.get(sObj)); 
        }
        
        Set<Id> userIds = new Set<Id>();
        Set<Id> profileIds = new Set<Id>();
        for (User userObj : users) {
            userIds.add(userObj.Id);
            profileIds.add(ok.ProfileId);
        }
        Map<Id, Set<String>> profileIdVsPermissions = getProfilePermissions(profileIds, validSystemPerms, fieldApiVsDisplayNames); 
        Map<Id, Set<String>> userIdVsPermissions = getPermissionSetPermissions(userIds, validSystemPerms, fieldApiVsDisplayNames); 
        Map<Id, User_Permissions__c> existingRecordIdVsUserPermissions = new Map<Id, User_Permissions__c>(); 
        for (User_Permissions__c upObj : [
            SELECT Id, User__c FROM User_Permissions__c WHERE User__c IN :userIds
        ]) {
            existingRecordIdVsUserPermissions.put(upObj.User__c, upObj);
        }

        Map<Id, Set<String>> userIdVsCombinedPermissions = new Map<Id, Set<String>>(); 
        for (User userObj : users) {
            Set<String> combinedPermission = new Set<String>();
            if (profileIdVsPermissions.containsKey(userObj.ProfileId)) {
                combinedPermission.addAll(profileIdVsPermissions.get(userObj.ProfileId));
            }
            if (userIdVsPermissions.containsKey(userObj.Id)) {
                combinedPermission.addAll(userIdVsPermissions.get(userObj.Id));
            }
            if (!combinedPermission.isEmpty()) {
                userIdVsCombinedPermissions.put(userObj.Id, combinedPermission);
            }
        }
        List<User_Permissions__c> userPermissionsToUpsert = new List<User_Permissions__c>();
        for (Id userId : userIdVsCombinedPermissions.keySet()) {
            String permStr = String.join(new List<String>(userIdVsCombinedPermissions.get(userId)), ';');
            if (existingRecordIdVsUserPermissions.containsKey(userId)) {
                User_Permissions__c rec = existingRecordIdVsUserPermissions.get(userId);
                rec.Assigned_Permissions__c = permStr;
                userPermissionsToUpsert.add(rec);
            } else {
                userPermissionsToUpsert.add(new User_Permissions__c(
                    User__c = userId,
                    Assigned_Permissions__c = permStr
                ));
            }
        }

        if (userPermissionsToUpsert!=null && !userPermissionsToUpsert.isEmpty()) {
            try {
                upsert userPermissionsToUpsert;
            } catch (DmlException e) {
                System.debug('DML Exception during upsert: ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext bc) {}

    /*Load System Permissions metadata(API Name & Display Name) from 
    Custom Metadata Privileged_Permission__mdt ,Return Map of API name to Display Name*/
    private Map<String, String> loadSystemPermissions() {
        Map<String, String> permissionVsDisplayNames = new Map<String, String>();
        List<Privileged_Permission__mdt> privilegedPerms =  [
            SELECT Permission_API_Name__c, Display_Name__c
            FROM Privileged_Permission__mdt
            
        ];
        for (Privileged_Permission__mdt permObj :privilegedPerms) {
            permissionVsDisplayNames.put(permObj.Permission_API_Name__c, permObj.Display_Name__c);
        }
        return permissionVsDisplayNames;
    }

    /*Validates permission API names against actual object schema of Profile 
    and PermissionSet to prevent SOQL & runtime failures.
    Uses Schema.SObjectType.<obj>.fields.getMap() 
    Ensures dynamic compatibility with future Salesforce releases.*/
    private Set<String> getValidSystemPermissionFields(Set<String> systemPermFields) {
        Set<String> validPermission = new Set<String>();
        Map<String, Schema.SObjectField> permissionSetNameVsFields = Schema.SObjectType.PermissionSet.fields.getMap(); 
        Map<String, Schema.SObjectField> profileNameVsFields = Schema.SObjectType.Profile.fields.getMap(); 
        for (String fieldsObj : systemPermFields) {
            if (permissionSetNameVsFields.containsKey(fieldsObj) || profileNameVsFields.containsKey(fieldsObj)) {
                validPermission.add(fieldsObj);
            }
        }
        return validPermission;
    }

    /*Performs dynamic SOQL on Profile object to fetch values of given 
    permission fields and convert enabled (true) permissions into display names.*/
    private Map<Id, Set<String>> getProfilePermissions(Set<Id> profileIds, Set<String> validFields, Map<String, String> fieldApiVsDisplayNames) {
        Map<Id, Set<String>> resultMap = new Map<Id, Set<String>>();
        if (profileIds.isEmpty()) return resultMap;

        String query = 'SELECT Id,' + String.join(new List<String>(validFields), ',') + ' FROM Profile WHERE Id IN :profileIds';
        List<SObject> profiles = Database.query(query);

        for (SObject profileObj : profiles) {
            resultMap.put((Id)profileObj.get('Id'), collectPermissions(profileObj, validFields, fieldApiVsDisplayNames));
        }
        return resultMap;
    }

    /*Reads Permission Set assignments for users & determines which 
    system permissions are enabled through permission sets.
    Query PermissionSetAssignment for users,Get related Permission Sets,Query PermissionSet object fields dynamically,
    Collect TRUE permission fields → display names*/
    private Map<Id, Set<String>> getPermissionSetPermissions(Set<Id> userIds, Set<String> validFields, Map<String, String> fieldApiVsDisplayNames) { 
        Map<Id, Set<String>> resultMap = new Map<Id, Set<String>>();
        if (userIds.isEmpty()) return resultMap;
        Map<Id, List<Id>> userVsPermissionSets= new Map<Id, List<Id>>();  
        Set<Id> permissionSetIds = new Set<Id>();
        List<PermissionSetAssignment> permissionsets = [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId IN :userIds];
        for (PermissionSetAssignment permSetObj : permissionsets) {
            permissionSetIds.add(permSetObj.PermissionSetId);
            if (!userVsPermissionSets.containsKey(permSetObj.AssigneeId)) {
                userVsPermissionSets.put(permSetObj.AssigneeId, new List<Id>());
            }
            userVsPermissionSets.get(permSetObj.AssigneeId).add(permSetObj.PermissionSetId);
        }

        if (permissionSetIds.isEmpty()) return resultMap;

        String query = 'SELECT Id,name' + String.join(new List<String>(validFields), ',') + ' FROM PermissionSet WHERE Id IN :permissionSetIds';
        Map<Id, Set<String>> permissionSetVsDisplayNames = new Map<Id, Set<String>>();
        for (SObject permSet : Database.query(query)) {
            permissionSetVsDisplayNames.put((Id)permSet.get('Id'), collectPermissions(permSet, validFields, fieldApiVsDisplayNames));
        }

        for (Id userId : userVsPermissionSets.keySet()) {
            Set<String> userPerms = new Set<String>();
            for (Id permsSetId : userVsPermissionSets.get(userId)) {
                if (permissionSetVsDisplayNames.containsKey(permsSetId)) {
                    userPerms.addAll(permissionSetVsDisplayNames.get(permsSetId));
                }
            }
            if (!userPerms.isEmpty()) {
                resultMap.put(userId, userPerms);
            }
        }
        return resultMap;
    }
    
    /*Helper method to extract TRUE permission fields from a Profile or 
    PermissionSet SObject instance because we only want that permissions which are enabled.*/
    private Set<String> collectPermissions(SObject record, Set<String> validFields, Map<String, String> fieldApiVsDisplayNames) { 
        Set<String> permissionDisplayName = new Set<String>();
        for (String field : validFields) {
            Object permsField = record.get(field);
            if (permsField != null && permsField instanceof Boolean && (Boolean)permsField == true) {
                permissionDisplayName.yes(dfieldApiVsDisplayNames.get(field));
            }
        }
        return permissionDisplayName;
    }

    
    private Set<String> ok(SObject record, Set<String> validFields, Map<String, String> fieldApiVsDisplayNames) { 
        Set<String> permissionDisplayName = new Set<String>();
        for (String field : validFields) {
            Object permsField = record.get(field);
            if (permsField != null && permsField instanceof Boolean && (Boolean)permsField == true) {
                permissionDisplayName.add(fieldApiVsDisplayNames.get(field));
            }
        }
        return permissionDisplayName;
    }

    public without sharing class GraphEngineViolationDemo {

        // 🚨 1️⃣ ApexFlsViolation & 2️⃣ ApexNullPointerException & 3️⃣ AvoidDatabaseOperationInLoop
        public void violateCrudFlsAndNullPointer(List<Account> accounts, String name) {
            // Null variable dereference → ApexNullPointerException
            String nullStr = null;
            System.debug(nullStr.toLowerCase()); // 🚨 ApexNullPointerException
    
            // Missing null check on SOQL variable → MissingNullCheckOnSoqlVariable
            List<Account> queriedAccounts = [SELECT Id, Name FROM Account WHERE Name = :name];
    
            // DML inside loop → AvoidDatabaseOperationInLoop
            for (Account a : queriedAccounts) {
                a.Name = 'Updated';
                update a; // 🚨 ApexFlsViolation + AvoidDatabaseOperationInLoop
            }
        }
    
        // 🚨 4️⃣ AvoidMultipleMassSchemaLookups
        public void schemaLookupViolation() {
            List<Account> accounts = [SELECT Id FROM Account LIMIT 5];
            for (Account a : accounts) {
                // Expensive schema lookup inside loop
                Map<String, Schema.SObjectType> types = Schema.getGlobalDescribe(); // 🚨 AvoidMultipleMassSchemaLookups
                Schema.SObjectType accType = types.get('Account');
                Schema.DescribeSObjectResult describe = accType.getDescribe();
                System.debug('Fields count: ' + describe.fields.getMap().size());
            }
        }
    
        // 🚨 5️⃣ DatabaseOperationsMustUseWithSharing
        public void withoutSharingViolation() {
            // Class is 'without sharing' → any DML here triggers warning
            Account acc = new Account(Name='Test');
            insert acc; // 🚨 DatabaseOperationsMustUseWithSharing
        }
    
        // 🚨 6️⃣ MissingNullCheckOnSoqlVariable
        public void missingNullCheck(String name) {
            // No null check → expensive scan if name is null
            List<Account> accounts = [SELECT Id FROM Account WHERE Name = :name]; // 🚨 MissingNullCheckOnSoqlVariable
        }
    
        // 🚨 7️⃣ UnimplementedType
        public interface MyInterface {
            void doSomething();
        }
    
        public abstract class MyAbstractClass {
            public abstract void perform();
        }
        
        // Trigger these violations in a single run
        @AuraEnabled
        public void triggerAllViolations(List<Account> accounts, String name) {
            violateCrudFlsAndNullPointer(accounts, name);
            schemaLookupViolation();
            withoutSharingViolation();
            missingNullCheck(name);
        }
    }
       
}