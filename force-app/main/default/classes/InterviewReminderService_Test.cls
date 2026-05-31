@IsTest
private with sharing class InterviewReminderService_Test {
    @TestSetup
    static void makeData(){
        TestDataFactory.createEvents();
    }

    @IsTest
    static void getTomorrowsEventsTest() {
        List<Event> tomorrowsEvents = InterviewReminderService.getTomorrowsEvents();

        System.assertEquals(
            2,
            tomorrowsEvents.size(),
            'Expected the service to find the two events scheduled for tomorrow.'
        );

        for (Event event : tomorrowsEvents) {
            System.assertEquals(
                Date.today().addDays(1),
                event.StartDateTime.date(),
                'Expected each returned event to be scheduled for tomorrow.'
            );
            System.assertNotEquals(
                null,
                event.WhatId,
                'Expected each returned event to be related to a job application.'
            );
        }
    }

    @IsTest
    static void generateReminderEmailBodyTest() {
        List<Event> tomorrowsEvents = InterviewReminderService.getTomorrowsEvents();

        String reminderEmailBody = InterviewReminderService.generateReminderEmailBody(tomorrowsEvents);

        System.assert(
            reminderEmailBody.contains('You have the following interviews scheduled for tomorrow:'),
            'Expected the reminder body to include the intro text.'
        );
        System.assert(
            reminderEmailBody.contains('Interview at: Test Account 0'),
            'Expected the reminder body to include the first company name.'
        );
        System.assert(
            reminderEmailBody.contains('Interview at: Test Account 1'),
            'Expected the reminder body to include the second company name.'
        );
        System.assert(
            reminderEmailBody.contains('Location: Test Location 1'),
            'Expected the reminder body to include the first event location.'
        );
        System.assert(
            reminderEmailBody.contains('Location: Test Location 2'),
            'Expected the reminder body to include the second event location.'
        );
        System.assertEquals(
            false,
            reminderEmailBody.contains('Test Interview 1'),
            'Expected the reminder body to use the company name instead of the event subject.'
        );
    }

    @IsTest
    static void sendEmailTest() {
        Test.startTest();
        InterviewReminderService.sendEmail();
        Integer numberOfEmailSendAttempts = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(
            1,
            numberOfEmailSendAttempts,
            'Expected one reminder email to be sent when tomorrow has interviews.'
        );
    }

}
