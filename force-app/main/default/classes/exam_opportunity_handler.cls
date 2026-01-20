public class exam_opportunity_handler {

    public static void classhandler(List<Opportunity> oppRecord) {
        //if (!oppRecord.isEmpty()) {
		if (oppRecord != null && !oppRecord.isEmpty()) {

            // ID
            Set<Id> closedWonIds = new Set<Id>();

            for (Opportunity opp : oppRecord) 
            {
                if (opp.StageName != null && opp.StageName.toLowerCase() == 'closed won') 
                {
                    closedWonIds.add(opp.Id);
                }
            }

            for (Opportunity opps : oppRecord) {
                if (closedWonIds.contains(opps.Id)) {
                    opps.addError('Cannot delete Opportunity with StageName = Closed Won.');
                }
            }
        }
    }
}