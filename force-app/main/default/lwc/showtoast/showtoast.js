import { LightningElement } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
export default class Showtoast extends LightningElement {
    mytitle = "My First Button";
    
        handleClick(){
            this.showToast();
        }
            
        showToast(){
        const event=new ShowToastEvent({
        title: "show toast done",
        message:"want to display eg",
        variant:"Warning",
    })
    this.dispatchEvent(event);
}
}