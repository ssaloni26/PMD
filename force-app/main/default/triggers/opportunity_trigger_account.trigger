trigger opportunity_trigger_account on Opportunity (after update) {
    if(trigger.isafter && trigger.isupdate)
    {
        opportunity_handler.opportunities_account_update(trigger.new);
    }
}