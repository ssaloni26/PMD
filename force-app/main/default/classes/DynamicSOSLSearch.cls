public class DynamicSOSLSearch {

    // Static method to perform dynamic SOSL search using user input
    public static void sr(String userInput) {
        // Escape single quotes to prevent SOSL injection
        String safeInput = String.escapeSingleQuotes(userInput);

        // Build SOSL query dynamically
        String query = 'FIND \'' + safeInput + '*\' IN ALL FIELDS RETURNING ' +
                       'Account(Name), Contact(FirstName, LastName, Email), Invoice__c(Name)';

        // Execute the SOSL query
        List<List<SObject>> searchResults = Search.query(query);

        // Process Account results
        for (SObject s : searchResults[0]) {
            Account a = (Account)s;
            System.debug('Account: ' + a.Name);
        }

        // Process Contact results
        for (SObject s : searchResults[1]) {
            Contact c = (Contact)s;
            System.debug('Contact: ' + c.FirstName + ' ' + c.LastName + ' ' + c.Email);
        }

        // Process Invoice__c results (custom object)
        for (SObject s : searchResults[2]) {
            Invoice__c inv = (Invoice__c)s;
            System.debug('Invoice: ' + inv.Name);
        }
    }
}