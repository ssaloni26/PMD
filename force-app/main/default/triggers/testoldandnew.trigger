trigger testoldandnew on Contact (before update,after update) {
    if(trigger.isupdate){
        if(trigger.isbefore){
            System.debug('update before'+Trigger.new);
            System.debug('update before'+Trigger.old);
            System.debug('update before new map'+Trigger.newmap);
            System.debug('update before old map'+Trigger.oldmap);
        }
        if(trigger.isafter){
            System.debug('update after new '+Trigger.new);
            System.debug('update after old'+Trigger.old);
            System.debug('update after newmap'+Trigger.newmap);
            System.debug('update after oldmap'+Trigger.oldmap);
        }
    }
}