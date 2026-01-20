public class BankAccount {
    private Decimal balance = 0; // hidden

    public Decimal getBalance() {
        return balance;
    }

    public void deposit(Decimal amount) {
        if (amount > 0) {
            balance += amount;
        }
    }

    public void withdraw(Decimal amount) {
        if (amount > 0 && amount <= balance) {
            balance -= amount;
        } else {
            System.debug('Insufficient funds or invalid amount');
        }
    }
}