public class PromptUtils {

       public interface EinsteinLLMService {
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generate(
            String promptTemplateDeveloperName,
            ConnectApi.EinsteinPromptTemplateGenerationsInput input
        );
    }

       public class EinsteinLLMServiceImpl implements EinsteinLLMService {
        public ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generate(
            String promptTemplateDeveloperName,
            ConnectApi.EinsteinPromptTemplateGenerationsInput input
        ) {
            return ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(promptTemplateDeveloperName, input);
        }
    }

      public static String invokePrompt(
        String promptTemplateDeveloperName,
        Map<String, ConnectApi.WrappedValue> inputParams
    ) {
                return invokePrompt(promptTemplateDeveloperName, inputParams, new EinsteinLLMServiceImpl());
    }

        public static String invokePrompt(
        String promptTemplateDeveloperName,
        Map<String, ConnectApi.WrappedValue> inputParams,
        EinsteinLLMService service
    ) {
        
        ConnectApi.EinsteinPromptTemplateGenerationsInput promptGenerationsInput =
            new ConnectApi.EinsteinPromptTemplateGenerationsInput();

        promptGenerationsInput.inputParams = inputParams;

        promptGenerationsInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        promptGenerationsInput.additionalConfig.numGenerations = 1;
        promptGenerationsInput.additionalConfig.enablePiiMasking = true;
        promptGenerationsInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';

        promptGenerationsInput.isPreview = false;

        
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput =
            service.generate(promptTemplateDeveloperName, promptGenerationsInput);

        ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];
        return response.text;
    }
}