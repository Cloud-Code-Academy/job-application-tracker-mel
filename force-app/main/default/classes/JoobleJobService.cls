public with sharing class JoobleJobService {
    private static final String NAMED_CREDENTIAL = 'callout:Jooble';
    private static final Integer RESULT_LIMIT = 10;
    private static final String IMPORTED_STATUS = 'Saved';

    public class JoobleRequest {
        public String keywords;
        public String location;
        public Integer page;
        public Integer ResultOnPage;
        public String companysearch;

        public JoobleRequest() {
        }

        public JoobleRequest(
            String keywords,
            String location,
            Integer page,
            Integer resultOnPage,
            Boolean companySearch
        ) {
            this.keywords = keywords;
            this.location = location;
            this.page = page;
            this.ResultOnPage = resultOnPage;
            this.companysearch = String.valueOf(companySearch);
        }
    }

    public class JoobleResponse {
        public List<JoobleJob> jobs;
    }

    public class JoobleJob {
        public String title;
        public String location;
        public String link;
        public String salary;
    }

    public static void fetchSalesforceJobs() {
        HttpRequest request = new HttpRequest();

        request.setEndpoint(NAMED_CREDENTIAL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        JoobleRequest requestBody = new JoobleRequest(
            'Salesforce',
            'United States',
            1,
            RESULT_LIMIT,
            false
        );

        request.setBody(JSON.serialize(requestBody));

        Http http = new Http();
        HttpResponse response = http.send(request);

        // What happens if we send the call but they don't return it = callout exception: timeout or they never reply
        // You may or may not want to handle callout exception: could consider Nebula Logger then catch and rethrow

        if (response.getStatusCode() != 200) {
            return;
        }

        // In this code, we just stop here
        // In real world: throw a Nebula logger exception here; could schedule a retry (501), even immediately;
        // cont: add more specific error message that includes the code for other users to troubleshoot
        // Important to be decisive about failures in your code: could decide to log out everything on failures for engineer to review in Slack

        JoobleResponse responseBody = (JoobleResponse) JSON.deserialize(response.getBody(), JoobleResponse.class);
        List<JoobleJob> jobs = responseBody == null ? null : responseBody.jobs;

        // If we know that we'll get back a specific format based on documentation, it's even more important to build class for response than for request
        // Could make another inner class here as well - use this as a data structure so you don't have to think where URL gets stored - see it there
        // Deserialize in a single call with deserialize strict or deserialize (no untyped and if a mismatch in type, get an error)
        // Better to handle this because we can get a bad JSON exception --> deserialize into a specific response body
        // Using the contract framework allows you to provide guarantees to stakeholders

        if (jobs == null || jobs.isEmpty()) {
            return;
        }

        // These kind of null checks can still be good practice - varies based on integration: good for Jooble
        // Still, better to alert rather than return with no info - if it starts coming back empty, we want to know that

        Set<String> joobleJobUrls = new Set<String>();
        for (JoobleJob job : jobs) {
            if (!String.isBlank(job.link)) {
                joobleJobUrls.add(job.link);
            }
        }

        if (joobleJobUrls.isEmpty()) {
            return;
        }

        Set<String> existingJobUrls = new Set<String>();
        for (Job_Application__c existingJobApplication : [
            SELECT URL__c
            FROM Job_Application__c
            WHERE URL__c IN :joobleJobUrls
        ]) {
            existingJobUrls.add(existingJobApplication.URL__c);
        }

        // Could refactor to use Jooble Job ID as unique key here - probably more reliable than URL as unique key

        List<Job_Application__c> newJobApps = new List<Job_Application__c>();
        for (JoobleJob job : jobs) {
            String url = job.link;

            if (String.isBlank(url) || existingJobUrls.contains(url)) {
                continue;
            }

            newJobApps.add(buildJobApplication(job));
        }

        if (newJobApps.isEmpty()) {
            return;
        }

        insert newJobApps;
    }

    private static Job_Application__c buildJobApplication(JoobleJob job) {
        return new Job_Application__c(
            Title__c = job.title,
            Location__c = job.location,
            URL__c = job.link,
            Salary__c = parseSalary(job.salary),
            Status__c = IMPORTED_STATUS
        );
    }

    private static Decimal parseSalary(String salaryText) {
        if (String.isBlank(salaryText)) {
            return null;
        }

        List<Decimal> salaryNumbers = extractSalaryNumbers(salaryText);

        if (salaryNumbers.isEmpty()) {
            return null;
        }

        Decimal salary = salaryNumbers[0];

        if (salaryNumbers.size() > 1 && salaryNumbers[1] < salary) {
            salary = salaryNumbers[1];
        }

        return salary;
    }

    private static List<Decimal> extractSalaryNumbers(String salaryText) {
        List<Decimal> salaryNumbers = new List<Decimal>();
        String cleanedSalaryText = salaryText.toLowerCase()
            .replace('$', '')
            .replace(',', '');
        String currentNumber = '';

        for (Integer i = 0; i < cleanedSalaryText.length(); i++) {
            String currentCharacter = cleanedSalaryText.substring(i, i + 1);

            if (isNumberCharacter(currentCharacter)) {
                currentNumber += currentCharacter;
            } else if (currentCharacter == 'k' && !String.isBlank(currentNumber)) {
                salaryNumbers.add(Decimal.valueOf(currentNumber) * 1000);
                currentNumber = '';
            } else {
                addSalaryNumber(salaryNumbers, currentNumber);
                currentNumber = '';
            }
        }

        addSalaryNumber(salaryNumbers, currentNumber);

        return salaryNumbers;
    }

    private static void addSalaryNumber(List<Decimal> salaryNumbers, String salaryNumberText) {
        if (String.isBlank(salaryNumberText) || salaryNumberText == '.') {
            return;
        }

        salaryNumbers.add(Decimal.valueOf(salaryNumberText));
    }

    private static Boolean isNumberCharacter(String value) {
        return value == '.' || '0123456789'.contains(value);
    }

}
