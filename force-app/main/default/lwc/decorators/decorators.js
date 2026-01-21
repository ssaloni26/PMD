import { LightningElement, api, track, wire } from 'lwc';
import getAccount from '@salesforce/apex/AccountController.getAccount';

export default class Decorators extends LightningElement {
    // @api → Parent can pass value to child
    @api recordId;

    // @track → Reactive object
    @track counter = { value: 0 };

    // @wire → Fetch Accounts from Apex
    @wire(getAccount) accounts;

    increaseCounter() {
        this.counter.value++;
    }

}