import { LightningElement , wire} from 'lwc';
import{publish , MessageContext} from 'lightning/messageService'
import Counting_update from '@salesforce/messageChannel/Counting_update__c';

export default class Publwc extends LightningElement {
    @wire(MessageContext)
    MessageContext;


    handleIncrement(){
        const payload={
            operator : 'Add',
            constant:1
        };

        publish(this.MessageContext,Counting_update,payload);
    }
    handleDecrement(){
        const payload={
            operator : 'Subtract',
            constant:1
        };
        
        publish(this.MessageContext,Counting_update,payload);
    }
    handleMultiply(){
        const payload={
            operator : 'Multiply',
            constant:2
        };
        
        publish(this.MessageContext,Counting_update,payload);
    }

}