import { LightningElement , wire,api } from 'lwc';
import callApex from '@salesforce/apex/WireDecorator.showMessage';
export default class Wire_demo extends LightningElement {
@api message;
    @wire(callApex)
    wireData({error,data})
    {
        if (data) { 
            this.message=data;
        }else if (error){
            this.message="error";
        }
    }
}