public class contact_handler_email_duplication {
	public static void email_duplication(list<contact> contactRecords)
    {
        set<Id> accIds = new set<Id>();
        for(contact c : contactRecords)
        {
            accIds.add(c.AccountId);
        }
        
        map<id, list<contact>> contactMap= new map<Id, List<Contact>>();
        
		for(contact c: [SELECT Id, Email, AccountId FROM Contact WHERE AccountId IN :accIds AND Email != null])
        {
            if(!contactMap.containskey(c.AccountId))
            {
                contactMap.put(c.AccountId, new list<contact>());
            }
           	  //adding to empty new list<contact>() in above 
           	  //get accid and add in list of c from email
           	  
              contactmap.get(c.AccountId).add(c);  
        }
        
    }
}