@IsTest
private with sharing class EventTriggerHandler_Test {
    @TestSetup
    static void makeData() {
        TestDataFactory.createJobApplications();
    }

    @IsTest
    static void insertOverlappingEventTest() {
        List<Job_Application__c> jobAppList = queryJobApplications();
        Datetime startTime = createStartTime(10);

        Event firstEvent = buildEvent('First Event', startTime, startTime.addHours(1), jobAppList[0].Id);
        insert firstEvent;

        Event secondEvent = buildEvent(
            'Second Event',
            startTime.addMinutes(30),
            startTime.addHours(1).addMinutes(30),
            jobAppList[1].Id
        );

        try {
            insert secondEvent;
            System.assert(false, 'Expected insert to fail because another interview overlaps this time.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('You already have an interview at this time.'));
        }
    }

    @IsTest
    static void updateOverlappingEventTest() {
        List<Job_Application__c> jobAppList = queryJobApplications();
        Datetime firstStartTime = createStartTime(10);
        Datetime secondStartTime = firstStartTime.addHours(1);

        Event firstEvent = buildEvent('First Event', firstStartTime, firstStartTime.addHours(1), jobAppList[0].Id);
        insert firstEvent;

        Event secondEvent = buildEvent('Second Event', secondStartTime, secondStartTime.addHours(1), jobAppList[1].Id);
        insert secondEvent;

        secondEvent.StartDateTime = firstStartTime.addMinutes(30);
        secondEvent.EndDateTime = firstStartTime.addHours(1).addMinutes(30);

        try {
            update secondEvent;
            System.assert(false, 'Expected update to fail because another interview overlaps this time.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('You already have an interview at this time.'));
        }
    }

    @IsTest
    static void bulkInsertOverlappingEventsTest() {
        List<Job_Application__c> jobAppList = queryJobApplications();
        Datetime startTime = createStartTime(10);
        List<Event> eventList = new List<Event>{
            buildEvent('First Event', startTime, startTime.addHours(1), jobAppList[0].Id),
            buildEvent('Second Event', startTime.addMinutes(30), startTime.addHours(1).addMinutes(30), jobAppList[1].Id)
        };

        try {
            insert eventList;
            System.assert(false, 'Expected bulk insert to fail because the new interviews overlap each other.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('You already have an interview at this time.'));
        }
    }

    @IsTest
    static void insertBackToBackEventTest() {
        List<Job_Application__c> jobAppList = queryJobApplications();
        Datetime startTime = createStartTime(10);

        Event firstEvent = buildEvent('First Event', startTime, startTime.addHours(1), jobAppList[0].Id);
        insert firstEvent;

        Event secondEvent = buildEvent('Second Event', startTime.addHours(1), startTime.addHours(2), jobAppList[1].Id);
        insert secondEvent;

        System.assertNotEquals(null, secondEvent.Id, 'Back-to-back interviews should not be treated as overlapping.');
    }

    private static List<Job_Application__c> queryJobApplications() {
        return [
            SELECT Id
            FROM Job_Application__c
            LIMIT 2
        ];
    }

    private static Datetime createStartTime(Integer hour) {
        return Datetime.newInstance(
            Date.today().addDays(1),
            Time.newInstance(hour, 0, 0, 0)
        );
    }

    private static Event buildEvent(String subject, Datetime startDateTime, Datetime endDateTime, Id jobApplicationId) {
        return new Event(
            Subject = subject,
            StartDateTime = startDateTime,
            EndDateTime = endDateTime,
            WhatId = jobApplicationId
        );
    }
}
