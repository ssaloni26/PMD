public class MultiObjectSoslSoqlDml {

    public static void runLogic() {
        String keyword = 'Demo';
        String safeInput = String.escapeSingleQuotes(keyword);

        // 🔍 SOSL Search across 3 standard objects
        String query = 'FIND \'' + safeInput + '*\' IN ALL FIELDS RETURNING ' +
                       'Account(Id, Name), ' +
                       'Contact(Id, FirstName, LastName), ' +
                       'Lead(Id, FirstName, LastName)';

        List<List<SObject>> searchResults = Search.query(query);

        // ---------------------
        // ✅ Step 1: Collect Ids
        // ---------------------
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();

        for (SObject s : searchResults[0]) accountIds.add(((Account)s).Id);
        for (SObject s : searchResults[1]) contactIds.add(((Contact)s).Id);
        for (SObject s : searchResults[2]) leadIds.add(((Lead)s).Id);

        // ---------------------
        // ✅ Step 2: SOQL Queries
        // ---------------------
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id IN :accountIds];
        List<Contact> contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE Id IN :contactIds];
        List<Lead> leads = [SELECT Id, FirstName, LastName FROM Lead WHERE Id IN :leadIds];

        // ---------------------
        // ✅ Step 3: Perform DML (update)
        // ---------------------
        for (Account acc : accounts) {
            acc.Name += ' [Updated]';
        }

        for (Contact c : contacts) {
            c.LastName += ' [Updated]';
        }

        for (Lead l : leads) {
            l.LastName += ' [Updated]';
        }

        // Perform bulk updates
        update accounts;
        update contacts;
        update leads;

        // 🖨️ Debug updated records
        for (Account a : accounts) System.debug('Account: ' + a.Id + ' - ' + a.Name);
        for (Contact c : contacts) System.debug('Contact: ' + c.Id + ' - ' + c.FirstName + ' ' + c.LastName);
        for (Lead l : leads) System.debug('Lead: ' + l.Id + ' - ' + l.FirstName + ' ' + l.LastName);

        // ---------------------
        // ✅ Step 4: (Optional) Delete records for test cleanup
        // ---------------------
        // delete accounts;
        // delete contacts;
        // delete leads;
    }
}