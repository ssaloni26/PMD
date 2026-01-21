/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
Trigger q2 on Account (before delete) {
    if (Trigger.isDelete && Trigger.isBefore) {
        q2_handler.handler(Trigger.old);
    }
}