import { LightningElement, track } from 'lwc';
import getPlayersList from '@salesforce/apex/imperative.getPlayersList';  
const columns=[
        {label : 'Record Id' , fieldName:'Id'},
        {label : 'Player Name',fieldName : 'Name'}
    ]
export default class Imperative extends LightningElement {
    @track columns = columns; 
    @track data=[];
    connectedCallback(){
        getPlayersList()
        .then(result=>{
            this.data=result;
        })
        .catch(error=>{
            console.log("error");
        })
    }
}