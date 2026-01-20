@isTest
public class AccountHelperTest {

    @isTest
    static void testAccountInsert() {
        Id accId = AccountHelper.createAccount('Test Account');
        Account insertedAcc = [SELECT Name FROM Account WHERE Id = :accId];
        System.assertEquals('Test Account', insertedAcc.Name);
    }

    @isTest
    static void testAccountUpdate() {
        Id accId = AccountHelper.createAccount('Old Name');
        AccountHelper.updateAccountName(accId, 'New Name');
        Account updatedAcc = [SELECT Name FROM Account WHERE Id = :accId];
        System.assertEquals('New Name', updatedAcc.Name);
    }

    @isTest
    static void testGetAccountName() {
        Id accId = AccountHelper.createAccount('Helper Test');
        String result = AccountHelper.getAccountName(accId);
        System.assertEquals('Helper Test', result);
    }
}