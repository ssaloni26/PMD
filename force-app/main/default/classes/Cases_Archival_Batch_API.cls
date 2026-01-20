global class Cases_Archival_Batch_API implements Database.Batchable<SObject> , Database.AllowsCallouts{

    global Database.QueryLocator start(Database.BatchableContext bc){
        System.debug('Started');
        return Database.getQueryLocator([SELECT Id, CaseNumber, Subject, Description from Case where Status = 'Closed']);
        
    }
    global void execute(Database.BatchableContext bc,List<Case> CaseRecords){
      if(CaseRecords!=null && !CaseRecords.isEmpty() ){
        List<case> Cases_To_Update = new List<case>();
        For(case c:CaseRecords){
            try{
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:JSONPlaceholderAPI/posts');
            req.setMethod('POST');	
            req.setHeader('Content-Type', 'application/json');
            Map<String,Object> Json_payload = new Map<String,Object>{'title'=>c.Subject,'body'=>c.Description,'userId'=>c.CaseNumber};
            req.setBody(JSON.serialize(Json_payload));
            Http http = new Http();
            HttpResponse res = http.send(req);
            if(res.getStatusCode()==201) {
                Map<String,Object> Response_Map = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                if(Response_Map.containsKey('id')) {
                c.Description = 'Archival Id:'+ String.valueOf(Response_Map.get('id'));
                Cases_To_Update.add(c);
                }
            }
            }catch(Exception e)
            {
                System.debug('Exception Occur' + e.getMessage());
            }
        }
        if(!Cases_To_Update.isEmpty())
        {
            update Cases_To_Update;
            System.debug('Updated');
        }
        }
    }
	global void finish(Database.BatchableContext bc){
        System.debug('Archival Batch Completed');
    }                        
}