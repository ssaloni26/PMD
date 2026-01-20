public class SchemaGlobalDescribe {
    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix) {

        if (String.isBlank(recordIdOrPrefix) || recordIdOrPrefix.length() < 3) {
            return null;
        }

        //ex 3
        String myIdPrefix = recordIdOrPrefix.substring(0, 3);

        //all sobject
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        //loop
        for (Schema.SObjectType stype : gd.values()) {
            Schema.DescribeSObjectResult describeResult = stype.getDescribe();
            String keyPrefix = describeResult.getKeyPrefix();

            if (keyPrefix != null && keyPrefix.equals(myIdPrefix)) {
                return describeResult.getName(); //return object
            }
        }

        return null;
    }
}