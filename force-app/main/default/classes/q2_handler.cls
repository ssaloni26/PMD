/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class q2_handler {
    public static void handler(list<account> accRecord) 
    {   
        if (!accRecord.isEmpty()) {

        
        list<Aggregateresult> a_to_c = [select accountid ,count(id) contactcount from contact where accountid in :accRecord group by accountid having count(id)>=2];
        
        Set<Id> acc_set = new Set<Id>();
            for (AggregateResult result : a_to_c) {
                acc_set.add((Id) result.get('AccountId'));
            }
        
        for(account acc :accRecord)
        {
            if(acc_set.contains(acc.id))
            {
                acc.addError('This cant be deleted beacuse of related contacts');
            }
        }

    }
    }
}