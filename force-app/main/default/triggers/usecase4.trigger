/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger usecase4 on lead (before update) {
    if(trigger.isupdate&& trigger.isupdate)
    {
        for(lead leadRecord : trigger.new)
        {
            if(leadRecord.Industry == 'Healthcare')
            {
                leadRecord.LeadSource='Purchased list ';
                leadRecord.SICCode__c='1100';
                leadRecord.Primary__c='yes';
            }
            
        }
    }

}