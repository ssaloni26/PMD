public class set_trailhead {
	
    public static void insertAccount(Integer v) {
        map<String,Account> addmap = new map<String,Account>();
        Integer n = 1;

        while (n <= v) {
            Account acc = new Account();
            acc.Name = 'Acme Inc'+n;           // make unique
            acc.AccountNumber = 'A000'+n;       // make unique
            addmap.put(acc.name,acc);
            n++;
        }
		
        insert addmap.values();
        
        Account a = addmap.get('Acme Inc1');
        if (a != null) {
            System.debug('Fetched Account: ' + a.Name + ', AccountNumber: ' + a.AccountNumber);
        } else {
            System.debug('Account with Name Acme Inc1 not found.');
        }
    }


}