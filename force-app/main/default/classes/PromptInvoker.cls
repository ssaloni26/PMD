/**
 * wrapper for the static PromptUtils.invokePrompt() method.
 * 
 * Purpose:
 *  - Allows dependency injection for unit tests.
 *  - Prevents direct static call errors.
 */
public virtual class PromptInvoker {
    public virtual String invoke(String promptName, Map<String, ConnectApi.WrappedValue> inputParams) {
        // Calls the real static method during runtime
        return PromptUtils.invokePrompt(promptName, inputParams);
    }
}