public class BankManager {
    public static void simulate() {
        BankAccount acc = new BankAccount();
        acc.deposit(1000);
        acc.withdraw(200);
        System.debug('Final Balance: ' + acc.getBalance());
    }
}