public class GetContactOpportunityDetails {

    	
    @AuraEnabled(cacheable=true)
    public static List<Account> getChildDetails(String recId){
        System.debug(' Apex received recordId: ' + recId);
        List<Account> accList = [
            SELECT Id, Name,
                   (SELECT Id, LastName FROM Contacts),
                   (SELECT Id, Name FROM Opportunities)
            FROM Account
            WHERE Id = :recId
        ];
        System.debug(' accList result: ' + accList);
        return accList;
    }

}