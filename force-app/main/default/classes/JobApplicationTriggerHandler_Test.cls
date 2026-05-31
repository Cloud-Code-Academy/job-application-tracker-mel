@isTest
private with sharing class JobApplicationTriggerHandler_Test {
    @isTest
    static void testTasksCreatedForEachStatus() {
        List<Job_Application__c> jobApplications = TestDataFactory.createJobApplications();

        Map<Id, Job_Application__c> jobApplicationsById = new Map<Id, Job_Application__c>(jobApplications);
        List<Task> tasks = [
            SELECT WhatId, Subject, ActivityDate
            FROM Task
            WHERE WhatId IN :jobApplicationsById.keySet()
        ];

        System.assertEquals(37, tasks.size(), 'Each job application should create its configured follow-up tasks');
    }

    @isTest
    static void testUpdateOnlyCreatesTaskWhenStatusChanges() {
        List<Job_Application__c> jobApplications = TestDataFactory.createJobApplications();
        Job_Application__c jobApplication = jobApplications[0];

        Integer taskCountAfterInsert = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :jobApplication.Id
        ];

        jobApplication.Notes__c = 'Updated notes without a status change';
        update jobApplication;

        Integer taskCountAfterNotesUpdate = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :jobApplication.Id
        ];

        System.assertEquals(
            taskCountAfterInsert,
            taskCountAfterNotesUpdate,
            'Updating another field should not create a duplicate task'
        );

        jobApplication.Status__c = 'Applied';
        update jobApplication;

        Integer taskCountAfterStatusUpdate = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :jobApplication.Id
        ];

        System.assertEquals(
            taskCountAfterInsert + 4,
            taskCountAfterStatusUpdate,
            'Changing to Applied should create the four Applied follow-up tasks'
        );
    }
}
