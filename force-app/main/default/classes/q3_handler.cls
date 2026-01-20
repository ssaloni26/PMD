public class q3_handler {
    public static void leadBeforeInsertUpdate(List<Lead> leadRecords) {
        if (!leadRecords.isEmpty()) {
        Set<String> leadEmailSet = new Set<String>();
		
        //EXTRACT EMAIL
        for (Lead ldObj : leadRecords) {
            if (!String.isBlank(ldObj.Email)) {
                leadEmailSet.add(ldObj.Email.trim().toLowerCase()); // normalize
            }
        }
		
        //MATCH EMAILS FROM CONTACTS
        if (!leadEmailSet.isEmpty()) {
            List<Contact> existingContacts = [SELECT Id, Email FROM Contact WHERE Email IN :leadEmailSet];
            
            
            Set<String> existingEmails = new Set<String>();
			
            //STORING CONTACTS MATCHING EMAILS IN SET
            for (Contact con : existingContacts) {
                if (!String.isBlank(con.Email)) {
                    existingEmails.add(con.Email.trim().toLowerCase());
                }
            }
			
            
            //FINAL CHECK AND THROW ERROR
            for (Lead ldObj : leadRecords) {
                if (!String.isBlank(ldObj.Email)) {
                    if (existingEmails.contains(ldObj.Email.trim().toLowerCase())) {
                        ldObj.addError('Email already exists in Contact records.');
                    }
                } else {
                    ldObj.addError('Please enter an Email Address.');
                }
            }
        }
        }
    }
        
}