import { LightningElement } from 'lwc';

export default class My1Lwc extends LightningElement {
    mytitle = "Mai hu saloooniiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii";

    connectedCallback() {
        var name = "meeeeeeeeeeeeeeeeeeeeeeeeeee";
        
        if(this.mytitle){
            window.alert("name" + name);
        
        }
    }
       
}