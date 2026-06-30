@isTest
private with sharing class JobContactTriggerHandler_Test {
    @TestSetup
    public static void createData() {
        TestDataFactory.createJobContacts();
    }

    @isTest
    public static void testPrimaryContact() {
        Job_Contact__c jobContact = [
            SELECT Id, Contact__c, Job_Application__c, Primary_Contact__c
            FROM Job_Contact__c
            LIMIT 1
        ];

        Test.startTest();
        jobContact.Primary_Contact__c = true;
        update jobContact;
        Test.stopTest();

        Job_Application__c jobApp = [
            SELECT Id, Primary_Contact__c
            FROM Job_Application__c
            WHERE Id = :jobContact.Job_Application__c
        ];

        System.assertEquals(jobContact.Contact__c, jobApp.Primary_Contact__c, 'Wrong or missing Primary Contact'); 
    }

}
