import { LightningElement } from 'lwc';

export default class ArrowFunction extends LightningElement {
    connectedCallback(){
        let callMyFunction = this.myFunction(10,2);
        window.alert("reeesullttttttttt    arrowww"+callMyFunction);
}

    myFunction =(dividend,divisor) =>{
        return(dividend/divisor);
    }
    // myFunction(dividend,divisor){
    //     return(dividend/divisor);

    // }
}