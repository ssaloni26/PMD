public class AIHelper {

    @TestVisible
    public static PromptInvoker promptInvoker = new PromptInvoker(); // default real one


    public static Map<String, Object> preparePayload(List<SObject> records, Id userId) {
        List<Map<String, Object>> jsonRecords = new List<Map<String, Object>>();

        for (SObject rec : records) {
            Map<String, Object> fieldMap = new Map<String, Object>();


            for (String fieldName : rec.getPopulatedFieldsAsMap().keySet()) {
                fieldMap.put(fieldName, rec.get(fieldName));
            }

            jsonRecords.add(fieldMap);
        }

        Map<String, Object> payload = new Map<String, Object>{
            'BatchId' => 'batch_' + userId + '_' + Datetime.now().getTime(),
            'records' => jsonRecords
        };

        return payload;
    }

  
    public static Map<String, Object> sendToAI(String promptName, Map<String, Object> payload, Id userId) {
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();

        ConnectApi.WrappedValue wrappedPayload = new ConnectApi.WrappedValue();
        wrappedPayload.value = JSON.serialize(payload);
        inputParams.put('Input:DML_Records', wrappedPayload);

        String aiOutput;
        try {
            aiOutput = promptInvoker.invoke(promptName, inputParams);
            System.debug('AI Output for User ' + userId + ': ' + aiOutput);
        } catch (Exception e) {
            System.debug('Error invoking AI prompt for user ' + userId + ': ' + e.getMessage());
            return new Map<String, Object>(); 
        }

    
        String cleanedOutput = aiOutput.replace('\u00A0', ' ').trim();
        cleanedOutput = cleanedOutput.replaceAll('^```json', '');
        cleanedOutput = cleanedOutput.replaceAll('```$', '');
        cleanedOutput = cleanedOutput.trim();

        
        Map<String, Object> aiResponse = new Map<String, Object>();
        try {
            aiResponse = (Map<String, Object>) JSON.deserializeUntyped(cleanedOutput);
        } catch (Exception e) {
            System.debug('AI output is not valid JSON for user ' + userId + ': ' + cleanedOutput);
        }

        return aiResponse;
    }
}