trigger q3 on Lead (before insert, before update) 
{
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) 
    {
        q3_handler.leadBeforeInsertUpdate(Trigger.new);
    }
}