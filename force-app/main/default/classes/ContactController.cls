public with sharing class ContactController {
    
@AuraEnabled(cacheable=true)
public static List<Contact> getContacts(Integer pageSize, Integer offsetRecords) {
    return [
        SELECT Id, FirstName, LastName, Email, Phone, Account.Name
        FROM Contact
        ORDER BY CreatedDate DESC
        LIMIT :pageSize
        OFFSET :offsetRecords
    ];
}
@AuraEnabled
public static void updateContacts(List<Contact> contacts) {
    update contacts;
}



    @AuraEnabled(cacheable=true)
    public static Integer getContactCount() {
        return [SELECT COUNT() FROM Contact];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContact() {
        return [SELECT Id, FirstName, LastName, Email, Phone, Account.Name FROM Contact ORDER BY CreatedDate DESC LIMIT 50];
    }
    
    

    @AuraEnabled
    public static String saveContact(Contact con) {
        try {
            if (con.Id == null) {
                insert con;
                
                return 'Contact created successfully with Id: ' + con.Id;
                
            } else {
                update con;
                return 'Contact updated successfully with Id: ' + con.Id;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error while saving contact: ' + e.getMessage());
        }
    } 

    @AuraEnabled
    public static void deleteContact(Id contactId) {
        delete [SELECT Id FROM Contact WHERE Id = :contactId];
    }
}