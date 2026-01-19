import { LightningElement } from 'lwc';
import { createMessageContext, releaseMessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import SAMPLEMC from '@salesforce/messageChannel/SampleMessageChannel__c';

export default class SubscriberLwc extends LightningElement {
    context = createMessageContext();
    subscription = null;
    receivedMessage = '';

    connectedCallback() {
        this.subscribeMC();
    }

    subscribeMC() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.context,
                SAMPLEMC,
                (message) => { this.handleMessage(message); }
            );
        }
    }

    handleMessage(message) {
        this.receivedMessage = message ? message.message : 'No message received';
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        releaseMessageContext(this.context);
    }
}