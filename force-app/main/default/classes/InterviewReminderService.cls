public with sharing class InterviewReminderService {

/* Feedback - try building out this on the stale job functionality:
- How many records can we mark as stale if we call directly from Service class? 10K - can query 50K, but can only update 10K
-- Pattern to use is Schedulable Batchable or Schedulable Queuable (that would be more relevant if time-sensitive)
- Schedulable opens up a new set of transaction limits: get limits only once for that
- Batch job was traditional guidance: not time sensitive, simple, feed it a query and it performs operation
-- Batch job can query as many as you want, 2K at a time
*/

    public static void sendEmail() {
        List<Event> tomorrowsEvents = getTomorrowsEvents();

        if (tomorrowsEvents.isEmpty()) {
            return;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String reminderEmailBody = generateReminderEmailBody(tomorrowsEvents);

        email.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
        email.setSubject('Reminder: Interview Tomorrow');
        email.setPlainTextBody(reminderEmailBody);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
    
    public static String generateReminderEmailBody(List<Event> tomorrowsEvents) {
        Map<Id, String> companyNamesByJobApplicationId = getCompanyNamesByJobApplicationId(tomorrowsEvents);
        String reminderEmailBody = 'You have the following interviews scheduled for tomorrow:\n';

        for (Event event : tomorrowsEvents) {
            String companyName = companyNamesByJobApplicationId.get(event.WhatId);

            reminderEmailBody = reminderEmailBody + 'Interview at: ' + companyName + '\n';
            reminderEmailBody = reminderEmailBody + 'Start: ' + event.StartDateTime.format() + '\n';
            reminderEmailBody = reminderEmailBody + 'Location: ' + event.Location + '\n\n';
        }
        
        return reminderEmailBody;
    }

    private static Map<Id, String> getCompanyNamesByJobApplicationId(List<Event> events) {
        Set<Id> jobApplicationIds = new Set<Id>();

        for (Event event : events) {
            jobApplicationIds.add(event.WhatId);
        }

        Map<Id, String> companyNamesByJobApplicationId = new Map<Id, String>();
        for (Job_Application__c jobApplication : [
            SELECT Id, Company_Name__r.Name
            FROM Job_Application__c
            WHERE Id IN :jobApplicationIds
        ]) {
            String companyName = jobApplication.Company_Name__r.Name;
            companyNamesByJobApplicationId.put(jobApplication.Id, companyName);
        }

        return companyNamesByJobApplicationId;
    }
    
    public static List<Event> getTomorrowsEvents() {
        Date tomorrow = Date.today().addDays(1);

        Datetime startOfTomorrow = Datetime.newInstance(
            tomorrow,
            Time.newInstance(0, 0, 0, 0)
        );

        Datetime startOfDayAfterTomorrow = startOfTomorrow.addDays(1);

        List<Event> tomorrowsEvents = [
            SELECT Id, Subject, StartDateTime, EndDateTime, Location, Description, WhatId, OwnerId
            FROM Event
            WHERE StartDateTime >= :startOfTomorrow
            AND StartDateTime < :startOfDayAfterTomorrow
            AND What.Type = 'Job_Application__c'
        ];

        return tomorrowsEvents;
    }
}
