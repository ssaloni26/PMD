/**
 * @description Helper class to process Account records.
 */
public class AccountHelper {

    /**
     * @description Updates the Description field of Accounts with a non-null Name.
     * @param accounts List of Account records to process.
     */
    public void processAccounts(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            return;
        }

        for (Account acc : accounts) {
            updateAccountDescription(acc);
        }
    }

    /**
     * @description Sets the Description field for a single Account if Name is not null.
     * @param acc Account record to update.
     */
    private void updateAccountDescription(Account acc) {
        if (acc.Name != null) {
            acc.Description = 'Processed';
        }

        // Use proper logging level instead of generic System.debug
        System.debug(LoggingLevel.INFO, 'Account ' + acc.Name + ' processed');
    }
}
