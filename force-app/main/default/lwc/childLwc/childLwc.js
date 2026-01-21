import { LightningElement } from 'lwc';

export default class ChildLwc extends LightningElement {
    handleSubtract(){
        this.dispatchEvent(new CustomEvent('subtract'));
    }
    handleAdd(){
        this.dispatchEvent(new CustomEvent('add'));
    }
    handleMultiply(event){
        const valueForMultiply = event.target.value;
        alert("value for multiply is : " + valueForMultiply);

        this.dispatchEvent(new CustomEvent('multiply', {detail : valueForMultiply}));
    }
    
    
}