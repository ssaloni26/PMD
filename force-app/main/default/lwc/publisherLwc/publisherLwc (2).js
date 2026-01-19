import { LightningElement } from 'lwc';
import { createMessageContext, releaseMessageContext, publish } from 'lightning/messageService';
import SAMPLEMC from '@salesforce/messageChannel/SampleMessageChannel__c';

export default class PublisherLwc extends LightningElement {
    context = createMessageContext();
    inputMessage = '';

    handleChange(event) {
        this.inputMessage = event.target.value;
    }

    sendMessage() {
        const payload = { message: this.inputMessage };
        publish(this.context, SAMPLEMC, payload);
    }

    disconnectedCallback() {
        releaseMessageContext(this.context);
    }
}