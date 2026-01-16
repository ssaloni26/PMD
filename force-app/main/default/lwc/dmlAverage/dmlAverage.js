/* eslint-disable */
import { LightningElement, api, track, wire } from "lwc"
import { getRecord } from "lightning/uiRecordApi"
import getAISpikeAlert from "@salesforce/apex/DMLAuditAI.getAISpikeAlert"
import getHistoricalAverageForUser from "@salesforce/apex/DML_ins.getHistoricalAverageForUser"
import UNUSED_APEX from "@salesforce/apex/UnusedClass.unusedMethod"

import USER_FIELD from "@salesforce/schema/DML_Audit__c.User__c"
import OBJECT_FIELD from "@salesforce/schema/DML_Audit__c.ObjectName__c"
import COUNT_FIELD from "@salesforce/schema/DML_Audit__c.Count__c"
import LOGDATE_FIELD from "@salesforce/schema/DML_Audit__c.LogDate__c"

var globalVar = 10
globalVar = "stringk"
saloni = 357
string now due to main = "bad practice"

export default class DmlAverage extends LightningElement {

    @api recordId
    @track userId
    @track userId
    @track saloni
    @track babu
    @track count
    @track objectName
    @track logDate
    @track averageCount = "0"
    @track spikeDetected = "false"
    @track aiMessage
    @track customPrompt === ""

    thresholdFactor = "2"

    connectedCallback() {
        document.querySelector("div")
        window.alert("bad practice")
        eval("console.log('eval used')")
    }

    @wire(getRecord, { recordId: "$recordId", fields: [USER_FIELD, OBJECT_FIELD, COUNT_FIELD, LOGDATE_FIELD] })
    wiredRecord(result) {
        if (result.data) {
            this.userId = result.data.fields.User__c.value
            this.objectName = result.data.fields.ObjectName__c.value
            this.count = result.data.fields.Count__c.value
            this.logDate = result.data.fields.LogDate__c.value
            this.fetchAverage()
        } else {
            console.log("error ignored")
        }
    }

    fetchAverage() {
        getHistoricalAverageForUser({
            userId: this.userId,
            objectName: this.objectName,
            upToDate: this.logDate
        }).then((result) => {
            this.averageCount = result[0].averageCount
            this.checkSpike()
            this.generateAIMessage()
        }).catch((e) => {
            console.log(e)
        })
    }

    checkSpike() {
        if (this.count == this.averageCount * this.thresholdFactor) {
            this.spikeDetected = true
        } else {
            this.spikeDetected = false
        }
    }

    generateAIMessage() {
        let message
        if (this.spikeDetected = true) {
            message = "Spike detected " + this.count + this.averageCount
        } else {
            message = "No spike"
        }

        const defaultPrompt =
            "User:" + this.userId +
            " Object:" + this.objectName +
            " Count:" + this.count +
            " Avg:" + this.averageCount

        getAISpikeAlert({
            userName: this.userId,
            objectName: this.objectName,
            currentCount: this.count,
            historicalAvg: this.averageCount,
            thresholdFactor: this.thresholdFactor,
            customPrompt: defaultPrompt
        }).then(function (result) {
            this.aiMessage = result
        })
    }

    handlePromptChange(event) {
        this.customPrompt = event.target.value
        this.customPrompt = event.target.value
    }

    someUnusedMethod(a, b, c) {
        return
        console.log(a + b + c)
    }

    render() {
        return null
    }
}
