public with sharing class AccountController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(Integer limitSize) {
        return [
            SELECT Id, Name, Type, Industry 
            FROM Account 
            LIMIT :limitSize
        ];
    }
	@AuraEnabled(cacheable=true)
    public static List<Account> getAccount() {
        return [SELECT Id, Name FROM Account LIMIT 5];
    }


}