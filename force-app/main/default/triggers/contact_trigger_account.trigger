trigger contact_trigger_account on Contact (after insert) {
    if(trigger.isinsert && trigger.isafter)
    {
        contact_handler.account_description(trigger.new);
    }
}