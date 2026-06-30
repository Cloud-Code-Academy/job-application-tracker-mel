@IsTest
public with sharing class TestDataFactory {

    public static List<Account> createAccounts() {
        List<Account> accountList = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            Account account = new Account(
                Name = 'Test Account ' + i
            );
            accountList.add(account);
        }
        insert accountList;
        return accountList;
    }

    public static List<Contact> createContacts() {
        List<Account> accountList = createAccounts();
        List<Contact> contactList = new List<Contact>();
        for (Integer i = 0; i < accountList.size(); i++) {
            Contact contact = new Contact(
                AccountId = accountList[i].Id,
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'test.contact.' + i + '@example.com'
            );
            contactList.add(contact);
        }
        insert contactList;
        return contactList;
    }

    public static List<Job_Application__c> createJobApplications() {
        List<String> statuses = new List<String>{
            'Saved',
            'Applying',
            'Applied',
            'Interviewing',
            'Negotiating',
            'Accepted',
            'Closed',
            'Saved',
            'Applying',
            'Applied'
        };
        List<Account> accountList = createAccounts();
        List<Job_Application__c> jobApplicationList = new List<Job_Application__c>();
        for (Integer i = 0; i < statuses.size(); i++) {
            Job_Application__c jobApplication = new Job_Application__c(
                Company_Name__c = accountList[i].Id,
                Status__c = statuses[i],
                Title__c = 'Test Job ' + i
            );
            jobApplicationList.add(jobApplication);
        }
        insert jobApplicationList;
        return jobApplicationList;
    }
    
    public static List<Job_Contact__c> createJobContacts() {
        List<Contact> contactList = createContacts();
        List<Job_Application__c> jobApplicationList = createJobApplications();
        List<Job_Contact__c> jobContactList = new List<Job_Contact__c>();
        for (Integer i = 0; i < 10; i++) {
            Job_Contact__c jobContact = new Job_Contact__c(
                Contact__c = contactList[i].Id,
                Job_Application__c = jobApplicationList[i].Id,
                Hiring_Role__c = 'Recruiter'
            );
            jobContactList.add(jobContact);
        }
        insert jobContactList;
        return jobContactList;
    }

    public static List<Event> createEvents() {
        List<Job_Application__c> jobApplicationList = createJobApplications();
        Datetime firstStartTime = Datetime.newInstance(
            Date.today().addDays(1),
            Time.newInstance(10, 0, 0, 0)
        );

        List<Event> eventList = new List<Event>{
            new Event(
                Subject = 'Test Interview 1',
                StartDateTime = firstStartTime,
                EndDateTime = firstStartTime.addHours(1),
                Location = 'Test Location 1',
                WhatId = jobApplicationList[0].Id,
                OwnerId = UserInfo.getUserId()
            ),
            new Event(
                Subject = 'Test Interview 2',
                StartDateTime = firstStartTime.addHours(2),
                EndDateTime = firstStartTime.addHours(3),
                Location = 'Test Location 2',
                WhatId = jobApplicationList[1].Id,
                OwnerId = UserInfo.getUserId()
            )
        };
        insert eventList;
        return eventList;
    }

}
