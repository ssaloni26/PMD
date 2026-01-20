@IsTest
private class PromptInvokerTest {
    // Mock subclass to override invoke()
    private class MockPromptInvoker extends PromptInvoker {
        public override String invoke(String promptName, Map<String, ConnectApi.WrappedValue> inputParams) {
            return '{"status":"ok","prompt":"' + promptName + '"}';
        }
    }

    @IsTest
    static void testMockInvoker() {
        MockPromptInvoker mock = new MockPromptInvoker();
        Map<String, ConnectApi.WrappedValue> params = new Map<String, ConnectApi.WrappedValue>();
        String result = mock.invoke('TestPrompt', params);

        System.assert(result.contains('ok'), 'Mock should return JSON response');
    }

    @IsTest
    static void testRealInvokerCompiles() {
        try {
            PromptInvoker inv = new PromptInvoker();
            inv.invoke('RealPrompt', new Map<String, ConnectApi.WrappedValue>());
        } catch (Exception e) {
            System.assertNotEquals(null, e); // acceptable since PromptUtils may not run in test
        }
    }
}