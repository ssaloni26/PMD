public class Queueable_Demo implements System.Queueable {
    
    public void execute(System.QueueableContext context) {
    System.debug('Inside the execute method of Queueable Job');
        
    List<Account> listofAccounts = new List<Account>([Select Id, Name From Account Limit 50]);
    System.debug('listofAccounts:'+ listofAccounts);
    }
}