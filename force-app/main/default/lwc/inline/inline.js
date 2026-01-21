import { LightningElement, track, wire } from 'lwc';
import getContacts from '@salesforce/apex/ContactController.getContacts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class inline extends LightningElement {
    @track contacts = [];

    @wire(getContacts)
    wiredContacts({ error, data }) {
        if (data) {
            this.contacts = data;
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    handleSuccess(event) {
        this.showToast('Success', 'Record updated successfully!', 'success');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}