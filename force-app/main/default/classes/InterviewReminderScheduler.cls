public with sharing class InterviewReminderScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        InterviewReminderService.sendEmail();
    }
}