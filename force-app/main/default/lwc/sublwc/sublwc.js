import { LightningElement, wire } from 'lwc';
import {subscribe,MessageContext} from 'lightning/messageService';
import Counting_update from '@salesforce/messageChannel/Counting_update__c';
export default class Sublwc extends LightningElement {
    counter = 0;
    subscription = null;

    @wire(MessageContext)
    messageContext;

    connectedCallback(){
        this.subscribeToMessageChannel();
    }

    subscribeToMessageChannel(){
        this.subscription=subscribe(
            this.messageContext,
            Counting_update,
            (message)=>this.handleMessage(message)
            
        );
    }
    handleMessage(message){
        
            console.log('Received message:', JSON.stringify(message));
        
            if (message.operator === 'Add') {
                this.counter += message.constant;
            } else if (message.operator === 'Subtract') {
                this.counter -= message.constant;
            } else if (message.operator === 'Multiply') {
                this.counter *= message.constant;
            }
    }

}