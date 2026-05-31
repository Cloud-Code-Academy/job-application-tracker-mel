trigger JobContactTrigger on Job_Contact__c (after insert, after update) {
    new JobContactTriggerHandler().run();
}
