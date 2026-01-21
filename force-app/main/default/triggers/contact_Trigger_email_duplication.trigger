trigger contact_Trigger_email_duplication on Contact (before insert) {
    if(trigger.isbefore && trigger.isinsert)
    {
        contact_handler_email_duplication.email_duplication(trigger.new);
    }
}