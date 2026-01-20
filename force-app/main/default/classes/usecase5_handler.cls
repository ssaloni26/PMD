/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-01-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class usecase5_handler {
    public static void usecase(List<opportunity> newrecords) 
    {
        List<task> taskRecordToInsert=new List<task>();
        for(opportunity opp: newrecords)
        {
            if(opp.stagename=='closed won')
            {
                //create a task for related record
                task taskRecord = new task();
                taskRecord.priority ='high';
                taskRecord.Ownerid =opp.Ownerid;
                taskRecord.description ='plz split revenue';
                taskRecord.status ='not started';
                taskRecord.subject ='spli revenue';
                taskRecord.whatid =opp.id;
                taskRecordToInsert.add(taskRecord);

            }
        }

        if(!taskRecordToInsert.isEmpty())
        {
            insert taskRecordToInsert;
        }
    }
}