import { LightningElement,track } from 'lwc';

export default class Button extends LightningElement {
    @track mytitle = "My First Button";

    handleClick() {
        // console.log("✅ Button clicked!");   // Check console first
        window.alert("Hello from LWC!");           // Then try alert
    }
}