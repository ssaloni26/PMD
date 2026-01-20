/** Description
The DMLLoggerScheduler class automatically runs the DMLLoggerBatch daily for the previous
day’s event logs.
It ensures continuous and automated tracking of user DML activity in Salesforce. 
**/
global class DMLLoggerScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Date yesterday = Date.today().addDays(-1);
        Database.executeBatch(new DMLLoggerBatch(yesterday), 100);
    }
}