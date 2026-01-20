public class AccountComplianceJob implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext qc) {
        List<Account> accs = [SELECT Id, Name FROM Account LIMIT 5];
        for (Account a : accs) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:ComplianceAPI/accounts/' + a.Id);
            req.setMethod('GET');
            Http h = new Http();
            HttpResponse res = h.send(req);

            if (res.getStatusCode() == 200) {
                System.debug('status');
            }
        }
        update accs;
    }
}