trigger exam_q1 on Contact (after insert) {
//Write a trigger on Contact that automatically updates the Phone field 
//of the related Account with the Phone of the latest created Contact, 
//whenever a new Contact is insert.

    if(trigger.isinsert && trigger.isAfter)
    {
        exam_q1_handler.handler(trigger.new);
    }
}