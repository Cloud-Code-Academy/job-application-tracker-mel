public with sharing class StaleJobApplicationBatch implements Database.Batchable<SObject> {
    private static final String CLOSED_NOTE = 'This job application was closed by an automated process.';

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date staleFollowUpDate = Date.today().addDays(-30);

        return Database.getQueryLocator([
            SELECT Id, Status__c, Notes__c
            FROM Job_Application__c
            WHERE Status__c NOT IN ('Closed', 'Accepted')
            AND Follow_Up_Date__c <= :staleFollowUpDate
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> records) {
        List<Job_Application__c> jobApplicationsToUpdate = new List<Job_Application__c>();

        for (SObject record : records) {
            Job_Application__c jobApplication = (Job_Application__c) record;

            jobApplication.Status__c = 'Closed';
            jobApplication.Notes__c = getUpdatedNotes(jobApplication.Notes__c);
            jobApplicationsToUpdate.add(jobApplication);
        }

        if (!jobApplicationsToUpdate.isEmpty()) {
            update jobApplicationsToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    private static String getUpdatedNotes(String notes) {
        if (String.isBlank(notes)) {
            return CLOSED_NOTE;
        }

        return notes + '\n' + CLOSED_NOTE;
    }
}
