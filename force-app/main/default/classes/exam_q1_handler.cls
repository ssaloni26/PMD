public class exam_q1_handler {
	public static void handler(list<contact> contactRecord)
    {
        if(!contactRecord.isEmpty())
        {
            contact contact_id_phone = [SELECT Id,AccountId , Phone FROM Contact where AccountId !=null ORDER BY CreatedDate DESC limit 1 ];
            
            if (contact_id_phone.AccountId != null && contact_id_phone.Phone != null)
            {
            Account accToUpdate = new Account(Id = contact_id_phone.AccountId , Phone = contact_id_phone.Phone);
            update accToUpdate;
            }
        }
    }
}