/** Description
The SchemaService class provides a utility method to map Salesforce record ID prefixes (first 3 characters) to
their corresponding SObject names. It leverages the Salesforce Schema API to retrieve global describe results
and caches mappings for faster subsequent lookups. This helps identify the object type (e.g., Account, Contact,
Opportunity) from a record’s key prefix. The class uses in-memory caching for both prefix-to-object and global
**/
/**
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-28-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class SchemaService {
    private static Map<String, String> prefixToObjectNameCache = new Map<String, String>();

    private static Map<String, Schema.SObjectType> globalDescribeCache;

    public static String getSObjectNameFromPrefix(String prefix) {
        if (String.isBlank(prefix) || prefix.length() != 3) {
            return null;
        }

        prefix = prefix.toUpperCase();

        if (prefixToObjectNameCache.containsKey(prefix)) {
            return prefixToObjectNameCache.get(prefix);
        }


        Map<String, Schema.SObjectType> globalDescribe = getGlobalDescribe();

        for (Schema.SObjectType sObjType : globalDescribe.values()) {
            try {
                Schema.DescribeSObjectResult describeResult = sObjType.getDescribe();
                String keyPrefix = describeResult.getKeyPrefix();

                if (keyPrefix != null && keyPrefix.equals(prefix)) {
                    String objectName = describeResult.getName();
                    prefixToObjectNameCache.put(prefix, objectName);
                    return objectName;
                }
            } catch (Exception e) {
                continue;
            }
        }

        prefixToObjectNameCache.put(prefix, null);
        return null;
    }

 
    private static Map<String, Schema.SObjectType> getGlobalDescribe() {
        if (globalDescribeCache == null) {
            globalDescribeCache = Schema.getGlobalDescribe();
        }
        return globalDescribeCache;
    }
}