@IsTest
private with sharing class EventTriggerHandler_Test {
    @TestSetup
    static void makeData(){
        TestDataFactory.createJobApplications();
    }

    @IsTest
    static void insertDuplicateStartTimeEventTest() {
        List<Job_Application__c> jobAppList = [SELECT Id FROM Job_Application__c LIMIT 2];
        Datetime startTime = Datetime.newInstance(
            Date.today().addDays(1),
            Time.newInstance(10, 0, 0, 0)
        );

        Event firstEvent = new Event(
            Subject = 'First Event',
            StartDateTime = startTime,
            EndDateTime = startTime.addHours(1),
            WhatId = jobAppList[0].Id,
            OwnerId = UserInfo.getUserId()
        );
        insert firstEvent;

        Event secondEvent = new Event(
            Subject = 'Second Event',
            StartDateTime = startTime,
            EndDateTime = startTime.addHours(1),
            WhatId = jobAppList[1].Id,
            OwnerId = UserInfo.getUserId()
        );
        try {
            insert secondEvent;
            System.assert(false, 'Expected insert to fail because another interview has the same start time.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('You already have an interview at this time.'));
        }
    }

    @IsTest
    static void updateDuplicateStartTimeEventTest() {
        List<Job_Application__c> jobAppList = [SELECT Id FROM Job_Application__c LIMIT 2];
        Datetime firstStartTime = Datetime.newInstance(
            Date.today().addDays(1),
            Time.newInstance(10, 0, 0, 0)
        );
        Datetime secondStartTime = firstStartTime.addHours(1);

        Event firstEvent = new Event(
            Subject = 'First Event',
            StartDateTime = firstStartTime,
            EndDateTime = firstStartTime.addHours(1),
            WhatId = jobAppList[0].Id,
            OwnerId = UserInfo.getUserId()
        );
        insert firstEvent;

        Event secondEvent = new Event(
            Subject = 'Second Event',
            StartDateTime = secondStartTime,
            EndDateTime = secondStartTime.addHours(1),
            WhatId = jobAppList[1].Id,
            OwnerId = UserInfo.getUserId()
        );
        insert secondEvent;

        secondEvent.StartDateTime = firstStartTime;
        secondEvent.EndDateTime = firstStartTime.addHours(1);

        try {
            update secondEvent;
            System.assert(false, 'Expected update to fail because another interview has the same start time.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('You already have an interview at this time.'));
        }
    }
}
