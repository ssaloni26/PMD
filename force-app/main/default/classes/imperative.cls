public class imperative {
	
    @AuraEnabled(cacheable = true)
    public static List<invoice__c> getPlayersList(){
        List<invoice__c> playerListForLwc =[select id , name from invoice__c];
        return playerListForLwc;
    }
}