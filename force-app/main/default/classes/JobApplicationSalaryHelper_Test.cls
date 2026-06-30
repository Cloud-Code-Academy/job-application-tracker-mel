@IsTest
private class JobApplicationSalaryHelper_Test {
    @IsTest
    static void testPopulateSalaryFieldsAcrossFederalTaxBrackets() {
        List<SalaryScenario> scenarios = new List<SalaryScenario>{
            new SalaryScenario(10000.00, 1000.00, 620.00, 145.00, 8235.00),
            new SalaryScenario(40000.00, 4561.50, 2480.00, 580.00, 32378.50),
            new SalaryScenario(80000.00, 12514.00, 4960.00, 1160.00, 61366.00),
            new SalaryScenario(150000.00, 28847.00, 9300.00, 2175.00, 109678.00),
            new SalaryScenario(225000.00, 49063.00, 13950.00, 3262.50, 158724.50),
            new SalaryScenario(400000.00, 109547.25, 24800.00, 5800.00, 259852.75),
            new SalaryScenario(700000.00, 216020.25, 43400.00, 10150.00, 430429.75)
        };

        for (SalaryScenario scenario : scenarios) {
            Job_Application__c jobApplication = new Job_Application__c(
                Salary__c = scenario.salary
            );

            JobApplicationSalaryHelper.populateSalaryFields(jobApplication);

            System.assertEquals(
                scenario.expectedFederalIncomeTax,
                jobApplication.Federal_Income_Tax__c,
                'Wrong federal income tax for salary ' + scenario.salary
            );
            System.assertEquals(
                scenario.expectedSocialSecurityTax,
                jobApplication.Social_Security_Tax__c,
                'Wrong Social Security tax for salary ' + scenario.salary
            );
            System.assertEquals(
                scenario.expectedMedicareWithholding,
                jobApplication.Medicare_Withholding__c,
                'Wrong Medicare withholding for salary ' + scenario.salary
            );
            System.assertEquals(
                scenario.expectedTakeHomePay,
                jobApplication.Take_Home_Pay__c,
                'Wrong take-home pay for salary ' + scenario.salary
            );
        }
    }

    @IsTest
    static void testPopulateSalaryFieldsClearsValuesWhenSalaryIsNull() {
        Job_Application__c jobApplication = new Job_Application__c(
            Salary__c = null,
            Federal_Income_Tax__c = 100.00,
            Social_Security_Tax__c = 100.00,
            Medicare_Withholding__c = 100.00,
            Take_Home_Pay__c = 100.00
        );

        JobApplicationSalaryHelper.populateSalaryFields(jobApplication);

        System.assertEquals(null, jobApplication.Federal_Income_Tax__c, 'Federal income tax should be cleared');
        System.assertEquals(null, jobApplication.Social_Security_Tax__c, 'Social Security tax should be cleared');
        System.assertEquals(null, jobApplication.Medicare_Withholding__c, 'Medicare withholding should be cleared');
        System.assertEquals(null, jobApplication.Take_Home_Pay__c, 'Take-home pay should be cleared');
    }

    private class SalaryScenario {
        Decimal salary;
        Decimal expectedFederalIncomeTax;
        Decimal expectedSocialSecurityTax;
        Decimal expectedMedicareWithholding;
        Decimal expectedTakeHomePay;

        SalaryScenario(
            Decimal salary,
            Decimal expectedFederalIncomeTax,
            Decimal expectedSocialSecurityTax,
            Decimal expectedMedicareWithholding,
            Decimal expectedTakeHomePay
        ) {
            this.salary = salary;
            this.expectedFederalIncomeTax = expectedFederalIncomeTax;
            this.expectedSocialSecurityTax = expectedSocialSecurityTax;
            this.expectedMedicareWithholding = expectedMedicareWithholding;
            this.expectedTakeHomePay = expectedTakeHomePay;
        }
    }
}
