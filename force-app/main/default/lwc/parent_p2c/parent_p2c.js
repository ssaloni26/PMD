import { LightningElement } from 'lwc';

export default class Parent_p2c extends LightningElement {
    
    startCounter =0;
    
    handleStartChange(event){
        this.startCounter = parseInt(event.target.value);
    }

    handleMaximizeCounter(){
        // const updateCounter = this.template.querySelector('c-childp2c');
        // updateCounter.maximizeCounter();
        
        this.template.querySelector('c-childp2c').maximizeCounter();
    }


}