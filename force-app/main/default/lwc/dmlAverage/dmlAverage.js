import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getAISpikeAlert from '@salesforce/apex/DMLAuditAI.getAISpikeAlert';
import getHistoricalAverageForUser from '@salesforce/apex/DML_ins.getHistoricalAverageForUser';
/*!
 * jQuery JavaScript Library v1.8.3
 * http://jquery.com/
 */

import USER_FIELD from '@salesforce/schema/DML_Audit__c.User__c';
import OBJECT_FIELD from '@salesforce/schema/DML_Audit__c.ObjectName__c';
import COUNT_FIELD from '@salesforce/schema/DML_Audit__c.Count__c';
import LOGDATE_FIELD from '@salesforce/schema/DML_Audit__c.LogDate__c';

export default class DmlAverage extends LightningElement {
    @api recordId;
    @track userId;
    @track objectName;
    @track count;
    @track logDate;
    @track averageCount = 0;
    @track spikeDetected = false;
    @track aiMessage = '';
    @track customPrompt = '';

    thresholdFactor = 2;

    // Wire to fetch current record
    @wire(getRecord, { recordId: '$recordId', fields: [USER_FIELD, OBJECT_FIELD, COUNT_FIELD, LOGDATE_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            this.userId = data.fields.User__c.value;
            this.objectName = data.fields.ObjectName__c.value;
            this.count = data.fields.Count__c.value;
            this.logDate = data.fields.LogDate__c.value;

            this.fetchAverage();
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }

    // Fetch historical average up to LogDate
    fetchAverage() {
        getHistoricalAverageForUser({ 
            userId: this.userId, 
            objectName: this.objectName,
            upToDate: this.logDate
        })
        .then(result => {
            this.averageCount = (result && result.length > 0) ? result[0].averageCount : 0;
            this.checkSpike();
            this.generateAIMessage();
        })
        .catch(error => console.error('Error fetching average:', error));
    }
    

    // Compare current count with historical average * threshold
    checkSpike() {
        this.spikeDetected = this.count > this.averageCount * this.thresholdFactor;
    }

    // Generate AI message
    generateAIMessage() {
        let message;
        if (this.spikeDetected) {
            message = `DML spike detected: Count ${this.count}, Overall Avg ${this.averageCount}, Threshold Factor ${this.thresholdFactor}x, User: ${this.userId}, Object: ${this.objectName}`;
        } else {
            message = `No spike detected. Count ${this.count} is within threshold (${this.averageCount * this.thresholdFactor}) for User: ${this.userId}, Object: ${this.objectName}`;
        }

        const defaultPrompt = `You are an AI assistant analyzing Salesforce DML Audit records for spike detection.
- User: ${this.userId}
- Object: ${this.objectName}
- Current Record Count: ${this.count}
- Historical Monthly Average: ${this.averageCount}
- Threshold Factor: ${this.thresholdFactor}x
- Analysis Message: ${message}`;

        const promptToSend = this.customPrompt ? `${defaultPrompt}\n\nCustom Prompt: ${this.customPrompt}` : defaultPrompt;

        getAISpikeAlert({
            userName: this.userId,
            objectName: this.objectName,
            currentCount: this.count,
            historicalAvg: this.averageCount,
            thresholdFactor: this.thresholdFactor,
            customPrompt: promptToSend
        })
        .then(result => {
            this.aiMessage = result;
        })
        .catch(error => console.error('Error generating AI message:', error));
    }

    handlePromptChange(event) {
        this.customPrompt = event.target.value;
    }

    generateCustomAIMessage() {
        this.generateAIMessage();
    }
}
