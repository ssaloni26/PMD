public class AccountHelper {
    
    // Method to insert a test Account and return its Id
    public static Id createAccount(String accName) {
        Account acc = new Account(Name = accName);
        insert acc;
        return acc.Id;
    }

    // Method to update an Account's name
    public static void updateAccountName(Id accId, String newName) {
        Account acc = [SELECT Id, Name FROM Account WHERE Id = :accId];
        acc.Name = newName;
        update acc;
    }

    // Method to get Account Name
    public static String getAccountName(Id accId) {
        Account acc = [SELECT Name FROM Account WHERE Id = :accId];
        return acc.Name;
    }
}