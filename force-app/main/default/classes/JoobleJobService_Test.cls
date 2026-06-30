@IsTest
private with sharing class JoobleJobService_Test {
    private class JoobleSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('callout:Jooble', request.getEndpoint(), 'Expected the Jooble named credential.');
            System.assertEquals('POST', request.getMethod(), 'Expected a POST request.');

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"jobs":[{"title":"Existing Salesforce Admin","link":"https://example.com/existing"},{"title":"Salesforce Developer","location":"Remote","link":"https://example.com/developer","salary":"$100,000 - $120,000 a year"}]}');
            return response;
        }
    }

    private class JoobleSalaryFormatsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('callout:Jooble', request.getEndpoint(), 'Expected the Jooble named credential.');
            System.assertEquals('POST', request.getMethod(), 'Expected a POST request.');

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody(
                '{"jobs":[' +
                '{"title":"Range Salary","link":"https://example.com/range","salary":"$100,000 - $120,000 a year"},' +
                '{"title":"K Salary","link":"https://example.com/k","salary":"Estimated $95K per year"},' +
                '{"title":"Hourly Salary","link":"https://example.com/hourly","salary":"$50 - $60 an hour"},' +
                '{"title":"Monthly Salary","link":"https://example.com/monthly","salary":"$6,000 monthly"},' +
                '{"title":"No Salary","link":"https://example.com/no-salary","salary":"Competitive salary"}' +
                ']}'
            );
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

        Map<String, Job_Application__c> jobsByUrl = queryJobsByUrl(new Set<String>{
            'https://example.com/existing',
            'https://example.com/developer'
        });

        System.assertEquals(2, jobsByUrl.size(), 'Expected the existing record plus one new Jooble record.');

        Job_Application__c newJob = jobsByUrl.get('https://example.com/developer');
        System.assertNotEquals(null, newJob, 'Expected the new Jooble job to be inserted.');
        System.assertEquals('Salesforce Developer', newJob.Title__c, 'Expected the title from Jooble.');
        System.assertEquals('Remote', newJob.Location__c, 'Expected the location from Jooble.');
        System.assertEquals(100000.00, newJob.Salary__c, 'Expected the lower salary from the Jooble range.');
        System.assertEquals('Saved', newJob.Status__c, 'Expected imported jobs to start as Saved.');
    }

    @IsTest
    static void fetchSalesforceJobsMapsCommonSalaryFormats() {
        Test.setMock(HttpCalloutMock.class, new JoobleSalaryFormatsMock());

        Test.startTest();
        JoobleJobService.fetchSalesforceJobs();
        Test.stopTest();

        Map<String, Job_Application__c> jobsByUrl = queryJobsByUrl(new Set<String>{
            'https://example.com/range',
            'https://example.com/k',
            'https://example.com/hourly',
            'https://example.com/monthly',
            'https://example.com/no-salary'
        });

        System.assertEquals(5, jobsByUrl.size(), 'Expected all Jooble salary examples to be inserted.');
        System.assertEquals(100000.00, jobsByUrl.get('https://example.com/range').Salary__c, 'Expected salary ranges to use the lower number.');
        System.assertEquals(95000.00, jobsByUrl.get('https://example.com/k').Salary__c, 'Expected K shorthand to map to thousands.');
        System.assertEquals(50.00, jobsByUrl.get('https://example.com/hourly').Salary__c, 'Expected hourly salaries to use the lower number without conversion.');
        System.assertEquals(6000.00, jobsByUrl.get('https://example.com/monthly').Salary__c, 'Expected monthly salaries to use the number without conversion.');
        System.assertEquals(null, jobsByUrl.get('https://example.com/no-salary').Salary__c, 'Expected non-numeric salary text to stay blank.');
    }

    private static Map<String, Job_Application__c> queryJobsByUrl(Set<String> urls) {
        Map<String, Job_Application__c> jobsByUrl = new Map<String, Job_Application__c>();

        for (Job_Application__c savedJob : [
            SELECT Title__c, Location__c, Salary__c, Status__c, URL__c
            FROM Job_Application__c
            WHERE URL__c IN :urls
        ]) {
            jobsByUrl.put(savedJob.URL__c, savedJob);
        }

        return jobsByUrl;
    }
}
