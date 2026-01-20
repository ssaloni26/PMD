public class opportunity_handler {
    public static void opportunities_account_update(list<opportunity> oppRecord)
    {
        if(oppRecord!=null || !oppRecord.isEmpty())
        {
           Set<Id> alredy_used_ids= opportunity_helper.ids_to_see_duplications;
            
                       
            list<account> accList = new list<account>();
            for(opportunity opps : oppRecord)
            {
                if(opps.AccountId!=null && !alredy_used_ids.contains(opps.AccountId))
                {
                    account a = new account(id= opps.AccountId,NumberofLocations__c= 3);
                    accList.add(a);
                    alredy_used_ids.add(opps.AccountId); 
                }
            }
            update accList;
                
        }
    }
}