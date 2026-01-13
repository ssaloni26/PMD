/**
 * Helper class to process Account records
 */
public class AccountHelper {

    /**
     * Updates Description for Accounts with non-null Name
     */
    public void processAccounts(List<Account> accounts){
        if(accounts == null || accounts.isEmpty()) return;

        for(Account acc : accounts){
            updateAccountDescription(acc);
        }
    }

    /**
     * Helper method to update account description
     */
    private void updateAccountDescription(Account acc){
        if(acc.Name != null){
            acc.Description = 'Processed';
        }
        System.debug(LoggingLevel.INFO, 'Account ' + acc.Name + ' processed');
    }
}
