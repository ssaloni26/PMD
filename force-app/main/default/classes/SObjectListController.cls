public with sharing class SObjectListController {

//object
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllSObjects() {
        List<Map<String, String>> out = new List<Map<String, String>>();
        for (Schema.SObjectType sobjType : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult dr = sobjType.getDescribe();
            if (dr.isAccessible() && !String.isBlank(dr.getLabel()) && !dr.getLabel().startsWith('__MISSING LABEL__')) {
                out.add(new Map<String, String>{ 'label' => dr.getLabel(), 'apiName' => dr.getName() });
            }
        }

        out.sort(new MapLabelComparator());
        return out;
    }

    public class MapLabelComparator implements System.Comparator<Map<String, String>> {
        public Integer compare(Map<String, String> a, Map<String, String> b) {
            String la = a != null && a.get('label') != null ? a.get('label') : '';
            String lb = b != null && b.get('label') != null ? b.get('label') : '';
            return la.toLowerCase().compareTo(lb.toLowerCase());
        }
    }



//fields
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getFieldsForObject(String objectApiName) {
        List<Map<String, String>> fields = new List<Map<String, String>>();
        if (String.isBlank(objectApiName)) return fields;

        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        if (sObjType == null) return fields;

        for (Schema.SObjectField field : sObjType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult d = field.getDescribe();
            if (d.isAccessible()) {
                fields.add(new Map<String, String>{
                    'label'     => d.getLabel(),
                    'value'     => d.getName(),
                    'updateable'=> d.isUpdateable() ? 'true' : 'false'
                });
            }
        }
        return fields;
    }
//records
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRecordsWithSelectedFields(
            String objectApiName,
            List<String> fieldNames,
            Integer limitSize
    ) {
        List<Map<String, Object>> recordsList = new List<Map<String, Object>>();
        if (String.isBlank(objectApiName) || fieldNames == null || fieldNames.isEmpty()) return recordsList;
        if (limitSize == null || limitSize <= 0) limitSize = 50;

        String query = 'SELECT ' + String.join(fieldNames, ',') +
                       ' FROM ' + objectApiName +
                       ' ORDER BY CreatedDate ASC LIMIT :limitSize';

        for (SObject rec : Database.query(query)) {
            Map<String, Object> row = new Map<String, Object>();
            for (String f : fieldNames) row.put(f, rec.get(f));
            row.put('Id', rec.Id);
            recordsList.add(row);
        }
        return recordsList;
    }

//update
 @AuraEnabled
    public static void updateRecords(List<SObject> updateRecords) {
    
        try {
            update updateRecords;
           
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update records: ' + e.getMessage());
        }
        
    }
   
}