public class GenAIUtil {
    @AuraEnabled(cacheable=true)
    public static boolean isGenAIEnabled(){
        try{
             Type einsteinType = Type.forName('ConnectApi', 'EinsteinLLM');
              if ( einsteinType !=null){
                return true ;
            }
            else {return false;}
        }Catch(Exception e){
            return false;
        }
    }
    
    public static String invokeAIPromptTemplate(String userIds,String promptHandler) {
        if(!isGenAIEnabled()) return null;
        
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        ConnectApi.WrappedValue userIdsVal = new ConnectApi.WrappedValue();
        userIdsVal.value = userIds;
        ConnectApi.WrappedValue promptHandlerVal = new ConnectApi.WrappedValue();
        promptHandlerVal.value = promptHandler;
        inputParams.put('Input:userIds', userIdsVal);
        inputParams.put('Input:promptHandler', promptHandlerVal);
        
        ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        input.inputParams = inputParams;
        input.isPreview = false;
        input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        String response;
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation responseFromAI = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('SecurityAnalyzerPrompt', input);
        response = responseFromAI.generations[0].text.replaceAll('[\\u00A0\\u200B]', '').replaceAll('`', '').trim();
        return response;
    }
}