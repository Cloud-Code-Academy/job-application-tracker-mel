@IsTest
private with sharing class StaleJobApplicationBatch_Test {
    @TestSetup
    static void createData() {
        Account account = new Account(Name = 'Stale Job Application Test Account');
        insert account;

        List<Job_Application__c> jobApplications = new List<Job_Application__c>{
            new Job_Application__c(
                Company_Name__c = account.Id,
                Status__c = 'Saved',
                Title__c = 'Stale Saved Job',
                Follow_Up_Date__c = Date.today().addDays(-31)
            ),
            new Job_Application__c(
                Company_Name__c = account.Id,
                Status__c = 'Applied',
                Title__c = 'Stale Boundary Job',
                Follow_Up_Date__c = Date.today().addDays(-30),
                Notes__c = 'Existing note'
            ),
            new Job_Application__c(
                Company_Name__c = account.Id,
                Status__c = 'Applied',
                Title__c = 'Recent Follow Up Job',
                Follow_Up_Date__c = Date.today().addDays(-29)
            ),
            new Job_Application__c(
                Company_Name__c = account.Id,
                Status__c = 'Closed',
                Title__c = 'Already Closed Job',
                Follow_Up_Date__c = Date.today().addDays(-31)
            ),
            new Job_Application__c(
                Company_Name__c = account.Id,
                Status__c = 'Accepted',
                Title__c = 'Accepted Job',
                Follow_Up_Date__c = Date.today().addDays(-31)
            ),
            new Job_Application__c(
                Company_Name__c = account.Id,
                Status__c = 'Saved',
                Title__c = 'No Follow Up Job'
            )
        };

        insert jobApplications;
    }

    @IsTest
    static void closesOnlyStaleJobApplications() {
        Test.startTest();
        Database.executeBatch(new StaleJobApplicationBatch(), 2000);
        Test.stopTest();

        Map<String, Job_Application__c> jobApplicationsByTitle = getJobApplicationsByTitle();
        String closedNote = 'This job application was closed by an automated process.';

        System.assertEquals(
            'Closed',
            jobApplicationsByTitle.get('Stale Saved Job').Status__c,
            'A job with a follow-up date more than 30 days old should be closed'
        );
        System.assertEquals(
            closedNote,
            jobApplicationsByTitle.get('Stale Saved Job').Notes__c,
            'The batch should explain that automation closed the job'
        );

        System.assertEquals(
            'Closed',
            jobApplicationsByTitle.get('Stale Boundary Job').Status__c,
            'A job with a follow-up date exactly 30 days old should be closed'
        );
        System.assertEquals(
            'Existing note\n' + closedNote,
            jobApplicationsByTitle.get('Stale Boundary Job').Notes__c,
            'Existing notes should be kept when the automation note is added'
        );

        System.assertEquals(
            'Applied',
            jobApplicationsByTitle.get('Recent Follow Up Job').Status__c,
            'A job with a follow-up date less than 30 days old should stay open'
        );
        System.assertEquals(
            'Closed',
            jobApplicationsByTitle.get('Already Closed Job').Status__c,
            'A closed job should not be changed'
        );
        System.assertEquals(
            'Accepted',
            jobApplicationsByTitle.get('Accepted Job').Status__c,
            'An accepted job should not be changed'
        );
        System.assertEquals(
            'Saved',
            jobApplicationsByTitle.get('No Follow Up Job').Status__c,
            'A job without a follow-up date should not be changed'
        );
    }

    @IsTest
    static void schedulerStartsBatch() {
        Test.startTest();

        String jobId = System.schedule(
            'Test Stale Job Application Scheduler',
            '0 0 9 1 1 ? 2050',
            new StaleJobApplicationScheduler()
        );

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    private static Map<String, Job_Application__c> getJobApplicationsByTitle() {
        Map<String, Job_Application__c> jobApplicationsByTitle = new Map<String, Job_Application__c>();

        for (Job_Application__c jobApplication : [
            SELECT Id, Title__c, Status__c, Notes__c
            FROM Job_Application__c
        ]) {
            jobApplicationsByTitle.put(jobApplication.Title__c, jobApplication);
        }

        return jobApplicationsByTitle;
    }
}
