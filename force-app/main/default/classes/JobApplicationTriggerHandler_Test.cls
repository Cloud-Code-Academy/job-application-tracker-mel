@IsTest
private with sharing class JobApplicationTriggerHandler_Test {
    @TestSetup
    public static void createData() {
        TestDataFactory.createJobApplications();
        TestDataFactory.createContacts();
    }

    @IsTest
    static void testPrimaryContactLinkedOnUpdate() {
        List<Account> accounts = TestDataFactory.createAccounts();

        List<Job_Application__c> jobApplications = new List<Job_Application__c>();
        for (Integer i = 0; i < 5; i++) {
            Job_Application__c jobApplication = new Job_Application__c(
                Company_Name__c = accounts[i].Id,
                Status__c = 'Saved',
                Title__c = 'Test Job ' + i
            );
            jobApplications.add(jobApplication);
        }
        insert jobApplications;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact contact = new Contact(
                AccountId = accounts[i].Id,
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'bulk.update.contact.' + i + '@example.com'
            );
            contacts.add(contact);
        }
        insert contacts;

        for (Job_Application__c jobApp : jobApplications) {
            jobApp.Location__c = 'Remote';
        }

        update jobApplications;

        List<Job_Application__c> updatedJobApplications = [
            SELECT Id, Primary_Contact__c
            FROM Job_Application__c
            WHERE Id IN :jobApplications
        ];

        for (Job_Application__c jobApp : updatedJobApplications) {
            System.assertNotEquals(
                null,
                jobApp.Primary_Contact__c,
                'Primary Contact should be linked for every updated job application'
            );
        }
    }

    @IsTest
    static void testPrimaryContactLinkedOnInsert() {
        List<Contact> contacts = TestDataFactory.createContacts();

        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        for (Integer i = 0; i < 5; i++) {
            Job_Application__c newJobApp = new Job_Application__c(
                Company_Name__c = contacts[i].AccountId,
                Status__c = 'Saved',
                Title__c = 'Test Job ' + i
            );
            jobApps.add(newJobApp);
        }

        insert jobApps;

        List<Job_Application__c> insertedJobApps = [
            SELECT Id, Primary_Contact__c
            FROM Job_Application__c
            WHERE Id IN :jobApps
        ];

        for (Job_Application__c jobApp : insertedJobApps) {
            System.assertNotEquals(
                null,
                jobApp.Primary_Contact__c,
                'Primary Contact should be linked on insert'
            );
        }
    }

    @IsTest
    static void testTasksCreatedForEachStatus() {
        Map<String, Integer> expectedTaskCountByStatus = new Map<String, Integer>{
            'Saved' => 3,
            'Applying' => 5,
            'Applied' => 4,
            'Interviewing' => 5,
            'Negotiating' => 3,
            'Accepted' => 3,
            'Closed' => 2
        };

        Account account = new Account(Name = 'Task Status Test Account');
        insert account;

        List<Job_Application__c> jobApplications = new List<Job_Application__c>();
        for (String status : expectedTaskCountByStatus.keySet()) {
            Job_Application__c jobApplication = new Job_Application__c(
                Company_Name__c = account.Id,
                Status__c = status,
                Title__c = 'Task Status Test ' + status
            );
            jobApplications.add(jobApplication);
        }

        insert jobApplications;

        Map<Id, Integer> actualTaskCountByJobApplicationId = new Map<Id, Integer>();
        for (Job_Application__c jobApplication : jobApplications) {
            actualTaskCountByJobApplicationId.put(jobApplication.Id, 0);
        }

        List<Task> tasks = [
            SELECT WhatId
            FROM Task
            WHERE WhatId IN :actualTaskCountByJobApplicationId.keySet()
        ];

        for (Task task : tasks) {
            Integer currentCount = actualTaskCountByJobApplicationId.get(task.WhatId);
            actualTaskCountByJobApplicationId.put(task.WhatId, currentCount + 1);
        }

        for (Job_Application__c jobApplication : jobApplications) {
            System.assertEquals(
                expectedTaskCountByStatus.get(jobApplication.Status__c),
                actualTaskCountByJobApplicationId.get(jobApplication.Id),
                'Wrong number of follow-up tasks for status ' + jobApplication.Status__c
            );
        }
    }

    @IsTest
    static void testUpdateOnlyCreatesTaskWhenStatusChanges() {
        List<Job_Application__c> jobApplications = [
            SELECT Id, Notes__c, Status__c
            FROM Job_Application__c
            WHERE Status__c = 'Saved'
            LIMIT 1
        ];
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
