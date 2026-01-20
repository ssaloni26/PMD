public class Expense_Queueable implements Queueable{
    
    public void execute(Queueablecontext qc)
    {
        List<Expense__c> ExpenseRecords = [select id , New_Status__c , Amount__c from Expense__c where New_Status__c = 'Submitted' ];
        List<Audit_Expense__c> AuditRecords = new List<Audit_Expense__c>();
        for(Expense__c e : ExpenseRecords)
        {
            Audit_Expense__c newRecord = new Audit_Expense__c(Expense__c = e.id,Old_Status__c= 'Submitted');
            if(e.Amount__c >10000)
            {
            e.New_Status__c = 'Approved';
            newRecord.New_Status__c='Approved';
            AuditRecords.add(newRecord);
            
                
            }
            else
            {
                e.New_Status__c = 'Rejected';
                newRecord.New_Status__c='Rejected';
                AuditRecords.add(newRecord);
            }
        }
        
      
            update ExpenseRecords;
        
        if(!AuditRecords.isEmpty())
        {
            insert AuditRecords;
        }
        
        
    }

}