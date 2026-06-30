public with sharing class JobApplicationSalaryHelper {
    private static final Decimal DEFAULT_FEDERAL_TAX_YEAR = 2025;
    private static final String DEFAULT_FILING_STATUS = 'Single';
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

        Decimal salary = jobApplication.Salary__c;
        Decimal federalTax = calculateFederalTax(salary);
        Decimal socialSecurityTax = calculateSocialSecurityTax(salary);
        Decimal medicareWithholding = calculateMedicareWithholding(salary);

        jobApplication.Federal_Income_Tax__c = federalTax;
        jobApplication.Social_Security_Tax__c = socialSecurityTax;
        jobApplication.Medicare_Withholding__c = medicareWithholding;
        jobApplication.Take_Home_Pay__c = salary - federalTax - socialSecurityTax - medicareWithholding;
    }

    public static Decimal calculateTakeHomePay(Decimal salary) {
        Decimal federalTax = calculateFederalTax(salary);
        Decimal socialSecurityTax = calculateSocialSecurityTax(salary);
        Decimal medicareWithholding = calculateMedicareWithholding(salary);

        return salary - federalTax - socialSecurityTax - medicareWithholding;
    }

    private static Decimal calculateFederalTax(Decimal salary) {
        for (Federal_Tax_Bracket__mdt bracket : Federal_Tax_Bracket__mdt.getAll().values()) {
            Boolean isCorrectTaxYear = bracket.Tax_Year__c == DEFAULT_FEDERAL_TAX_YEAR;
            Boolean isCorrectFilingStatus = bracket.Filing_Status__c == DEFAULT_FILING_STATUS;
            Boolean isAboveLowerBound = salary >= bracket.Lower_Bound__c;
            Boolean isBelowUpperBound = bracket.Upper_Bound__c == null || salary <= bracket.Upper_Bound__c;

            if (isCorrectTaxYear && isCorrectFilingStatus && isAboveLowerBound && isBelowUpperBound) {
                return bracket.Base_Tax__c + ((salary - bracket.Lower_Bound__c) * bracket.Rate__c);
            }
        }

        throw new SalaryCalculationException(
            'No federal tax bracket found for salary ' + salary +
            ', tax year ' + DEFAULT_FEDERAL_TAX_YEAR +
            ', filing status ' + DEFAULT_FILING_STATUS + '.'
        );
    }

    private static Decimal calculateSocialSecurityTax(Decimal salary) {
        return salary * SOCIAL_SECURITY_TAX_RATE;
    }

    private static Decimal calculateMedicareWithholding(Decimal salary) {
        return salary * MEDICARE_WITHHOLDING_RATE;
    }

    private class SalaryCalculationException extends Exception {
    }
}
