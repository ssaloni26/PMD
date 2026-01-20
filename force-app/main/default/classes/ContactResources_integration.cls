/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-11-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

//WebService
@RestResource(urlMapping='/ContactAPI/*')
global with sharing class ContactResources_integration {
    // GET method to return list of Contact Ids and Names
    @HttpGet
    global static List<Contact> getContactIdAndNames() {
        return [SELECT Id, FirstName, LastName FROM Contact LIMIT 100];
    }

    // POST method to create a new Contact record
    @HttpPost
    global static Contact createNewContact(String firstName, String lastName, String birthDate, String leadSource) {
        Contact c = new Contact();
        c.FirstName = firstName;
        c.LastName = lastName;
        if (birthDate != null) {
            c.Birthdate = Date.valueOf(birthDate);
        }
        c.LeadSource = leadSource;
        insert c;
        return c;
    }

    // DELETE method to delete a contact by Id (passed as query parameter)
    @HttpDelete
    global static Map<String, String> deleteContact() {
        RestRequest req = RestContext.request;
        String contactId = req.params.get('id');
        Map<String, String> response = new Map<String, String>();
        try {
            Contact c = [SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1];
            delete c;
            response.put('status', 'success');
            response.put('message', 'Contact deleted successfully.');
        } catch (Exception e) {
            response.put('status', 'error');
            response.put('message', e.getMessage());
        }
        return response;
    }

    // PUT method to upsert a Contact by external Id (or create new if not found)
    @HttpPut
    global static Contact upsertContact(String firstName, String lastName, String birthDate, String leadSource) {
        Contact c;

        // Query returns a list to safely check if a contact exists
        List<Contact> contacts = [SELECT Id,FirstName, LastName, Birthdate, LeadSource  FROM Contact LIMIT 1];

        if (!contacts.isEmpty()) {
            c = contacts[0];
        } else {
            c = new Contact();
            
        }

        c.FirstName = firstName;
        c.LastName = lastName;

        if (birthDate != null) {
            c.Birthdate = Date.valueOf(birthDate);
        }

        c.LeadSource = leadSource;

        upsert c ;

        return c;
    }


    // PATCH method to update Contact fields partially (expects JSON body)
    @HttpPatch
    global static Contact updateContact() {
        RestRequest req = RestContext.request;
        // Parse JSON body
        String reqBody = req.requestBody.toString();
        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(reqBody);

        String contactId = (String) params.get('Id');
        if (contactId == null) {
            throw new AuraHandledException('Contact Id is required for update');
        }
        Contact c = [SELECT Id, FirstName, LastName, Birthdate, LeadSource FROM Contact WHERE Id = :contactId LIMIT 1];

        if (params.containsKey('FirstName')) c.FirstName = (String) params.get('FirstName');
        if (params.containsKey('LastName')) c.LastName = (String) params.get('LastName');
        if (params.containsKey('Birthdate')) c.Birthdate = Date.valueOf((String) params.get('Birthdate'));
        if (params.containsKey('LeadSource')) c.LeadSource = (String) params.get('LeadSource');

        update c;
        return c;
    }
}