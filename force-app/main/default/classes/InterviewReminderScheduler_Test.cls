@IsTest
private with sharing class InterviewReminderScheduler_Test {
    @IsTest
    static void schedulerRunsReminderLogic() {
        TestDataFactory.createEvents();

        Test.startTest();

        String jobId = System.schedule(
            'Test of Interview Reminder Scheduler', 
            '0 0 9 1 1 ? 2050', 
            new InterviewReminderScheduler()
        );

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }
}