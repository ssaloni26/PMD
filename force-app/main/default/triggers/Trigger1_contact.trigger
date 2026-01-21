trigger Trigger1_contact on Contact (before insert,after insert,before update,after update,before delete,after delete,after undelete) {
    if(trigger.isinsert){
        if(trigger.isbefore){
            System.debug('insert before'+Trigger.new);
            System.debug('insert before'+Trigger.old);
        }
        if(trigger.isafter){
            System.debug('insert after'+Trigger.new);
            System.debug('insert after'+Trigger.old);
        }
    }
    /*if(trigger.isupdate){
        if(trigger.isbefore){
            System.debug('update before'+Trigger.new);
            System.debug('update before'+Trigger.old);
        }
        if(trigger.isafter){
            System.debug('update after'+Trigger.new);
            System.debug('update after'+Trigger.old);
        }
    }*/
    if(trigger.isdelete){
        if(trigger.isbefore){
            System.debug('delete before'+Trigger.new);
            System.debug('delete before'+Trigger.old);
        }
        if(trigger.isafter){
            System.debug('delete after'+Trigger.new);
            System.debug('delete after'+Trigger.old);
        }
    }
    if(trigger.isundelete){
        if(trigger.isafter){
            System.debug('undelete after'+Trigger.new);
            System.debug('undelete after'+Trigger.old);
        }
    }
}