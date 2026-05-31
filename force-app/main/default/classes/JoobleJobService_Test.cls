@IsTest
private with sharing class JoobleJobService_Test {
    private class JoobleSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('callout:Jooble', request.getEndpoint(), 'Expected the Jooble named credential.');
            System.assertEquals('POST', request.getMethod(), 'Expected a POST request.');

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"jobs":[{"title":"Existing Salesforce Admin","link":"https://example.com/existing"},{"title":"Salesforce Developer","link":"https://example.com/developer"}]}');
            return response;
        }
    }

    @IsTest
    static void fetchSalesforceJobsCreatesOnlyNewJobs() {
        insert new Job_Application__c(
            Title__c = 'Existing Salesforce Admin',
            Status__c = 'Saved',
            URL__c = 'https://example.com/existing'
        );

        Test.setMock(HttpCalloutMock.class, new JoobleSuccessMock());

        Test.startTest();
        JoobleJobService.fetchSalesforceJobs();
        Test.stopTest();

        List<Job_Application__c> savedJobs = [
            SELECT Title__c, Status__c, URL__c
            FROM Job_Application__c
            WHERE URL__c IN ('https://example.com/existing', 'https://example.com/developer')
        ];

        System.assertEquals(2, savedJobs.size(), 'Expected the existing record plus one new Jooble record.');

        Map<String, Job_Application__c> jobsByUrl = new Map<String, Job_Application__c>();
        for (Job_Application__c savedJob : savedJobs) {
            jobsByUrl.put(savedJob.URL__c, savedJob);
        }

        Job_Application__c newJob = jobsByUrl.get('https://example.com/developer');
        System.assertNotEquals(null, newJob, 'Expected the new Jooble job to be inserted.');
        System.assertEquals('Salesforce Developer', newJob.Title__c, 'Expected the title from Jooble.');
        System.assertEquals('Saved', newJob.Status__c, 'Expected imported jobs to start as Saved.');
    }
}
