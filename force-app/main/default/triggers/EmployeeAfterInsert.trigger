/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-02-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger EmployeeAfterInsert on Employee__c (after insert) {

    if(trigger.isinsert && trigger.isafter)
    {
        
                new EmployeeAfterInserthandler(Trigger.new);
            
        
        
    }
}