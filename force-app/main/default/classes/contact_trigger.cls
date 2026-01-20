public class contact_trigger {
	public static void contact_insertion_prevention(list<contact> contactRecords)
    {
        if(!contactRecords.isEmpty())
        {
            set<string> emails_to_check_duplication = new set<string>();
            for(contact cc : contactRecords)
            {
                emails_to_check_duplication.add(cc.email.toLowerCase());
                
            }
            
            if (emails_to_check_duplication.isEmpty()) return;

            set<string> already_exists_email = new set<string>();
            for(contact c: [select  email from contact where email != null and email in :emails_to_check_duplication])
            {
                if(c.email!=null)
                {
                    already_exists_email.add(c.Email.toLowerCase());
                }
            }
            
            for(contact c:contactRecords)
            {
                if(c.Email!= null && already_exists_email.contains(c.email.toLowerCase()))
                {
                    c.addError('same email of another contact');
                }
            }
        }
    }
}