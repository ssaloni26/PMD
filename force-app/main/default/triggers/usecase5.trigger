/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger usecase5 on opportunity (after update) {

    if(trigger.isupdate && trigger.isafter)
    {
        //do use case here
        usecase5_handler.usecase(trigger.new);
        
    }
}