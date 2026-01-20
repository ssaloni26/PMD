public class Combined {
    
    public static void comb(String keyword){
        savepoint sp = Database.setSavepoint();
        try{
            String safeInput = String.escapeSingleQuotes(keyword);
            
            String query = 'FIND \'' + safeInput + '*\' IN ALL FIELDS RETURNING ' +
                'Contact(Id, FirstName, LastName), ' +
                'Account(Id, Name),'+'invoice__c(Id, Name)'
            ;
            list<list<SObject>> result = Search.query(query);
            
            // EMPTY SET FORMATION
            set<id> cid = new set<id>();
            	//FILLING SET WITH ID 
                for(SObject a:result[0])
                {
                    cid.add(a.id);
                }
            
            set<id> aid = new set<id>();
            
                for(SObject a:result[1])
                {
                    aid.add(a.id);
                }
            
            set<id> iid = new set<id>();
                for(SObject a:result[2])
                {
                    iid.add(a.id);
                }
            
            
            list<account> validacc= aid.isempty()?new list<account>():[SELECT Id, name FROM account WHERE Id IN :aid ];
            
                
            list<contact> validcontact= cid.isempty()?new list<contact>():[SELECT Id, FirstName, LastName, Email FROM Contact WHERE Id IN :cid AND Email != null];
	
            list<invoice__c> validinvoice= iid.isempty()?new list<invoice__c>():[SELECT Id, name FROM invoice__c WHERE Id IN :iid ];
	
          
            System.debug('Valid Contacts:');
            for (Contact c : validcontact) {
                System.debug(c.FirstName + ' ' + c.LastName + ' | Email: ' + c.Email);
            }

            System.debug(' Valid Accounts:');
            for (Account a : validAcc) {
                System.debug(' name: ' + a.name);
            }
            
            
            System.debug(' Valid invoice:');
            for (invoice__c a : validinvoice) {
                System.debug('name: ' + a.name);
            }
            
            
            if(validcontact.isempty()||validacc.isempty()||validinvoice.isempty())
            {
              database.rollback(sp);
                System.debug('error');
                return;
            }
            
        }catch(Exception e){
            database.rollback(sp);
            System.debug('e error'+e.getmessage());
                
        }
    }
}