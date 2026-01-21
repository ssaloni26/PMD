trigger usecase1 on Task (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        for (Task taskRecord : Trigger.new) {
            taskRecord.Priority = 'High'; // Set priority
            // Print full task info
            System.debug('Task Record => Subject: ' + taskRecord.Subject +
                         ', Status: ' + taskRecord.Status +
                         ', OwnerId: ' + taskRecord.OwnerId +
                         ', Priority: ' + taskRecord.Priority);
        }
    }
}