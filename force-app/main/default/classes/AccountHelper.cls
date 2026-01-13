/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-13-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class AccountHelper {

    // Processes accounts by updating Description if Name is not null
    public void processAccounts(List<Account> accounts){
        if(accounts == null || accounts.isEmpty()) return;

        for(Account acc : accounts){
            updateAccountDescription(acc);
        }
    }

    // Separated logic to remove duplication (CPD fix)
    private void updateAccountDescription(Account acc){
        if(acc.Name != null){
            acc.Description = 'Processed';
        }
        System.debug('Account ' + acc.Name + ' processed');
    }
}
