import { LightningElement,track,api } from 'lwc';

export default class Decorator_Demo extends LightningElement {
    @api recordId;
    @track message= "hi meeeeeeeeeeeee";

    handleEvent(event){
        this.message = event.target.value;
    }

}