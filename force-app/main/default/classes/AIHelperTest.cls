@IsTest
public class AIHelperTest {

    // Utility: create test Accounts to simulate input data
    private static List<Account> createTestAccounts() {
        List<Account> accList = new List<Account>();
        accList.add(new Account(Name = 'Test Account 1', Industry = 'IT', Phone = '1234567890'));
        accList.add(new Account(Name = 'Test Account 2', Industry = 'Finance', Phone = '9876543210'));
        insert accList;
        return accList;
    }

    // ✅ Test preparePayload()
    @IsTest
    static void testPreparePayload() {
        List<Account> accList = createTestAccounts();
        Id userId = UserInfo.getUserId();

        Map<String, Object> payload = AIHelper.preparePayload(accList, userId);

        System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assert(payload.containsKey('BatchId'), 'Payload must contain BatchId');
        System.assert(payload.containsKey('records'), 'Payload must contain records');
        System.assertEquals(2, ((List<Object>)payload.get('records')).size(), 'Payload should contain 2 records');
    }

    // 🔹 Mock PromptInvoker that returns a valid cleaned JSON response
    private class MockPromptInvoker extends PromptInvoker {
        private String response;
        MockPromptInvoker(String resp) { response = resp; }
        public override String invoke(String promptName, Map<String, ConnectApi.WrappedValue> inputParams) {
            return response;
        }
    }

    // 🔹 Mock PromptInvoker that throws an exception
    private class MockPromptInvokerThrows extends PromptInvoker {
        public override String invoke(String promptName, Map<String, ConnectApi.WrappedValue> inputParams) {
            throw new MockAIException('Simulated AI failure');
        }
    }

    // 🔹 Custom lightweight exception
    private class MockAIException extends Exception {}

    // ✅ Test sendToAI() — Successful cleanable response
    @IsTest
    static void testSendToAI_CleanedOutputProcessing() {
        Id userId = UserInfo.getUserId();

        Map<String, Object> payload = new Map<String, Object>{
            'BatchId' => 'batch_' + userId,
            'records' => new List<Map<String, Object>>{
                new Map<String, Object>{ 'Name' => 'Test Record' }
            }
        };

        // Mock response that triggers cleaning logic
        String dirtyResponse = '```json\n   { "result" : "cleaned output", "value" : 123 }\u00A0   ```   ';

        // Inject mock PromptInvoker
        AIHelper.promptInvoker = new MockPromptInvoker(dirtyResponse);

        Test.startTest();
        Map<String, Object> result = AIHelper.sendToAI('CleanPrompt', payload, userId);
        Test.stopTest();

        System.assertEquals('cleaned output', result.get('result'));
        System.assertEquals(123, result.get('value'));
    }

    // ✅ Test sendToAI() — Invalid JSON (hits catch block)
    @IsTest
    static void testSendToAI_InvalidJSON() {
        Id userId = UserInfo.getUserId();

        Map<String, Object> payload = new Map<String, Object>{
            'BatchId' => 'batch_' + userId,
            'records' => new List<Map<String, Object>>()
        };

        // Mock response with invalid JSON
        String badJsonResponse = '```json\n   Not a JSON string   ```';

        AIHelper.promptInvoker = new MockPromptInvoker(badJsonResponse);

        Test.startTest();
        Map<String, Object> result = AIHelper.sendToAI('BadPrompt', payload, userId);
        Test.stopTest();

        // Should return an empty or partially filled map (but not null)
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    // ✅ Test sendToAI() — Simulated Exception
    @IsTest
    static void testSendToAI_Exception() {
        Id userId = UserInfo.getUserId();

        Map<String, Object> payload = new Map<String, Object>{
            'BatchId' => 'batch_' + userId,
            'records' => new List<Map<String, Object>>()
        };

        // Mock that throws an exception
        AIHelper.promptInvoker = new MockPromptInvokerThrows();

        Test.startTest();
        Map<String, Object> result = AIHelper.sendToAI('FailPrompt', payload, userId);
        Test.stopTest();

        // Should return empty map when exception occurs
        System.assertEquals(0, result.size(), 'Should return empty map on exception');
    }

    // ✅ Additional direct cleaning verification test
    @IsTest
    static void testCleaningAndDeserialization() {
        Id userId = UserInfo.getUserId();

        // Simulate uncleaned AI output
        String dirtyOutput = '```json\n   { "result" : "cleaned output", "value" : 123 }\u00A0   ```   ';

        // ---- Run cleaning logic directly ----
        String cleanedOutput = dirtyOutput.replace('\u00A0', ' ').trim();
        cleanedOutput = cleanedOutput.replaceAll('^```json', '');
        cleanedOutput = cleanedOutput.replaceAll('```$', '');
        cleanedOutput = cleanedOutput.trim();

        System.assert(!cleanedOutput.contains('```json'), 'Should remove starting fence');
        System.assert(!cleanedOutput.contains('```'), 'Should remove ending fence');
        System.assert(cleanedOutput.startsWith('{') && cleanedOutput.endsWith('}'), 'Should be valid JSON object');

        Map<String, Object> aiResponse = (Map<String, Object>) JSON.deserializeUntyped(cleanedOutput);
        System.assertEquals('cleaned output', aiResponse.get('result'));
        System.assertEquals(123, aiResponse.get('value'));
    }
}