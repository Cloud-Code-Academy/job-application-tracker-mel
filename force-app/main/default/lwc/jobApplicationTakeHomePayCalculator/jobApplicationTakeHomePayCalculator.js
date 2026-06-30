import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import ID_FIELD from "@salesforce/schema/Job_Application__c.Id";
import SALARY_FIELD from "@salesforce/schema/Job_Application__c.Salary__c";

const FIELDS = [SALARY_FIELD];

// 2025 assumptions
const SOCIAL_SECURITY_TAX_RATE = 0.062;
const MEDICARE_WITHHOLDING_RATE = 0.0145;

export default class JobApplicationTakeHomePayCalculator extends LightningElement {
  @api recordId;

  salary = 0;

  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  loadJobApplication(response) {
    const data = response.data;

    if (data != null) {
      this.salary = getFieldValue(data, SALARY_FIELD) || 0;
    }
  }

  handleSalaryChange(event) {
    if (event.target.value === "") {
      this.salary = null;
    } else {
      this.salary = Number(event.target.value);
    }
  }

  async handleSaveToRecord() {
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;
    fields[SALARY_FIELD.fieldApiName] = this.salary;

    await updateRecord({ fields });
    this.showToast(
      "Salary saved",
      "The salary was updated on this job application.",
      "success"
    );
  }

  get hasSalary() {
    return this.salary > 0;
  }

  get federalTax() {
    return this.calculateFederalTax(this.salary);
  }

  get socialSecurityTax() {
    return this.salary * SOCIAL_SECURITY_TAX_RATE;
  }

  get medicareWithholding() {
    return this.salary * MEDICARE_WITHHOLDING_RATE;
  }

  get totalTax() {
    return this.federalTax + this.socialSecurityTax + this.medicareWithholding;
  }

  get yearlyTakeHome() {
    return this.salary - this.totalTax;
  }

  get sixMonthTakeHome() {
    return this.yearlyTakeHome / 2;
  }

  get monthlyTakeHome() {
    return this.yearlyTakeHome / 12;
  }

  get biWeeklyTakeHome() {
    return this.yearlyTakeHome / 26;
  }

  get rows() {
    return [
      {
        label: "Yearly",
        salary: this.roundCurrency(this.salary),
        federalTax: this.roundCurrency(this.federalTax),
        medicare: this.roundCurrency(this.medicareWithholding),
        socialSecurity: this.roundCurrency(this.socialSecurityTax),
        takeHome: this.roundCurrency(this.yearlyTakeHome)
      },
      {
        label: "Six Months",
        salary: this.roundCurrency(this.salary / 2),
        federalTax: this.roundCurrency(this.federalTax / 2),
        medicare: this.roundCurrency(this.medicareWithholding / 2),
        socialSecurity: this.roundCurrency(this.socialSecurityTax / 2),
        takeHome: this.roundCurrency(this.sixMonthTakeHome)
      },
      {
        label: "Monthly",
        salary: this.roundCurrency(this.salary / 12),
        federalTax: this.roundCurrency(this.federalTax / 12),
        medicare: this.roundCurrency(this.medicareWithholding / 12),
        socialSecurity: this.roundCurrency(this.socialSecurityTax / 12),
        takeHome: this.roundCurrency(this.monthlyTakeHome)
      },
      {
        label: "Bi-Weekly",
        salary: this.roundCurrency(this.salary / 26),
        federalTax: this.roundCurrency(this.federalTax / 26),
        medicare: this.roundCurrency(this.medicareWithholding / 26),
        socialSecurity: this.roundCurrency(this.socialSecurityTax / 26),
        takeHome: this.roundCurrency(this.biWeeklyTakeHome)
      }
    ];
  }

  calculateFederalTax(grossIncome) {
    if (grossIncome <= 11925) {
      return grossIncome * 0.1;
    } else if (grossIncome <= 48475) {
      return 1192.5 + (grossIncome - 11925) * 0.12;
    } else if (grossIncome <= 103350) {
      return 5578.5 + (grossIncome - 48475) * 0.22;
    } else if (grossIncome <= 197300) {
      return 17651 + (grossIncome - 103350) * 0.24;
    } else if (grossIncome <= 250525) {
      return 40199 + (grossIncome - 197300) * 0.32;
    } else if (grossIncome <= 626350) {
      return 57231 + (grossIncome - 250525) * 0.35;
    } else {
      return 188769.75 + (grossIncome - 626350) * 0.37;
    }
  }

  roundCurrency(value) {
    return Math.round(value * 100) / 100;
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }
}
