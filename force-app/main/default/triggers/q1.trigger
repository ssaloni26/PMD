/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger q1 on account (before update) {
    if(trigger.isupdate )
    {   
        for(account newRecord : trigger.new){
        account oldRecord= trigger.oldmap.get(newRecord.id);

        if(newRecord.phone != oldRecord.phone)
        {
            newRecord.name = newRecord.name+'updated ';
            
        }
    }
    
    }
}