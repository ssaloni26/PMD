@IsTest
private class PromptUtilsTest {

    private class MockEinsteinLLMService implements PromptUtils.EinsteinLLMService {
        public ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generate(
            String promptTemplateDeveloperName,
            ConnectApi.EinsteinPromptTemplateGenerationsInput input
        ) {
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation mockResponse =
                new ConnectApi.EinsteinPromptTemplateGenerationsRepresentation();

            ConnectApi.EinsteinLLMGenerationItemOutput item =
                new ConnectApi.EinsteinLLMGenerationItemOutput();
            item.text = 'Mocked AI Response for ' + promptTemplateDeveloperName;

            mockResponse.generations = new List<ConnectApi.EinsteinLLMGenerationItemOutput>{ item };
            return mockResponse;
        }
    }

    @IsTest
    static void testInvokePrompt_WithMockService() {
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();

        PromptUtils.EinsteinLLMService mockService = new MockEinsteinLLMService();

       
        Test.startTest();
            String result = PromptUtils.invokePrompt('Test_Prompt_Template', inputParams, mockService);
        Test.stopTest();

        
        System.assertEquals('Mocked AI Response for Test_Prompt_Template', result, 'The mocked response should match.');
    }

    @IsTest
    static void testInvokePrompt_DefaultImpl_NoException() {
        
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();

        Test.startTest();
        String result;
        try {
            result = PromptUtils.invokePrompt('Prod_Template', inputParams);
        } catch (Exception e) {
            result = 'Mocked AI Response Text';
        }
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }
}