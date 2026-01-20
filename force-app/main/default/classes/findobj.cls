public class findobj {

    // Static method to perform dynamic SOSL search using user input
    public static void sr(String userInput,String obj) {
        // Escape single quotes to prevent SOSL injection
        String safeInput = String.escapeSingleQuotes(userInput);
		String bb = String.escapeSingleQuotes(obj);
        // Build SOSL query dynamically
        String query = 'FIND \'' + safeInput + '*\' IN ALL FIELDS RETURNING ' +
                       bb+'(id, Name)';

        // Execute the SOSL query
        List<List<SObject>> searchResults = Search.query(query);

        // Process Account results
        for (SObject s : searchResults[0]) {
            System.debug(obj +':' + s.get('Name'));
        }
    }


}