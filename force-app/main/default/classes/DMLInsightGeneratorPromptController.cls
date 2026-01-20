/**
 * @description       : This Apex controller class generates AI-ready prompts based on DML activity recorded 
 *                     in the Database_Audit__c object. It collects insert, update, delete, and query counts 
 *                     for each user over the past 6 months, structures the data in a nested JSON format, 
 *                     and returns it for AI processing or other analytical purposes.
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-09-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class DMLInsightGeneratorPromptController {

    
    /**
     * Invocable method that takes a list of user requests and returns structured AI prompts.
     * Calls prepareDMLData() to generate structured JSON data for DML operations per user.
     **/
    @InvocableMethod(label='Prepare DML Audit Data for AI')
    public static List<Response> getPrompt(List<Request> requests) {
        Request input = requests[0];
        String rawData = prepareDMLData(input.userIds);

        Response output = new Response();
        output.Prompt = rawData;

        return new List<Response>{ output };
    }

    /**
     * Private helper method that queries Database_Audit__c for DML activities (Insert, Update, Delete, Query)
     * for the specified users over the last 6 months. Aggregates counts per object per day per user,
     * organizes them into separate lists for each operation type, and serializes the result as JSON.
     **/
    private static String prepareDMLData(String userIds) {
        List<String> userIdList = userIds.split(',');

        List<Database_Audit__c> records = [
            SELECT Id, Name, User__c, User__r.Name, LogDate__c,
                   ObjectName__c, Operation__c, Record_Count__c
            FROM Database_Audit__c
            WHERE User__c IN :userIdList
            AND LogDate__c = LAST_N_DAYS:180 
            ORDER BY User__c, LogDate__c DESC
        ];

        Map<Id, Map<Date, Map<String, Map<String, Integer>>>> nestedCounts = new Map<Id, Map<Date, Map<String, Map<String, Integer>>>>();
        Map<Id, String> userNames = new Map<Id, String>();

        for (Database_Audit__c rec : records) {
            Id userId = rec.User__c;
            Date logDate = rec.LogDate__c != null ? rec.LogDate__c : Date.today();
            String objectName = rec.ObjectName__c;
            String operation = rec.Operation__c;
            Integer count = rec.Record_Count__c != null ? rec.Record_Count__c.intValue() : 0;

            if (count == 0) continue;

            userNames.put(userId, rec.User__r != null ? rec.User__r.Name : 'Unknown');

            if (!nestedCounts.containsKey(userId)) nestedCounts.put(userId, new Map<Date, Map<String, Map<String, Integer>>>());
            if (!nestedCounts.get(userId).containsKey(logDate)) nestedCounts.get(userId).put(logDate, new Map<String, Map<String, Integer>>());
            if (!nestedCounts.get(userId).get(logDate).containsKey(objectName)) {
                nestedCounts.get(userId).get(logDate).put(objectName, new Map<String, Integer>{
                    'Insert' => 0,
                    'Update' => 0,
                    'Delete' => 0,
                    'Query'  => 0
                });
            }

            Map<String, Integer> opMap = nestedCounts.get(userId).get(logDate).get(objectName);
            if (operation == 'Insert' || operation == 'Update' || operation == 'Delete' || operation == 'Query') {
                opMap.put(operation, opMap.get(operation) + count);
            }
        }

        List<Map<String, Object>> finalList = new List<Map<String, Object>>();

        for (Id userId : nestedCounts.keySet()) {
            Map<String, Object> userData = new Map<String, Object>();

            List<Map<String, Object>> queryList = new List<Map<String, Object>>();
            List<Map<String, Object>> insertList = new List<Map<String, Object>>();
            List<Map<String, Object>> updateList = new List<Map<String, Object>>();
            List<Map<String, Object>> deleteList = new List<Map<String, Object>>();

            Map<Date, Map<String, Map<String, Integer>>> logMap = nestedCounts.get(userId);
            List<Date> sortedDates = new List<Date>(logMap.keySet());
            sortedDates.sort(); 
            List<Date> descendingDates = new List<Date>();
            for (Integer i = sortedDates.size() - 1; i >= 0; i--) {
                descendingDates.add(sortedDates[i]);
            }

            for (Date logDate : descendingDates) {
                Map<String, Map<String, Integer>> objMap = logMap.get(logDate);

                Map<String, Object> queryMap = new Map<String, Object>{'Log Date' => logDate.format()};
                Map<String, Object> insertMap = new Map<String, Object>{'Log Date' => logDate.format()};
                Map<String, Object> updateMap = new Map<String, Object>{'Log Date' => logDate.format()};
                Map<String, Object> deleteMap = new Map<String, Object>{'Log Date' => logDate.format()};

                for (String objName : objMap.keySet()) {
                    Map<String, Integer> counts = objMap.get(objName);
                    if (counts.get('Query') > 0) queryMap.put(objName, counts.get('Query'));
                    if (counts.get('Insert') > 0) insertMap.put(objName, counts.get('Insert'));
                    if (counts.get('Update') > 0) updateMap.put(objName, counts.get('Update'));
                    if (counts.get('Delete') > 0) deleteMap.put(objName, counts.get('Delete'));
                }

                if (queryMap.size() > 1) queryList.add(queryMap);
                if (insertMap.size() > 1) insertList.add(insertMap);
                if (updateMap.size() > 1) updateList.add(updateMap);
                if (deleteMap.size() > 1) deleteList.add(deleteMap);
            }

            userData.put('Query', queryList);
            userData.put('Insert', insertList);
            userData.put('Update', updateList);
            userData.put('Delete', deleteList);
            userData.put('Id', userId);
            userData.put('Name', userNames.get(userId));

            finalList.add(userData);
        }

        return JSON.serializePretty(finalList);
    }

    /**
     * Inner class used as an input for the invocable method.
     * Contains the userIds field representing the users whose DML audit data should be fetched and prepared.
     **/
    public class Request {
        @InvocableVariable(required=true)
        public String userIds;
    }

    /**
     * Inner class used as the output for the invocable method.
     * Contains the generated prompt ready for AI or analytical processing.
     **/
    public class Response {
        @InvocableVariable
        public String Prompt;
    }
}