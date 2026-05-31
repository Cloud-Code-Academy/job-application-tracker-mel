public with sharing class JoobleJobService {
    private static final String NAMED_CREDENTIAL = 'callout:Jooble';
    private static final Integer RESULT_LIMIT = 10;

    public static void fetchSalesforceJobs() {
        HttpRequest request = new HttpRequest();

        request.setEndpoint(NAMED_CREDENTIAL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        Map<String, Object> requestBody = new Map<String, Object>{
            'keywords' => 'Salesforce',
            'location' => 'United States',
            'page' => 1,
            'ResultOnPage' => RESULT_LIMIT,
            'companysearch' => 'false'
        };

        request.setBody(JSON.serialize(requestBody));

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() != 200) {
            return;
        }

        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> jobs = (List<Object>) responseBody.get('jobs');

        if (jobs == null || jobs.isEmpty()) {
            return;
        }

        Set<String> joobleJobUrls = new Set<String>();
        for (Object jobObject : jobs) {
            Map<String, Object> job = (Map<String, Object>) jobObject;
            String url = (String) job.get('link');

            joobleJobUrls.add(url);
        }

        Set<String> existingJobUrls = new Set<String>();
        for (Job_Application__c existingJobApplication : [
            SELECT URL__c
            FROM Job_Application__c
            WHERE URL__c IN :joobleJobUrls
        ]) {
            existingJobUrls.add(existingJobApplication.URL__c);
        }

        List<Job_Application__c> newJobApps = new List<Job_Application__c>();
        for (Object jobObject : jobs) {
            Map<String, Object> job = (Map<String, Object>) jobObject;
            String url = (String) job.get('link');

            if (existingJobUrls.contains(url)) {
                continue;
            }

            newJobApps.add(new Job_Application__c(
                Title__c = (String) job.get('title'),
                Location__c = (String) job.get('location'),
                URL__c = url,
                Status__c = 'Saved'
            ));
        }

        insert newJobApps;
    }
}
