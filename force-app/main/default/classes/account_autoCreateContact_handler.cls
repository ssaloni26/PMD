public class account_autoCreateContact_handler {
	public static void CreateContact(list<account> accountList)
    {
        if(!accountList.isEmpty())
        {
            list<contact> contacts_to_update = new list<contact>();
            for(account a : accountList)
            {
                if (a.Name != null) {
                contact c = new contact(accountid = a.id ,FirstName = 'Default',LastName = a.Name );
                contacts_to_update.add(c);
            	}
            }
            
            if (!contacts_to_update.isEmpty()) {
            insert contacts_to_update;
        }
        }
    }
}