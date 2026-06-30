public with sharing class StaleJobApplicationScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new StaleJobApplicationBatch(), 2000);
    }
}
