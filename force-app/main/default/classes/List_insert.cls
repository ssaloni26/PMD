public class List_insert {
    public static void insert1(integer value){
        integer c=1;
         list<Account> accList = new list<account>();
        while(c<=value)
        {
           account acc = new account();
           acc.name = 'Saloni-test-duplicate';

           acc.BillingCity='jvhbcjmkxlcvjgn';
           accList.add(acc);
           c++;
        }
        insert accList ;
        for(account acc:accList){
            System.debug('Name: ' + acc.Name + ', AccountNumber: ' + acc.AccountNumber + ', BillingCity: ' + acc.BillingCity);


        }
    }
}