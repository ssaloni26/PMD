/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-13-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class AccountHelper {
    
    public void processAccounts(List<Account> accounts) {
        Integer count = 0; // PMD: unused variable

        for(Account acc : accounts){
            // duplicated logic (CPD violation)
            if(acc.Name != null){
                acc.Description = 'Processed';
            }
            if(acc.Name != null){
                acc.Description = 'Processed';
            }
        }

        // PMD: Long method without separation
        for(Account acc : accounts){
            System.debug(acc.Name + ' processed'); // too generic, no meaningful log
        }
    }
}
