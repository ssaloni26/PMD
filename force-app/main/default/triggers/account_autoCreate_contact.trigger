trigger account_autoCreate_contact on Account (after insert) {
    if(trigger.isafter && trigger.isinsert)
    {
        account_autoCreateContact_handler.CreateContact(trigger.new);
    }
}