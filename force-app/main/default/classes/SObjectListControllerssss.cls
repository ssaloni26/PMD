public class SObjectListControllerssss {




    // Get all list views
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getListViews(String objectApiName) {
        List<Map<String,String>> views = new List<Map<String,String>>();
        for (ListView lv : [SELECT Id, Name FROM ListView WHERE SObjectType = :objectApiName ORDER BY Name]) {
            views.add(new Map<String,String>{ 'label' => lv.Name, 'value' => lv.Id });
        }
        return views;
    }


    // Get a batch of records dynamically
@AuraEnabled(cacheable=true)
public static List<SObject> getRecordsBatch(String objectApiName, Id lastRecordId, Integer batchLimit) {
    if (String.isBlank(objectApiName)) return new List<SObject>();
    if (batchLimit == null || batchLimit <= 0) batchLimit = 20;

    Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
    if (sObjType == null) return new List<SObject>();

    String query = 'SELECT Id, Name FROM ' + objectApiName +
                   (lastRecordId != null ? ' WHERE Id > :lastRecordId' : '') +
                   ' ORDER BY Id ASC LIMIT :batchLimit';

    return Database.query(query);
}





    // Get updateable fileds
    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> getUpdateableFields(String objectApiName) {
        Map<String, Boolean> result = new Map<String, Boolean>();
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        if (sObjType == null) return result;

        Map<String, Schema.SObjectField> fieldsMap = sObjType.getDescribe().fields.getMap();
        for (String f : fieldsMap.keySet()) {
            result.put(f, fieldsMap.get(f).getDescribe().isUpdateable());
        }
        return result;
    }


    // Delete
    @AuraEnabled
    public static void deleteRecords(List<Id> recordIds, String objectApiName) {
        if (recordIds == null || recordIds.isEmpty()) return;

        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        if (sObjType == null) return;

        List<SObject> recordsToDelete = new List<SObject>();
        for (Id recId : recordIds) {
            SObject sobj = sObjType.newSObject();
            sobj.put('Id', recId);
            recordsToDelete.add(sobj);
        }
        delete recordsToDelete;
    }


    // Get Recently Viewed list view or first available
    @AuraEnabled(cacheable=true)
    public static String getRecentlyViewedListView(String objectApiName) {
        List<ListView> views = [
            SELECT Id, DeveloperName, Name
            FROM ListView
            WHERE SObjectType = :objectApiName
            ORDER BY LastViewedDate DESC NULLS LAST
        ];

        for (ListView lv : views) {
            if (lv.Name != null && lv.Name.containsIgnoreCase('Recently Viewed')) {
                return lv.DeveloperName;
            }
        }
        return (views.isEmpty()) ? null : views[0].DeveloperName;
    }


    // all SObjects
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllSObjects() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        List<Map<String, String>> out = new List<Map<String, String>>();

        for (Schema.SObjectType sobjType : gd.values()) {
            Schema.DescribeSObjectResult dr = sobjType.getDescribe();
            if (dr.isAccessible() && dr.isQueryable() && !String.isBlank(dr.getLabel()) &&
                !dr.getLabel().startsWith('__MISSING LABEL__')) {
                out.add(new Map<String,String>{'label' => dr.getLabel(), 'apiName' => dr.getName()});
            }
        }

        out.sort(new MapLabelComparator());
        return out;
    }


    // Comparator for sorting maps by label
    public class MapLabelComparator implements System.Comparator<Map<String, String>> {
        public Integer compare(Map<String, String> a, Map<String, String> b) {
            String la = (a == null || a.get('label') == null) ? '' : a.get('label');
            String lb = (b == null || b.get('label') == null) ? '' : b.get('label');
            return la.toLowerCase().compareTo(lb.toLowerCase());
        }
    }

    // Wrapper for update 
    public class UpdateResult {
        @AuraEnabled public String id;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
    }


    // Bulk update 
    @AuraEnabled
    public static List<UpdateResult> updateRecords(List<Map<String, Object>> updates) {
        List<UpdateResult> results = new List<UpdateResult>();
        if (updates == null || updates.isEmpty()) return results;

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        List<SObject> toUpdate = new List<SObject>();
        List<Integer> inputIndex = new List<Integer>();

        // Prepare SObjects
        for (Integer i = 0; i < updates.size(); i++) {
            Map<String, Object> rec = updates[i];
            UpdateResult ur = new UpdateResult();

            if (rec == null) {
                ur.id = null; ur.success = false; ur.message = 'Null record';
                results.add(ur); continue;
            }

            String typeName = (String) rec.get('sobjectType');
            Map<Object, Object> rawFields = (Map<Object, Object>) rec.get('fields');
            Map<String, Object> fields = new Map<String, Object>();

            if (rawFields != null) {
                for (Object k : rawFields.keySet()) {
                    fields.put(String.valueOf(k), rawFields.get(k));
                }
            }

            if (String.isBlank(typeName) || fields.isEmpty()) {
                ur.id = fields.containsKey('Id') ? (String) fields.get('Id') : null;
                ur.success = false; ur.message = 'Invalid payload';
                results.add(ur); continue;
            }

            if (!gd.containsKey(typeName)) {
                ur.id = fields.containsKey('Id') ? (String) fields.get('Id') : null;
                ur.success = false; ur.message = 'Object type not found: ' + typeName;
                results.add(ur); continue;
            }

            SObject sobj = gd.get(typeName).newSObject();
            for (String f : fields.keySet()) {
                sobj.put(f, fields.get(f));
            }

            toUpdate.add(sobj);
            inputIndex.add(i);
            results.add(null); // placeholder
        }

        //bulk update
        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] srs = Database.update(toUpdate, false);
            for (Integer j = 0; j < srs.size(); j++) {
                Database.SaveResult sr = srs[j];
                Integer orig = inputIndex[j];
                UpdateResult ur = new UpdateResult();
                ur.id = sr.getId();
                ur.success = sr.isSuccess();

                if (!sr.isSuccess()) {
                    List<String> errs = new List<String>();
                    for (Database.Error e : sr.getErrors()) errs.add(e.getStatusCode() + ': ' + e.getMessage());
                    ur.message = String.join(errs, '; ');
                } else {
                    ur.message = 'Saved';
                }

                results.set(orig, ur);
            }
        }

        return results;
    }



}