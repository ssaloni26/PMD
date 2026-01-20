public class ChainingQueueable {
    public class Step1_UpdateOppty implements Queueable {
        public void execute(QueueableContext qc) {
            List<Opportunity> opps = [SELECT Id, StageName FROM Opportunity WHERE StageName != 'Closed Won' LIMIT 50];
            System.debug('Step 1 - Records fetched: ' + opps.size());
            for (Opportunity o : opps) {
                o.StageName = 'Prospecting';
            }
            update opps;

            System.enqueueJob(new Step2_RecalculateField());
        }
    }

    public class Step2_RecalculateField implements Queueable {
        public void execute(QueueableContext qc) {
            List<Opportunity> opps = [SELECT Id, Amount FROM Opportunity WHERE StageName = 'Prospecting'];
            System.debug('Step 2 - Records fetched: ' + opps.size());
            for (Opportunity o : opps) {
                o.Amount = o.Amount != null ? o.Amount * 1.1 : 1000;
            }
            update opps;

            System.enqueueJob(new Step3_NotifyUsers());
        }
    }

    public class Step3_NotifyUsers implements Queueable {
        public void execute(QueueableContext qc) {
            System.debug('Step 3 - Sending email...');
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] {'test@example.com'});
            mail.setSubject('Oppty Update Completed');
            mail.setPlainTextBody('All steps done.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        }
    }
}