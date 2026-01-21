/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger usecase3 on case (before insert) {
    if(trigger.isinsert && trigger.isbefore){
        for(case caseRecord : trigger.new)
        {
            if(caseRecord.Origin =='Phone')
            {
                caseRecord.Priority='High';
            }
            else
            {
                caseRecord.Priority='Low';
            }
            
        }
    }
}