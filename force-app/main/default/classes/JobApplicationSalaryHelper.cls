public with sharing class JobApplicationSalaryHelper {
    
    private static final Decimal SOCIAL_SECURITY_TAX_RATE = 0.062;
    private static final Decimal MEDICARE_WITHHOLDING_RATE = 0.0145;
    public Decimal salary;

    public static void populateSalaryFields(Job_Application__c jobApplication) {
        if (jobApplication.Salary__c == null) {
            jobApplication.Federal_Income_Tax__c = null;
            jobApplication.Social_Security_Tax__c = null;
            jobApplication.Medicare_Withholding__c = null;
            jobApplication.Take_Home_Pay__c = null;
            return;
        }

        jobApplication.Federal_Income_Tax__c = calculateFederalTax(jobApplication.Salary__c);
        jobApplication.Social_Security_Tax__c = calculateSocialSecurityTax(jobApplication.Salary__c);
        jobApplication.Medicare_Withholding__c = calculateMedicareWithholding(jobApplication.Salary__c);
        jobApplication.Take_Home_Pay__c = calculateTakeHomePay(jobApplication.Salary__c);
    }

    public static Decimal calculateTakeHomePay(Decimal salary) {
        Decimal federalTax = calculateFederalTax(salary);
        Decimal socialSecurityTax = calculateSocialSecurityTax(salary);
        Decimal medicareWithholding = calculateMedicareWithholding(salary);

        return salary - federalTax - socialSecurityTax - medicareWithholding;
    }

    private static Decimal calculateFederalTax(Decimal salary) {
        if (salary <= 11925) {
        return salary * 0.1;
        } else if (salary <= 48475) {
        return 1192.5 + (salary - 11925) * 0.12;
        } else if (salary <= 103350) {
        return 5578.5 + (salary - 48475) * 0.22;
        } else if (salary <= 197300) {
        return 17651 + (salary - 103350) * 0.24;
        } else if (salary <= 250525) {
        return 40199 + (salary - 197300) * 0.32;
        } else if (salary <= 626350) {
        return 57231 + (salary - 250525) * 0.35;
        } else {
        return 188769.75 + (salary - 626350) * 0.37;
        }
  }

  private static Decimal calculateSocialSecurityTax(Decimal salary) {
    return salary * SOCIAL_SECURITY_TAX_RATE;
  }

  private static Decimal calculateMedicareWithholding(Decimal salary) {
    return salary * MEDICARE_WITHHOLDING_RATE;
  }
}
