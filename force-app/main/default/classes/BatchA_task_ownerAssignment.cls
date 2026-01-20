//use SObject because we are using 2 objec as input list
global class BatchA_task_ownerAssignment implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc)
        
    {
        System.debug('inside start');
        return Database.getQueryLocator([select id,OwnerId,Owner.isActive from account ]);                    
    }

    //global void execute(Database.batchablecontext bs , List<account> accRecords)
    //{
    //    System.debug('account ');
  //  }
    //SObject becoz we use 2 or more objects
    global void execute(Database.BatchableContext bc,List<opportunity> opportunityRecords)
    {
		System.debug('inside st');
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        List<task> create_task= new list<task>();
        System.debug(opportunityRecords);
        
        for(opportunity opp: opportunityRecords)
        {
            task t = new task(Subject='Review Opportunity',whatid= opp.id,status = 'not started' );
            if(opp.Owner.isActive){
                t.OwnerId=  opp.OwnerId;
                create_task.add(t);
            }
            else
            {
                t.OwnerId = adminUser.id;
            	create_task.add(t);
            }
        }
        
        
        //both null & empty 
        if(create_task != null && !create_task.isEmpty()){
        	Database.insert(create_task, false);
        }
        
    }

	global void finish(Database.BatchableContext bc)
    {
        System.debug('inside ff');
    }    
}