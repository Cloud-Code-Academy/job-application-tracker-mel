public with sharing class JobApplicationTriggerHandler extends TriggerHandler {
    private List<Job_Application__c> newJobApplicationList;
    private Map<Id, Job_Application__c> oldJobApplicationsById;

    public JobApplicationTriggerHandler() {
        this.newJobApplicationList = (List<Job_Application__c>) Trigger.new;
        this.oldJobApplicationsById = (Map<Id, Job_Application__c>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        setPrimaryContactFromAccountContact(newJobApplicationList);
        setPayValues(newJobApplicationList);
    }

    public override void beforeUpdate() {
        setPrimaryContactFromJobContacts(newJobApplicationList);
        setPayValues(newJobApplicationList);
    }
    
    public override void afterInsert() {
        insertTasksOnStatusChange(newJobApplicationList, null);
    }

    public override void afterUpdate() {
        insertTasksOnStatusChange(newJobApplicationList, oldJobApplicationsById);
    }

    private void insertTasksOnStatusChange(
        List<Job_Application__c> jobApplicationList,
        Map<Id, Job_Application__c> oldJobApplicationsById
    ) {
        List<Task> tasksToInsert = new List<Task>(); 

        for (Job_Application__c jobApp : jobApplicationList) {
            if (!hasStatusChanged(jobApp, oldJobApplicationsById)) {
                continue;
            }

            for (String subject : getTaskSubjectsForStatus(jobApp.Status__c)) {
                tasksToInsert.add(createTask(jobApp, subject));
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    private static Boolean hasStatusChanged(
        Job_Application__c jobApp,
        Map<Id, Job_Application__c> oldJobApplicationsById
    ) {

        if (oldJobApplicationsById == null) {
            return true;
        }

        Job_Application__c oldJobApp = oldJobApplicationsById.get(jobApp.Id);
        if (oldJobApp == null) {
            return true;
        }

        if (oldJobApp.Status__c != jobApp.Status__c) {
            return true;
        }

        return false;
    }

    private static List<String> getTaskSubjectsForStatus(String status) {
        switch on status {
            when 'Saved' {
                return new List<String>{
                    'Check if the job description aligns with your interests and values',
                    'Review the highlighted skills to see if the role is a good fit',
                    'Research the company or role and mark your excitement level'
                };
            }
            when 'Applying' {
                return new List<String>{
                    'Find and research someone who works at the company and add them as a contact',
                    'Set up an informational interview to learn more about the role/company',
                    'Identify potential referrals to help get your application on the top of the pile',
                    'Customize your work achievements using the job description keywords',
                    'Submit your application on the company website if possible'
                };
            }
            when 'Applied' {
                return new List<String>{
                    'Reach out to the hiring manager or recruiter',
                    'Follow up on your application via email weekly',
                    'Continue identifying and saving similar job opportunities',
                    'Set up weekly networking calls to explore similar companies/roles'
                };
            }
            when 'Interviewing' {
                return new List<String>{
                    'Prepare your blurb or "tell me about yourself" response',
                    'Practice answering behavioral interview questions',
                    'Research the company and your interviewers',
                    'Set up your virtual interview space and test your tech',
                    'Send thank you emails within 24 hours'
                };
            }
            when 'Negotiating' {
                return new List<String>{
                    'Research your market value and know your numbers',
                    'Prepare your negotiation scripts',
                    'Evaluate your offer and decline or accept'
                };
            }
            when 'Accepted' {
                return new List<String>{
                    'Plan your resignation if applicable',
                    'Take some time to relax and recharge',
                    'Prepare for your first day of onboarding'
                };
            }
            when 'Closed' {
                return new List<String>{
                    'Send a follow-up email thanking the interviewer and asking for feedback',
                    'Review your notes and reflect on areas of improvement'
                };
            }
        }

        return new List<String>();
    }

    private static Task createTask(Job_Application__c jobApp, String subject) {
        return new Task(
            WhatId = jobApp.Id,
            Subject = subject,
            OwnerId = UserInfo.getUserId(),
            Status = 'Not Started',
            ActivityDate = Date.today(),
            Priority = 'Medium'
        );
    }

    private static void setPrimaryContactFromAccountContact(List<Job_Application__c> newJobApplicationList) {
        Set<Id> accountIds = new Set<Id>();
        for (Job_Application__c jobApp : newJobApplicationList) {
            if (jobApp.Primary_Contact__c == null) {
                accountIds.add(jobApp.Company_Name__c);
            }
        }

        Map<Id, Id> contactIdByAccountId = new Map<Id, Id>();
        for (Contact accountContact : [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
        ]) {
            contactIdByAccountId.put(accountContact.AccountId, accountContact.Id);
        }

        for (Job_Application__c jobApp : newJobApplicationList) {
            if (jobApp.Primary_Contact__c == null && contactIdByAccountId.containsKey(jobApp.Company_Name__c)) {
                jobApp.Primary_Contact__c = contactIdByAccountId.get(jobApp.Company_Name__c);
            }
        }
    }

    private static void setPrimaryContactFromJobContacts(List<Job_Application__c> newJobApplicationList) {
        List<Job_Application__c> jobAppsWithoutPrimaryContact = new List<Job_Application__c>();

        for (Job_Application__c jobApp : newJobApplicationList) {
            if (jobApp.Primary_Contact__c == null) {
                jobAppsWithoutPrimaryContact.add(jobApp);
            }
        }

        Map<Id, Id> companiesByJobApp = new Map<Id, Id>();

        for (Job_Application__c jobApp : jobAppsWithoutPrimaryContact) {
            companiesByJobApp.put(jobApp.Id, jobApp.Company_Name__c);
        }

        List<Job_Contact__c> jobContacts = [
            SELECT Id, Job_Application__c, Contact__c
            FROM Job_Contact__c
            WHERE Job_Application__c IN :companiesByJobApp.keySet()
        ];

        Map<Id, Id> jobContactIdByJobAppId = new Map<Id, Id>();

        for (Job_Contact__c jobContact : jobContacts) {
            jobContactIdByJobAppId.put(jobContact.Job_Application__c, jobContact.Contact__c);
        }

        List<Contact> contactsInCompanies = [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :companiesByJobApp.values()
        ];

        Map<Id, Id> contactIdByAccountId = new Map<Id, Id>(); 
        for (Contact contact : contactsInCompanies) {
            contactIdByAccountId.put(contact.AccountId, contact.Id);
        }

        for (Job_Application__c jobApp : jobAppsWithoutPrimaryContact) {
            if (jobContactIdByJobAppId.containsKey(jobApp.Id) == true) {
                jobApp.Primary_Contact__c = jobContactIdByJobAppId.get(jobApp.Id);
            } else if (contactIdByAccountId.containsKey(jobApp.Company_Name__c)) {
                jobApp.Primary_Contact__c = contactIdByAccountId.get(jobApp.Company_Name__c);
            }
        }
    }

    private static void setPayValues(List<Job_Application__c> newJobApplicationList) {
        for (Job_Application__c jobApp : newJobApplicationList) {
            JobApplicationSalaryHelper.populateSalaryFields(jobApp);
        }
    }

    
}
