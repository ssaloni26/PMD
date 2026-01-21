/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger usecase2 on lead (before update) {
    if(trigger.isupdate && trigger.isbefore)
    {
        for(lead leadrecord : trigger.new)
        {
            leadrecord.status='Working-Contacted';
            System.debug('lead updated with new status');

            System.debug('status'+leadrecord.status+'name'+leadrecord.name + 'id'+ leadrecord.id);
        }
    }
}