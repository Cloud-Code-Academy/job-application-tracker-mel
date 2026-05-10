public with sharing class TestDataFactory {
    public static List<Account> createAccounts() {
        List<Account> accountList = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
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
        for (Integer i = 0; i < 5; i++) {
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
        List<Account> accountList = createAccounts();
        List<Job_Application__c> jobApplicationList = new List<Job_Application__c>();
        for (Integer i = 0; i < 5; i++) {
            Job_Application__c jobApplication = new Job_Application__c(
                Company_Name__c = accountList[i].Id,
                Status__c = 'Saved',
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
        for (Integer i = 0; i < 5; i++) {
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

}
