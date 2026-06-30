public with sharing class JobContactTriggerHandler extends TriggerHandler {
    private List<Job_Contact__c> newJobContactList;

    public JobContactTriggerHandler() {
        this.newJobContactList = (List<Job_Contact__c>) Trigger.new;
    }

    public override void afterInsert() {
        setPrimaryContact(newJobContactList);
    }

    public override void afterUpdate() {
        setPrimaryContact(newJobContactList);
    }

    public static void setPrimaryContact(List<Job_Contact__c> jobContactList) {
        Map<Id, Job_Application__c> jobApplicationsById = new Map<Id, Job_Application__c>();

        for (Job_Contact__c jobContact : jobContactList) {
            if (jobContact.Primary_Contact__c == true) {
                jobApplicationsById.put(
                    jobContact.Job_Application__c,
                    new Job_Application__c(
                        Id = jobContact.Job_Application__c,
                        Primary_Contact__c = jobContact.Contact__c
                    )
                );
            }
        }

        if (!jobApplicationsById.isEmpty()) {
            update jobApplicationsById.values();
        }
    }
}
