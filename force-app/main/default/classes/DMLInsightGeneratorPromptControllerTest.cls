@IsTest
public class DMLInsightGeneratorPromptControllerTest {

    // ---Reusable setup method ---
    private static List<User> setupUsersAndAudits() {
        List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
        
        // --- Create Database_Audit__c records ---
        Date today = Date.today();
        Date lastMonth = today.addMonths(-1);

        insert new List<Database_Audit__c>{
            new Database_Audit__c(
                User__c = users[0].Id,
                LogDate__c = today,
                ObjectName__c = 'Account',
                Operation__c = 'Insert',
                Record_Count__c = 10
            ),
            new Database_Audit__c(
                User__c = users[0].Id,
                LogDate__c = today,
                ObjectName__c = 'Contact',
                Operation__c = 'Update',
                Record_Count__c = 3
            ),
            new Database_Audit__c(
                User__c = users[0].Id,
                LogDate__c = lastMonth,
                ObjectName__c = 'Opportunity',
                Operation__c = 'Delete',
                Record_Count__c = 5
            ),
            new Database_Audit__c(
                User__c = users[0].Id,
                LogDate__c = lastMonth,
                ObjectName__c = 'Lead',
                Operation__c = 'Query',
                Record_Count__c = 8
            ),
            new Database_Audit__c(
                User__c = users[1].Id,
                LogDate__c = today,
                ObjectName__c = 'Case',
                Operation__c = 'Insert',
                Record_Count__c = 1 
            )
        };

        return users;
    }

    // --- Full coverage test using setup method ---
    @IsTest
    static void test_fullCoverage_allBranches() {
        List<User> users = setupUsersAndAudits();

        

        DMLInsightGeneratorPromptController.Request req = new DMLInsightGeneratorPromptController.Request();
        req.userIds = users[0].Id + ',' + users[1].Id;

        Test.startTest();
        List<DMLInsightGeneratorPromptController.Response> resList =
            DMLInsightGeneratorPromptController.getPrompt(
                new List<DMLInsightGeneratorPromptController.Request>{ req }
            );
        Test.stopTest();
        
        // --- Parse JSON from the Prompt ---
        List<Object> usersData = (List<Object>) JSON.deserializeUntyped(resList[0].Prompt);

        // --- Build expected totals dynamically matching controller logic ---
        Map<Id, Map<String, Integer>> expectedTotals = new Map<Id, Map<String, Integer>>();
        
        for (User u : users) {
            expectedTotals.put(u.Id, new Map<String, Integer>{
                'Insert' => 0,
                'Update' => 0,
                'Delete' => 0,
                'Query' => 0
            });
        }
        
        for (Database_Audit__c audit : [SELECT User__c, Operation__c, Record_Count__c, ObjectName__c
                                        FROM Database_Audit__c
                                        WHERE User__c IN :users
                                        AND LogDate__c = LAST_N_Days:180]) {
            if (audit.Record_Count__c == null || audit.Record_Count__c == 0) continue; // ignore zeros
        
            Map<String, Integer> opMap = expectedTotals.get(audit.User__c);
            if (opMap.containsKey(audit.Operation__c)) {
                opMap.put(audit.Operation__c, opMap.get(audit.Operation__c) + audit.Record_Count__c.intValue());
            }
        }

        // --- Assertions: loop through JSON and verify counts ---
        for (Object userObj : usersData) {
            Map<String, Object> userMap = (Map<String, Object>) userObj;
            Id uid = (Id) userMap.get('Id');
            Map<String, Integer> expectedOps = expectedTotals.get(uid);
        
            for (String op : new List<String>{'Insert','Update','Delete','Query'}) {
                List<Object> opList = (List<Object>) userMap.get(op);
                Integer totalCount = 0;
        
                if (opList != null) {
                    for (Object opRec : opList) {
                        Map<String, Object> recMap = (Map<String, Object>) opRec;
                        for (String key : recMap.keySet()) {
                            if (key != 'Log Date') {
                                totalCount += Integer.valueOf(recMap.get(key));
                            }
                        }
                    }
                }
        
                Assert.areEqual(expectedOps.get(op), totalCount, op + 'count mismatch for user ' + uid);

            }
        }
    }
}