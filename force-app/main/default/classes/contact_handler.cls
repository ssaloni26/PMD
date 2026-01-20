public class contact_handler {
    public static void account_description(List<Contact> contactRecord) {
        if (!contactRecord.isEmpty()) {
            Set<Id> accid = new Set<Id>();
            
            // Collect all related Account Ids from incoming contacts
            for (Contact c : contactRecord) {
                if (c.AccountId != null) {
                    accid.add(c.AccountId);
                }
            }

            //  // Query full Account records with their descriptions
            //List<Account> accList = [SELECT Id, Description FROM Account WHERE Id IN :accid];

            // Loop through each contact and match with each Account to set Description
            //for (Contact cc : contactRecord) {
            //    for (Account a : accList) {
            //      if (cc.AccountId == a.Id) {
            //        cc.Description = a.Description;
            //  }
            //   }
            // Query full Account records with their descriptions
           Map<id, Account> idVsAcc = new Map<id, Account>([SELECT Id, Description FROM Account WHERE Id IN :accid]);

            // Loop through each contact and match with each Account to set Description
            List<Contact> conList = new List<Contact>();
            for (Contact cc : contactRecord) {
                if(cc.Accountid != null){
                    Contact c = new Contact(id=cc.id, description=idVsAcc.get(cc.Accountid).description);
                    conList.add(c);
                }
            }
            update conList;
        }
    }
}