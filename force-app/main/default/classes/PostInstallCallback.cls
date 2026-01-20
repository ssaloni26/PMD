public class PostInstallCallback implements Metadata.DeployCallback {
    public void handleResult(Metadata.DeployResult result,
        Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            System.debug('Deployment Succeeded!');
        } else {
            System.debug('Deployment Failed!');
            System.debug(result.status);
            System.debug(result);
        }
    }
}