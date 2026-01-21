trigger contact_Trigger on Contact (before insert) {
    if(trigger.isbefore && trigger.isinsert)
    {
        contact_trigger.contact_insertion_prevention(trigger.new);
    }
}