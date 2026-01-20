public with sharing class GetContactOpportunityDetail {
    
        @AuraEnabled(cacheable=true)
        public static List<Account> getChildDetails(String recId){
            System.debug(' Apex received recordId: ' + recId);
            return [
                SELECT Id, Name,
                       (SELECT Id, LastName FROM Contacts),
                       (SELECT Id, Name FROM Opportunities)
                FROM Account
                WHERE Id = :recId
            ];
        }
    	
        // Insert new Contact
        @AuraEnabled
        public static Contact createContact(String accId, String conName){
            Contact c = new Contact(LastName = conName, AccountId = accId);
            insert c;
            return c;
        }
        
        @AuraEnabled
        public static void updateContacts(List<Contact> contacts) {
            System.debug('apex call');
            System.debug('data: '+ contacts);
            try {
                update contacts;
            } catch (Exception e) {
                system.debug(e.getMessage());
            }
            
        }

        // Delete Contact
        @AuraEnabled
        public static void deleteContact(Id contactId) {
            try {
                
                delete [SELECT Id FROM Contact WHERE Id = :contactId Limit 1];
            } catch (DmlException e) {
                throw new AuraHandledException(e.getDmlMessage(0));
            }
        }
        
        
    	
        @AuraEnabled
        public static string deletecontactfirst(Id accId) {
            // Get the last created Contact
            List<Contact> cons = [SELECT Id, Name FROM Contact 
                                  WHERE AccountId = :accId 
                                  ORDER BY CreatedDate DESC 
                                  LIMIT 1];
        
            if (cons.isEmpty()){
                return 'No contacts to delete';
            } 
        
            Contact con = cons[0];
        
            // Check for related Cases
            // relatedCases = [SELECT COUNT() FROM Case WHERE ContactId = :con.Id];
            //if (relatedCases > 0) return 'Cannot delete contact: related Cases exist';
        
            if(con!=null){
            	delete con;
            }
            else{
                return 'Last contact not found ';
            } 
            return 'success';
        }

        // Update Contact
        @AuraEnabled
        public static Contact updateContact(Id accId, String upName) {
            Contact con = [SELECT Id, Name FROM Contact WHERE AccountId = :accId LIMIT 1];
            con.LastName = upName;
            update con;
            return con;
        }
		
    	//update contact by id
    	@AuraEnabled
        public static contact Updatecontactbyid(Id conid,String Lastname){
            contact con =[select id ,name from contact where id = :conid];
            con.LastName= Lastname;
            update con;
            return con;
        }
    
        
    
        // Upsert Contact
        @AuraEnabled
        public static Contact upsertContact(Contact con){
            upsert con;
            return con;
        }
    
        // Undelete Contact
        @AuraEnabled
        public static void undeleteContact(Id conId){
            List<Contact> deletedCons = [SELECT Id FROM Contact WHERE Id = :conId ALL ROWS];
            undelete deletedCons;
        }
    }